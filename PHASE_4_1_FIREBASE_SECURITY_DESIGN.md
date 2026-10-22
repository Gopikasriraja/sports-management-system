# Phase 4.1 — Firebase security design

## Scope and project identification

This is a design and test-preparation document, not a deployment authorization.
No Firebase project configuration, deployed rules, production data, or paid
services were changed.

`lib/firebase_options.dart` configures project ID `sportsmanagement-58201` for
the generated Web, Android, and iOS options. The Android
`google-services.json` uses the same project ID and includes the Gradle
application ID. This confirms local configuration consistency only; the
project owner must confirm that this is the intended Firebase project before
any deployment or live-data test.

There is no root `firebase.json`, `.firebaserc`, or deployed/local
`firestore.rules`. `firestore.rules.proposed` is standalone, is not wired into
Firebase configuration, has not been compiled, and is not deployable as-is.

## Recommendation

Adopt **Option C: hybrid access**:

1. Keep direct Firestore reads only for explicitly approved, privacy-safe
   records, with Firestore Rules enforcing active identity, role, ownership,
   and query scope.
2. Route attendance creation/correction, session lifecycle changes, team
   membership mutations, student/account provisioning, role/status changes,
   register/team reservations, and administrator-count maintenance through
   authenticated callable Cloud Functions (or an equivalent trusted backend).
3. Have the backend re-read the actor's active user document on every
   privileged request, enforce the role and target ownership, validate
   canonical records, and perform the complete mutation in Firestore
   transactions. Admin SDK writes bypass Firestore Rules, so backend
   authorization and input validation are mandatory.
4. Deny direct client writes to backend-owned collections in rules. Provide
   clients only callable DTOs or privacy-safe Firestore projections.

Option A is not recommended for these workflows: rules can constrain many
single-document writes, but do not provide a safe general-purpose authorization
boundary for arbitrary base64url IDs, duplicate checks across independent
documents, transaction-wide attendance/audit coupling, or reliable
last-administrator protection. Option B is strongest for privileged
mutations, but moving every read to a backend increases complexity and
invocation/read cost. The hybrid minimizes that trade-off.

The repository already has a `functions/` Node 22 Firebase Functions codebase
and a callable sports assistant. The Phase 4.2 source implementation now adds
attendance and limited account-access callables; none has been deployed.
Cloud Functions deployment generally requires the Blaze
(billing-enabled) plan; confirm current Firebase pricing, quotas, region,
secrets, and owner approval before enabling or deploying anything. Local
emulator use does not deploy resources. Firestore reads/writes, function
invocations, logs, and network egress may incur production charges.

## Authorization matrix (target design)

Legend: **R** = read; **W** = write. “Self” means a verified UID-to-student
link. Session staff means the session's responsible UID. All access also
requires an authenticated, active account. Unlisted access is denied.

| Collection | Admin | Manager | Assigned Sports Staff | Unassigned Sports Staff | Student | Mutation authority |
|---|---|---|---|---|---|---|
| `users` | R all; W profiles/roles except unsafe last-admin transition | R permitted operational targets; manage Student accounts only | No general directory | No | R self-safe projection only | Backend for create, role/status, deactivation, admin counter |
| `students` | Safe DTO through admin workflow | Safe DTO through student workflow | No full documents; session roster DTO only | No | Safe self DTO only | Backend for create/edit/deactivate and account linkage |
| `attendance_sessions` | R/W all operational sessions | R/W all operational sessions | R/W own assigned sessions | No | No | Backend for create/edit/status; no delete |
| `attendance` | R all | R all | R own sessions only | No | R own linked history only | Backend only; deterministic record ID, transaction and eligibility checks |
| `attendance_audit` | R all | R all | R own sessions only | No | No | Backend append-only correction event in same transaction |
| `sports_teams` | R/W | R/W | R/W operational teams | No | R active, non-sensitive team metadata | Backend for writes |
| `team_memberships` | R/W | R/W | R/W operational rosters | No | R own membership only | Backend; active-team/student checks and deterministic membership ID |
| `student_register_numbers` | No direct access | No direct access | No | No | No | Backend-only reservation transaction |
| `sports_team_names` | No direct access | No direct access | No | No | No | Backend-only uniqueness reservation transaction |
| `system_counters/active_admins` | No direct access | No | No | No | No | Backend-only serialized transaction and reconciliation |
| `events` | R/W per existing event policy | R/W per existing event policy | R/W per existing event policy | No | R published events only | Rules for approved fields; backend if cross-document invariants apply |
| `achievements` | R/W per existing policy | R/W per existing policy | R/W per existing policy | No | R own records | Rules/backend after confirming actual workflows |
| `sports_equipment` | R/W inventory | R/W inventory | R loans/availability as needed | No | R available catalogue only | Rules/backend for inventory and stock invariants |
| `equipment_issues`, `equipment_returns` | R/W | R/W | R/W authorized issue workflow | No | R own loan history | Backend for issue/return and stock transactions |
| `gallery` | R/W per existing policy | R/W per existing policy | R/W per existing policy | No | R published items | Rules for published status and write roles |
| `notifications` | R/W management | R/W management | R only if recipient/authorized | No | R own recipient records | Backend for recipient assignment and system notifications |
| `reports` | R/W per existing report policy | R/W per existing report policy | No unless explicitly approved | No | No | Backend or tightly scoped rules; reports may contain aggregate/private data |
| `chatbot_rate_limits` | No client access | No client access | No client access | No | No client access | Existing callable/Admin SDK only |

