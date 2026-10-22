const {
  BackendError,
  ROLES,
  requireActorInTransaction,
  requiredString,
} = require('./authorization');

const ASSIGNABLE_ROLES = Object.freeze([
  ROLES.manager,
  ROLES.sportsStaff,
  ROLES.student,
]);

function createAccountBackend({ db, FieldValue, authAdmin, logger }) {
  async function setUserAccess(request) {
    const targetUid = requiredString(request.data?.targetUid, 'target UID', 128);
    const requestedRole = request.data?.role;
    const requestedStatus = request.data?.status;
    if (
      requestedRole !== undefined &&
      !ASSIGNABLE_ROLES.includes(requestedRole)
    ) {
      throw new BackendError(
        'invalid-argument',
        'Only Manager, Sports Staff, and Student roles can be assigned through this operation.',
      );
    }
    if (
      requestedStatus !== undefined &&
      !['active', 'inactive'].includes(
        String(requestedStatus).toLowerCase(),
      )
    ) {
      throw new BackendError(
        'invalid-argument',
        'Account status must be active or inactive.',
      );
    }
    if (requestedRole === undefined && requestedStatus === undefined) {
      throw new BackendError(
        'invalid-argument',
        'Provide a role or status change.',
      );
    }
    const targetReference = db.collection('users').doc(targetUid);
    const counterReference = db
      .collection('system_counters')
      .doc('active_admins');
    const committed = await db.runTransaction(async (transaction) => {
      const actor = await requireActorInTransaction(
        transaction,
        db,
        request,
        [ROLES.admin],
      );
      if (actor.uid === targetUid) {
        throw new BackendError(
          'permission-denied',
          'Administrators cannot modify their own role or active status.',
        );
      }
      const [targetSnapshot, counterSnapshot] = await Promise.all([
        transaction.get(targetReference),
        transaction.get(counterReference),
      ]);
      if (!targetSnapshot.exists) {
        throw new BackendError('not-found', 'The target user was not found.');
      }
      const target = targetSnapshot.data();
      const nextRole = requestedRole ?? target.role;
      const nextStatus = requestedStatus === undefined
        ? String(target.status || '').toLowerCase()
        : String(requestedStatus).toLowerCase();
      if (!Object.values(ROLES).includes(target.role)) {
        throw new BackendError(
          'failed-precondition',
          'The target user has an invalid role; resolve it through the recovery procedure.',
        );
      }
      const admins = await transaction.get(
        db.collection('users').where('role', '==', ROLES.admin),
      );
      const activeAdminCount = admins.docs.filter(
        (document) =>
          String(document.data().status || '').toLowerCase() === 'active',
      ).length;
      const wasActiveAdmin =
        target.role === ROLES.admin &&
        String(target.status || '').toLowerCase() === 'active';
      const willBeActiveAdmin =
        nextRole === ROLES.admin && nextStatus === 'active';
      const nextAdminCount =
        activeAdminCount +
        (willBeActiveAdmin ? 1 : 0) -
        (wasActiveAdmin ? 1 : 0);
      if (wasActiveAdmin && !willBeActiveAdmin && nextAdminCount < 1) {
        throw new BackendError(
          'failed-precondition',
          'The last active administrator cannot be deactivated.',
        );
      }
      transaction.set(counterReference, {
        count: nextAdminCount,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.update(targetReference, {
        role: nextRole,
        status: nextStatus,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { uid: targetUid, status: nextStatus };
    });

    let authSynchronized = true;
    try {
      await authAdmin.updateUser(targetUid, {
        disabled: committed.status !== 'active',
      });
      if (committed.status !== 'active') {
        await authAdmin.revokeRefreshTokens(targetUid);
      }
    } catch (error) {
      authSynchronized = false;
      logger?.error('User profile updated but Auth state synchronization failed.', {
        uid: targetUid,
        code: error?.code || 'unknown',
      });
    }
    return {
      ...committed,
      authSynchronized,
      message: authSynchronized
        ? 'Account access updated.'
        : 'Firestore access was updated, but Firebase Auth session revocation needs administrator follow-up.',
    };
  }

  return Object.freeze({ setUserAccess });
}

module.exports = { ASSIGNABLE_ROLES, createAccountBackend };
