const test = require('node:test');
const assert = require('node:assert/strict');

const {
  BackendError,
  ROLES,
  actorFromSnapshot,
  assertSessionAccess,
  requireActor,
  requireIdentity,
  requiredString,
} = require('../src/authorization');

test('identity is required and malformed identities are rejected', () => {
  for (const request of [undefined, {}, { auth: {} }, { auth: { uid: ' ' } }]) {
    assert.throws(
      () => requireIdentity(request),
      (error) => error instanceof BackendError && error.code === 'unauthenticated',
    );
  }
  assert.equal(requireIdentity({ auth: { uid: ' staff-1 ' } }), 'staff-1');
});

test('actor profiles must exist, be active, and use a known role', () => {
  assert.throws(
    () => actorFromSnapshot({ exists: false }, 'u1'),
    (error) => error.code === 'permission-denied',
  );
  assert.throws(
    () =>
      actorFromSnapshot(
        { exists: true, data: () => ({ role: ROLES.admin, status: 'inactive' }) },
        'u1',
      ),
    (error) => error.code === 'permission-denied',
  );
  assert.throws(
    () =>
      actorFromSnapshot(
        { exists: true, data: () => ({ role: 'Owner', status: 'active' }) },
        'u1',
      ),
    (error) => error.code === 'permission-denied',
  );
  assert.equal(
    actorFromSnapshot(
      { exists: true, data: () => ({ role: ROLES.manager, status: 'Active' }) },
      'u1',
    ).role,
    ROLES.manager,
  );
});

test('server role comes from Firestore, not request data', async () => {
  const db = {
    collection(name) {
      assert.equal(name, 'users');
      return {
        doc(uid) {
          assert.equal(uid, 'staff-1');
          return {
            async get() {
              return {
                exists: true,
                data: () => ({ role: ROLES.sportsStaff, status: 'active' }),
              };
            },
          };
        },
      };
    },
  };
  const actor = await requireActor(
    {
      auth: { uid: 'staff-1' },
      data: { actorUid: 'admin-1', actorRole: ROLES.admin },
    },
    db,
    [ROLES.admin, ROLES.sportsStaff],
  );
  assert.equal(actor.uid, 'staff-1');
  assert.equal(actor.role, ROLES.sportsStaff);
});

test('staff may access only sessions whose responsible UID matches auth', () => {
  const actor = { uid: 'staff-1', role: ROLES.sportsStaff };
  assert.doesNotThrow(() =>
    assertSessionAccess(actor, { responsibleUid: 'staff-1' }),
  );
  assert.throws(
    () => assertSessionAccess(actor, { responsibleUid: 'staff-2' }),
    (error) => error.code === 'permission-denied',
  );
  assert.doesNotThrow(() =>
    assertSessionAccess(
      { uid: 'manager-1', role: ROLES.manager },
      { responsibleUid: 'staff-2' },
    ),
  );
});

test('required fields reject non-strings, blanks, and oversized values', () => {
  assert.equal(requiredString(' session-1 ', 'session ID'), 'session-1');
  for (const value of [null, 5, '', '  ', 'x'.repeat(9)]) {
    assert.throws(
      () => requiredString(value, 'session ID', 8),
      (error) => error.code === 'invalid-argument',
    );
  }
});