The inventory was derived from literal Firestore collection paths in `lib/`
and `functions/`. Before adopting a ruleset, inspect every call site and
security-sensitive field in the non-attendance collections; the matrix rows
marked “per existing policy” are design targets, not verified deployed access.
Firestore Rules deny all paths not explicitly allowed, so a restrictive
ruleset will require coordinating and testing every existing screen/service.

## Privacy-limited attendance roster

Do not let Sports Staff read `students` documents: they contain unrelated
private profile fields. Replace `AttendanceService.getEligibleStudents`
with a callable `getAttendanceRoster(sessionId)` that:

1. Verifies Firebase Auth, reads the actor's active `users/{uid}` record, and
   permits Admin/Manager or the assigned Sports Staff only.
2. Reads the session, active team, membership set (if team-specific), and
   current active student records from canonical collections.
3. Returns only `{studentId, displayName, registerNumber}` (omit register
   number if it is not operationally required). Never return phone, email,
   address, medical, identity, or parent/guardian data.
4. Does not persist a duplicated roster. Each request derives it from current
   canonical state, avoiding stale projections after a student is deactivated
   or removed from a team. Attendance writes independently recheck eligibility
   in their transaction.

If a Firestore projection is later required for live roster listeners, store it
under a session-scoped path such as
`attendance_sessions/{sessionId}/roster/{studentId}`, allow only the assigned
staff/Admin/Manager to read it, and update it from trusted triggers or a
transactional workflow. Define deletion/repair behavior for membership and
student-status changes before relying on it. A projection does not replace
eligibility checks on each attendance mutation.

## Backend and rule changes proposed

1. Replace the fail-closed direct-write placeholders in
   `firestore.rules.proposed` with a reviewed, complete default-deny ruleset.
   Keep this file separate from production configuration until owner approval
   and emulator validation.
2. Lock privileged fields in `users`: clients cannot modify their own role,
   active status, UID, normalized register number, account linkage, or
   administrator fields. Allow self reads only through a safe projection;
   admin/manager writes use backend operations.
3. Deny all client writes to `attendance`, `attendance_audit`,
   `student_register_numbers`, `sports_team_names`, and `system_counters`.
4. Attendance session/roster/mark/correction and existing-user role/status
   callables are now implemented locally as described below. Remaining
   backend work includes team membership, user/student provisioning and
   updates, and register/team-name reservation operations.
5. Use a transaction for each attendance mutation: validate active actor,
   authorized session, active student, active team/membership, and session
   status; use the existing deterministic document ID; create the initial
   attendance record only if absent; for correction, require a non-empty
   reason and append the audit event in the same transaction. Make retries
   idempotent using a client-supplied operation ID stored/checked by the
   backend if retry semantics require it.
6. Enforce account/role policies in the backend, not by trusting `actorRole`
   supplied by a Flutter client. Consider custom claims only as a cache; role
   revocation must account for token-claim propagation delay.
7. Protect the last active Admin with a backend transaction serialized on a
   private counter/lock. Initialize it through a reviewed one-time migration,
   deny all client writes, and add a reconciliation operation. Do not treat
   the current client-side `active_admins` counter as authoritative.
8. Move student register-number and team-name uniqueness reservations behind
   backend transactions; prevent clients from reading or mutating those
   reservation records.
9. Add explicit rules for all inventoried collections and test query shapes.
   Split private student fields from safe account/profile/roster DTOs where
   collection-level rules cannot safely authorize individual fields.
10. Protect Cloud Functions with Firebase Auth checks and consider App Check,
    rate limits, structured audit logging, and least-privilege IAM. App Check
    is defense-in-depth, not user authorization.

