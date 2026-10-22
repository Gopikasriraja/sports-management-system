const ROLES = Object.freeze({
  admin: 'Admin',
  manager: 'Manager',
  sportsStaff: 'Sports Staff',
  student: 'Student',
});

const ACTIVE_STATUSES = new Set(['active']);
const STAFF_ROLES = new Set([ROLES.admin, ROLES.manager, ROLES.sportsStaff]);
const BROAD_STAFF_ROLES = new Set([ROLES.admin, ROLES.manager]);

class BackendError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'BackendError';
    this.code = code;
  }
}

function requireIdentity(request) {
  const uid = request?.auth?.uid;
  if (typeof uid !== 'string' || uid.trim().length === 0) {
    throw new BackendError('unauthenticated', 'Sign in to perform this action.');
  }
  return uid.trim();
}

function actorFromSnapshot(snapshot, uid) {
  if (!snapshot?.exists) {
    throw new BackendError(
      'permission-denied',
      'No active user profile exists for this account.',
    );
  }
  const profile = snapshot.data() || {};
  if (!ACTIVE_STATUSES.has(String(profile.status || '').toLowerCase())) {
    throw new BackendError('permission-denied', 'This account is inactive.');
  }
  if (!Object.values(ROLES).includes(profile.role)) {
    throw new BackendError('permission-denied', 'This account has no valid role.');
  }
  return Object.freeze({ uid, role: profile.role, profile });
}

async function requireActor(request, db, allowedRoles) {
  const uid = requireIdentity(request);
  const snapshot = await db.collection('users').doc(uid).get();
  const actor = actorFromSnapshot(snapshot, uid);
  if (allowedRoles && !allowedRoles.includes(actor.role)) {
    throw new BackendError(
      'permission-denied',
      'Your account is not authorized to perform this action.',
    );
  }
  return actor;
}

async function requireActorInTransaction(transaction, db, request, allowedRoles) {
  const uid = requireIdentity(request);
  const snapshot = await transaction.get(db.collection('users').doc(uid));
  const actor = actorFromSnapshot(snapshot, uid);
  if (allowedRoles && !allowedRoles.includes(actor.role)) {
    throw new BackendError(
      'permission-denied',
      'Your account is not authorized to perform this action.',
    );
  }
  return actor;
}

function assertSessionAccess(actor, session) {
  if (BROAD_STAFF_ROLES.has(actor.role)) return;
  if (
    actor.role === ROLES.sportsStaff &&
    session.responsibleUid === actor.uid
  ) {
    return;
  }
  throw new BackendError(
    'permission-denied',
    'You are not assigned to manage this session.',
  );
}

function requiredString(value, field, maxLength = 200) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new BackendError('invalid-argument', `A valid ${field} is required.`);
  }
  const normalized = value.trim();
  if (normalized.length > maxLength) {
    throw new BackendError(
      'invalid-argument',
      `${field} must be ${maxLength} characters or fewer.`,
    );
  }
  return normalized;
}

module.exports = {
  ACTIVE_STATUSES,
  BackendError,
  BROAD_STAFF_ROLES,
  ROLES,
  STAFF_ROLES,
  actorFromSnapshot,
  assertSessionAccess,
  requireActor,
  requireActorInTransaction,
  requireIdentity,
  requiredString,
};
