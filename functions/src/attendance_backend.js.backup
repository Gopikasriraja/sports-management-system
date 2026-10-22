const {
  BackendError,
  ROLES,
  STAFF_ROLES,
  assertSessionAccess,
  requireActor,
  requireActorInTransaction,
  requiredString,
} = require('./authorization');
const {
  SESSION_STATUSES,
  attendanceId,
  attendanceSummary,
  validateAttendanceStatus,
  validateCorrection,
  validateSessionInput,
  validateSessionTransition,
} = require('./attendance_policy');

const MAX_PAGE_SIZE = 200;
const MAX_HISTORY_SIZE = 500;

function createAttendanceBackend({ db, FieldValue }) {
  const users = db.collection('users');
  const sessions = db.collection('attendance_sessions');
  const attendance = db.collection('attendance');
  const audit = db.collection('attendance_audit');
  const students = db.collection('students');
  const teams = db.collection('sports_teams');
  const memberships = db.collection('team_memberships');

  async function authorizedSession(actor, sessionId) {
    const snapshot = await sessions.doc(sessionId).get();
    if (!snapshot.exists) {
      throw new BackendError('not-found', 'Attendance session not found.');
    }
    const session = snapshot.data();
    assertSessionAccess(actor, session);
    return { reference: snapshot.ref, session };
  }

  async function createSession(request) {
    const parsed = validateSessionInput(request.data);
    if (parsed.error) {
      throw new BackendError('invalid-argument', parsed.error);
    }
    const reference = sessions.doc();
    await db.runTransaction(async (transaction) => {
      const actor = await requireActorInTransaction(
        transaction,
        db,
        request,
        [...STAFF_ROLES],
      );
      const { value } = parsed;
      let teamName = '';
      if (value.teamId) {
        const teamSnapshot = await transaction.get(teams.doc(value.teamId));
        if (
          !teamSnapshot.exists ||
          String(teamSnapshot.data().status || '').toLowerCase() !== 'active'
        ) {
          throw new BackendError(
            'failed-precondition',
            'Select an existing active team.',
          );
        }
        teamName = String(teamSnapshot.data().name || '');
        const teamSport = String(teamSnapshot.data().sport || '');
        if (teamSport.trim().toLowerCase() !== value.sport.toLowerCase()) {
          throw new BackendError(
            'invalid-argument',
            'The session sport must match the selected team.',
          );
        }
      }
      transaction.create(reference, {
        ...value,
        teamName,
        status: 'scheduled',
        responsibleUid: actor.uid,
        responsibleName: String(actor.profile.name || ''),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return { sessionId: reference.id };
  }

  async function updateSession(request) {
    const sessionId = requiredString(request.data?.sessionId, 'session ID', 128);
    const parsed = validateSessionInput(request.data);
    if (parsed.error) {
      throw new BackendError('invalid-argument', parsed.error);
    }
    await db.runTransaction(async (transaction) => {
      const actor = await requireActorInTransaction(
        transaction,
        db,
        request,
        [...STAFF_ROLES],
      );
      const reference = sessions.doc(sessionId);
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw new BackendError('not-found', 'Attendance session not found.');
      }
      const current = snapshot.data();
      assertSessionAccess(actor, current);
      if (current.status !== 'scheduled') {
        throw new BackendError(
          'failed-precondition',
          'Only scheduled sessions can be edited.',
        );
      }
      const { value } = parsed;
      let teamName = '';
      if (value.teamId) {
        const teamSnapshot = await transaction.get(teams.doc(value.teamId));
        if (
          !teamSnapshot.exists ||
          String(teamSnapshot.data().status || '').toLowerCase() !== 'active'
        ) {
          throw new BackendError(
            'failed-precondition',
            'Select an existing active team.',
          );
        }
        teamName = String(teamSnapshot.data().name || '');
        if (
          String(teamSnapshot.data().sport || '').trim().toLowerCase() !==
          value.sport.toLowerCase()
        ) {
          throw new BackendError(
            'invalid-argument',
            'The session sport must match the selected team.',
          );
        }
      }
      transaction.update(reference, {
        ...value,
        teamName,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return { sessionId };
  }

  async function updateSessionStatus(request) {
    const sessionId = requiredString(request.data?.sessionId, 'session ID', 128);
    const status = request.data?.status;
    if (!SESSION_STATUSES.includes(status)) {
      throw new BackendError('invalid-argument', 'Choose a valid session status.');
    }
    await db.runTransaction(async (transaction) => {
      const actor = await requireActorInTransaction(
        transaction,
        db,
        request,
        [...STAFF_ROLES],
      );
      const reference = sessions.doc(sessionId);
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw new BackendError('not-found', 'Attendance session not found.');
      }
      const session = snapshot.data();
      assertSessionAccess(actor, session);
      if (!validateSessionTransition(session.status, status)) {
        throw new BackendError(
          'failed-precondition',
          `A ${session.status} session cannot be changed to ${status}.`,
        );
      }
      transaction.update(reference, {
        status,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return { sessionId, status };
  }

  async function listSessions(request) {
    const actor = await requireActor(request, db, [...STAFF_ROLES]);
    const pageSize = Math.max(
      1,
      Math.min(Number(request.data?.pageSize) || 100, MAX_PAGE_SIZE),
    );
    let query = sessions.orderBy('date', 'desc').limit(pageSize);
    if (actor.role === ROLES.sportsStaff) {
      query = sessions
        .where('responsibleUid', '==', actor.uid)
        .orderBy('date', 'desc')
        .limit(pageSize);
    }
    if (typeof request.data?.pageToken === 'string' && request.data.pageToken) {
      const cursor = await sessions.doc(request.data.pageToken).get();
      if (!cursor.exists) {
        throw new BackendError('invalid-argument', 'The page token is invalid.');
      }
      query = query.startAfter(cursor);
    }
    const snapshot = await query.get();
    return {
      sessions: snapshot.docs.map((document) => ({
        sessionId: document.id,
        ...document.data(),
      })),
      nextPageToken:
        snapshot.size === pageSize ? snapshot.docs.at(-1).id : null,
    };
  }

  async function getRoster(request) {
    const actor = await requireActor(request, db, [...STAFF_ROLES]);
    const sessionId = requiredString(request.data?.sessionId, 'session ID', 128);
    const pageSize = Math.max(
      1,
      Math.min(Number(request.data?.pageSize) || MAX_PAGE_SIZE, MAX_PAGE_SIZE),
    );
    const { session } = await authorizedSession(actor, sessionId);
    let source;
    let studentIds;
    if (session.teamId) {
      const teamSnapshot = await teams.doc(session.teamId).get();
      if (
        !teamSnapshot.exists ||
        String(teamSnapshot.data().status || '').toLowerCase() !== 'active' ||
        String(teamSnapshot.data().sport || '').trim().toLowerCase() !==
          String(session.sport || '').trim().toLowerCase()
      ) {
        throw new BackendError(
          'failed-precondition',
          'The session team is no longer active or does not match its sport.',
        );
      }
      let query = memberships
        .where('teamId', '==', session.teamId)
        .orderBy('studentId')
        .limit(pageSize);
      if (typeof request.data?.pageToken === 'string' && request.data.pageToken) {
        const cursor = await memberships.doc(request.data.pageToken).get();
        if (!cursor.exists || cursor.data().teamId !== session.teamId) {
          throw new BackendError('invalid-argument', 'The page token is invalid.');
        }
        query = query.startAfter(cursor);
      }
      source = await query.get();
      studentIds = source.docs
        .map((document) => document.data().studentId)
        .filter((id) => typeof id === 'string' && id.length > 0);
    } else {
      let query = students
        .where('status', 'in', ['active', 'Active'])
        .orderBy('name')
        .limit(pageSize);
      if (typeof request.data?.pageToken === 'string' && request.data.pageToken) {
        const cursor = await students.doc(request.data.pageToken).get();
        if (!cursor.exists) {
          throw new BackendError('invalid-argument', 'The page token is invalid.');
        }
        query = query.startAfter(cursor);
      }
      source = await query.get();
      studentIds = source.docs.map((document) => document.id);
    }
    const snapshots = session.teamId
      ? await Promise.all(studentIds.map((id) => students.doc(id).get()))
      : source.docs;
    return {
      students: snapshots
        .filter(
          (snapshot) =>
            snapshot.exists &&
            String(snapshot.data().status || '').toLowerCase() === 'active',
        )
        .map((snapshot) => ({
          studentId: snapshot.id,
          displayName: String(snapshot.data().name || ''),
          registerNumber: String(snapshot.data().registerNumber || ''),
        })),
      nextPageToken:
        source.size === pageSize ? source.docs.at(-1).id : null,
    };
  }

  async function markAttendance(request) {
    const sessionId = requiredString(request.data?.sessionId, 'session ID', 128);
    const studentId = requiredString(request.data?.studentId, 'student ID', 128);
    const status = request.data?.status;
    if (!validateAttendanceStatus(status)) {
      throw new BackendError('invalid-argument', 'Choose a valid attendance status.');
    }
    const recordReference = attendance.doc(attendanceId(sessionId, studentId));
    const auditReference = audit.doc();
    const result = await db.runTransaction(async (transaction) => {
      const actor = await requireActorInTransaction(
        transaction,
        db,
        request,
        [...STAFF_ROLES],
      );
      const sessionReference = sessions.doc(sessionId);
      const studentReference = students.doc(studentId);
      const [sessionSnapshot, studentSnapshot, existing] = await Promise.all([
        transaction.get(sessionReference),
        transaction.get(studentReference),
        transaction.get(recordReference),
      ]);
      if (!sessionSnapshot.exists) {
        throw new BackendError('not-found', 'Attendance session not found.');
      }
      const session = sessionSnapshot.data();
      assertSessionAccess(actor, session);
      if (session.status !== 'active') {
        throw new BackendError(
          'failed-precondition',
          'Attendance can only be changed for an active session.',
        );
      }
      if (
        !studentSnapshot.exists ||
        String(studentSnapshot.data().status || '').toLowerCase() !== 'active'
      ) {
        throw new BackendError(
          'failed-precondition',
          'Only active students are eligible for attendance.',
        );
      }
      if (session.teamId) {
        const memberReference = memberships.doc(`${session.teamId}--${studentId}`);
        const teamReference = teams.doc(session.teamId);
        const [membership, team] = await Promise.all([
          transaction.get(memberReference),
          transaction.get(teamReference),
        ]);
        if (
          !membership.exists ||
          membership.data().teamId !== session.teamId ||
          membership.data().studentId !== studentId
        ) {
          throw new BackendError(
            'failed-precondition',
            'This student is not on the selected team roster.',
          );
        }
        if (
          !team.exists ||
          String(team.data().status || '').toLowerCase() !== 'active' ||
          String(team.data().sport || '').trim().toLowerCase() !==
            String(session.sport || '').trim().toLowerCase()
        ) {
          throw new BackendError(
            'failed-precondition',
            'The session team is no longer active or does not match its sport.',
          );
        }
      }
      const previous = existing.data() || {};
      const reason = typeof request.data?.correctionReason === 'string'
        ? request.data.correctionReason.trim()
        : '';
      const correctionError = validateCorrection({
        existing: existing.exists,
        previousStatus: previous.status,
        status,
        reason,
      });
      if (correctionError) {
        throw new BackendError('invalid-argument', correctionError);
      }
      if (existing.exists && previous.status === status) {
        return { attendanceId: recordReference.id, changed: false };
      }
      const now = FieldValue.serverTimestamp();
      if (existing.exists) {
        transaction.update(recordReference, {
          status,
          updatedBy: actor.uid,
          updatedAt: now,
          correctionReason: reason,
        });
        transaction.create(auditReference, {
          sessionId,
          studentId,
          previousStatus: previous.status,
          newStatus: status,
          correctedBy: actor.uid,
          correctionReason: reason,
          changedAt: now,
        });
      } else {
        const student = studentSnapshot.data();
        transaction.create(recordReference, {
          attendanceId: recordReference.id,
          sessionId,
          studentId,
          studentName: String(student.name || ''),
          registerNumber: String(student.registerNumber || ''),
          department: String(student.department || ''),
          sport: String(session.sport || ''),
          date: session.date,
          status,
          markedBy: actor.uid,
          createdAt: now,
          updatedBy: actor.uid,
          updatedAt: now,
          correctionReason: '',
        });
      }
      return { attendanceId: recordReference.id, changed: true };
    });
    return result;
  }

  async function getOwnHistory(request) {
    const actor = await requireActor(request, db, [ROLES.student]);
    const snapshot = await attendance
      .where('studentId', '==', actor.uid)
      .orderBy('date', 'desc')
      .limit(MAX_HISTORY_SIZE)
      .get();
    return {
      records: snapshot.docs.map((document) => {
        const record = document.data();
        return {
          attendanceId: document.id,
          sessionId: String(record.sessionId || ''),
          sport: String(record.sport || ''),
          date: record.date || null,
          status: String(record.status || ''),
        };
      }),
      truncated: snapshot.size === MAX_HISTORY_SIZE,
    };
  }

  async function getSessionSummary(request) {
    const actor = await requireActor(request, db, [...STAFF_ROLES]);
    const sessionId = requiredString(request.data?.sessionId, 'session ID', 128);
    const { session } = await authorizedSession(actor, sessionId);
    const snapshot = await attendance.where('sessionId', '==', sessionId).get();
    const summary = attendanceSummary(
      snapshot.docs.map((document) => document.data()),
      session.status,
    );
    return { sessionId, ...summary };
  }

  return Object.freeze({
    createSession,
    updateSession,
    updateSessionStatus,
    listSessions,
    getRoster,
    markAttendance,
    getOwnHistory,
    getSessionSummary,
  });
}

module.exports = { createAttendanceBackend };