## Emulator Rules Unit Testing

`security-tests/` contains an isolated Rules Unit Testing harness. It loads
`../firestore.rules.proposed`, seeds synthetic documents with rules disabled,
and tests active-role reads, assigned-session scope, self-history scope,
student document privacy, role/status changes, team membership, and denial of
direct privileged writes and private reservation/counter access.

The rules proposal intentionally denies client attendance writes. The Rules
suite validates direct client access only; it does **not** test a Cloud
Function's transaction, duplicate handling, audit coupling, or last-admin
concurrency. The separate Functions emulator test source described below
addresses several of those behaviors, but has not been run.

The current Functions emulator test source covers duplicate concurrent first
marks, missing correction reasons and matching audit data, inactive/non-team
eligibility, session ownership/status, student history isolation, account
self-change and role escalation, and concurrent Admin deactivation. Further
coverage should include concurrent correction races, inactive-team and removed
membership cases, counter-recovery operations (none is implemented), and
end-to-end invocation through the Functions Emulator to validate callable
token handling.

The current proposal is intentionally stricter than the target matrix for
private profiles and mutations: it allows no direct reads of `students` and no
direct mutations of sessions, accounts, teams, memberships, attendance, or
reservation/counter documents. Convert affected callers before treating these
rules as an operational ruleset. In particular, current student login performs
an unauthenticated register-number/phone lookup in `users`; replace that
enumerating client query with a reviewed sign-in flow (prefer a direct
Firebase-Auth identifier, or a rate-limited backend that does not disclose
whether an account exists). Public Sports Staff registration and student
provisioning also currently write user profiles from the client and need
backend-mediated provisioning. Do not loosen rules simply to preserve those
flows.

Run only against the emulator and the demo project ID; this does not target the
configured production project:

```powershell
cd security-tests
npm install
npx firebase emulators:exec --project demo-mrcas-security-tests --only firestore "npm test"
```

Prerequisites: Node.js 20+ (the Functions package specifies Node 22), npm,
Firebase CLI (`firebase-tools`), and a Java runtime supported by the selected
Firestore Emulator. No production credentials are required. The test package
uses demo project ID `demo-mrcas-security-tests`. Do not use a real project ID
or deploy rules for this command.

## Phase 4.2 backend implementation status

The following callable handler implementations are present in `functions/`
and are wrapped by Firebase Functions v2 `onCall` exports in
[`functions/index.js`](./functions/index.js):

| Callable | Authorization and behavior |
|---|---|
| `createAttendanceSession` | Active Admin, Manager, or Sports Staff; server assigns session ID and responsible UID; selected team must be active and match the sport. |
| `updateAttendanceSession` | Admin/Manager or owning Sports Staff; only scheduled sessions can be edited. |
| `updateAttendanceSessionStatus` | Admin/Manager or owning Sports Staff; validates scheduled/active/completed/cancelled transitions. |
| `listAttendanceSessions` | Admin/Manager see operational sessions; Sports Staff query is scoped to their responsible UID. |
| `getAttendanceRoster` | Authorized session staff only; returns only student ID, name, and register number; team sessions use current memberships and active student profiles. |
| `markSessionAttendance` | Admin/Manager or owning Sports Staff; active session and active student required, plus active team and matching membership when team-bound; status and corrections validated transactionally. |
| `getOwnAttendanceHistory` | Active Student profile only; the student ID is derived from authenticated UID, never request data. |
| `getAttendanceSessionSummary` | Admin/Manager or owning Sports Staff; calculated from actual session records. |
| `setManagedUserAccess` | Admin only; changes an existing user's role/status, rejects self-changes and Admin assignment, and prevents removal of the last active Admin. |

The implementation is in [`authorization.js`](./functions/src/authorization.js),
[`attendance_policy.js`](./functions/src/attendance_policy.js),
[`attendance_backend.js`](./functions/src/attendance_backend.js), and
[`account_backend.js`](./functions/src/account_backend.js). User role and
active status are loaded from `users/{authenticated UID}`; request-supplied UID,
role, session owner, timestamps, and audit IDs are not authoritative. Attendance
document IDs use the same padded base64url encoding of the JSON
`[sessionId, studentId]` tuple as the current Flutter service, so an existing
record at that canonical ID is updated instead of duplicated. Corrections
require a reason and write the attendance change and append-only
`attendance_audit` event in one transaction. Repeating a mark with the same
status is idempotent. Legacy records with different IDs are not migrated or
silently removed.

The roster is computed from canonical documents on each request rather than a
persisted projection; this avoids staleness but costs reads and has no
push-updated client listener. Only `{studentId, displayName, registerNumber}`
is returned. Register number is included because the existing attendance
workflow uses it to identify students; remove it from the DTO if that field is
not operationally necessary. The summary denominator is
`Present + Absent + Late`; Late counts as attended, Excused and unmarked
students are excluded, and cancelled sessions return zero counts and a null
percentage. These policies need owner/product confirmation before rollout.

The account endpoint does not provision Firebase Auth users or create/promote
an Admin. It recomputes active Admin count from `users` in a Firestore
transaction and writes `system_counters/active_admins` as a serialization
point. Correctness depends on every Admin role/status mutation using this
backend and on the initial Admin bootstrap/recovery procedure keeping the
counter in sync. After the Firestore profile change commits, Auth disable/token
revocation is attempted separately; an Auth failure returns
`authSynchronized: false` and requires operator follow-up. Profile status
revocation cannot guarantee an already-issued Firebase session immediately
stops working in any client that has not adopted server authorization.

No Flutter client has been migrated: the source callables are not deployed and
the emulator suite has not passed. Deploying the strict proposal before the
client migration would break these existing direct-client workflows:

- [`attendance_service.dart`](./lib/database/services/attendance_service.dart):
  session create/edit/status, session streams, student roster reads, attendance
  writes/corrections, and direct attendance reads/summaries.
- [`student_service.dart`](./lib/database/services/student_service.dart) and
  [`user_service.dart`](./lib/database/services/user_service.dart): student
  creation/edit/deactivation, user provisioning/role/status management,
  register-number reservations, active-Admin counter access, user lists, and
  user role/profile streams.
- [`team_service.dart`](./lib/database/services/team_service.dart): team
  creation/edit/deactivation, team-name reservations, membership reads, and
  membership changes.
- [`firestore_service.dart`](./lib/database/firestore_service.dart): direct
  register-number/phone credential lookup in `users`, including its
  unauthenticated account-enumeration risk.

Before client migration, implement and test backend provisioning for Auth and
student profiles, student editing/deactivation, team and membership changes,
register/team-name reservations, an enumeration-resistant sign-in replacement,
and any safe user/team DTO reads required by the screens. Migrate the Flutter
clients to the callable contracts; ensure failures surface as failures and do
not show success before the callable resolves. Then test the complete app
against an approved demo/staging Firebase project with the reviewed Rules.
Do not deploy the rules or callables to `sportsmanagement-58201` unless the
owner confirms it is the intended target.

### Phase 4.2 tests and limitations

Added `node:test` policy/authorization tests and
[`attendance_backend.emulator.test.js`](./functions/test/attendance_backend.emulator.test.js).
The latter is explicitly skipped unless `FIRESTORE_EMULATOR_HOST` is set; it
uses project ID `demo-mrcas-functions-tests`, synthetic records, and a stubbed
Auth Admin adapter. It covers inactive/unauthenticated callers, Student staff
operation denial, session ownership, team eligibility, session status
restrictions, concurrent duplicate marks, correction/audit atomicity, own
history isolation, role escalation denial, and concurrent last-Admin
protection. Since it invokes backend factories directly, it does not verify
Firebase callable token verification, deployed rules, Auth Emulator behavior,
or production IAM.

The current environment has Flutter/Dart but no `node`, `npm`, Firebase CLI, or
Java executable. Consequently the Node tests and Firestore/Functions Emulator
tests have not run. No Rules compilation, live Firebase test, deployment,
production write, or paid-service enablement has occurred. Run backend tests
after installing the Node 22 package dependencies with:

```powershell
cd functions
npm test
```

For the integration tests, start the Firestore Emulator using the existing
isolated rules-test config (Admin SDK test writes bypass those client rules):

```powershell
firebase emulators:start --config security-tests\firebase.json --project demo-mrcas-functions-tests --only firestore
```

In a second PowerShell session, run:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
Set-Location functions
npm test
```

No root Firebase CLI config exists for Functions deployment. Do not use the
configured production project ID for these tests. Java and Firebase CLI are
emulator prerequisites; deployed Cloud Functions may require Blaze billing,
which must not be enabled without approval.

## Verification performed for Phase 4.1

- Project ID read from local FlutterFire options: `sportsmanagement-58201`;
  owner confirmation is still required.
- No Firebase CLI, npm, Node, or Java executable was available for emulator
  setup or tests.
- Flutter analyzer: `No issues found!` (ran in 4.8s).
- Flutter tests: `All tests passed!` — 34 passed, 0 failed.
- No live Firebase test, emulator test, rules compilation, rules deployment,
  production write, or paid-service enablement was performed.
