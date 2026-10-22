const test = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createAttendanceBackend } = require('../src/attendance_backend');
const { createAccountBackend } = require('../src/account_backend');
const { BackendError, ROLES } = require('../src/authorization');

const emulatorAvailable = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let db;
let FieldValue;
let attendanceBackend;
let accountBackend;
let app;

test.before(async () => {
  if (!emulatorAvailable) return;
  const { initializeApp } = require('firebase-admin/app');
  ({ FieldValue } = require('firebase-admin/firestore'));
  const { getFirestore } = require('firebase-admin/firestore');
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  app = initializeApp(
    { projectId: 'demo-mrcas-functions-tests' },
    `mrcas-functions-test-${randomUUID()}`,
  );
  db = getFirestore(app);
  db.settings({ host, ssl: false });
  attendanceBackend = createAttendanceBackend({ db, FieldValue });
  accountBackend = createAccountBackend({
    db,
    FieldValue,
    authAdmin: {
      async updateUser() {},
      async revokeRefreshTokens() {},
    },
    logger: { error() {} },
  });
});

test.after(async () => {
  if (app) await app.delete();
});

function runTest(name, fn) {
  test(name, { skip: !emulatorAvailable }, fn);
}

function uid(prefix) {
  return `${prefix}-${randomUUID()}`;
}

async function seedUser(id, role, status = 'active') {
  await db.collection('users').doc(id).set({
    uid: id,
    name: id,
    email: `${id}@example.test`,
    role,
    status,
    registerNumber: '',
  });
}

async function seedSession(id, responsibleUid, status, teamId = '') {
  await db.collection('attendance_sessions').doc(id).set({
    title: 'Training',
    sport: 'Football',
    teamId,
    teamName: teamId ? 'Team' : '',
    date: new Date('2026-10-22T09:00:00.000Z'),
    startTime: '09:00',
    endTime: '10:00',
    venue: 'Ground',
    status,
    responsibleUid,
    responsibleName: responsibleUid,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
}

function request(actorUid, data = {}) {
  return { auth: actorUid ? { uid: actorUid } : null, data };
}

function rejectedWithCode(promise, code) {
  return assert.rejects(
    promise,
    (error) => error instanceof BackendError && error.code === code,
  );
}

runTest('unauthenticated, inactive, and Student staff operations are rejected', async () => {
  await rejectedWithCode(
    attendanceBackend.listSessions(request(null)),
    'unauthenticated',
  );
  const inactive = uid('inactive');
  const student = uid('student');
  await seedUser(inactive, ROLES.sportsStaff, 'inactive');
  await seedUser(student, ROLES.student);
  await rejectedWithCode(
    attendanceBackend.listSessions(request(inactive)),
    'permission-denied',
  );
  await rejectedWithCode(
    attendanceBackend.createSession(request(student, {
      title: 'Training',
      sport: 'Football',
      venue: 'Ground',
      startTime: '09:00',
      endTime: '10:00',
      dateMillis: Date.now(),
    })),
    'permission-denied',
  );
});

runTest('Sports Staff cannot access another staff member session', async () => {
  const staff = uid('staff');
  const owner = uid('owner');
  const sessionId = uid('session');
  await seedUser(staff, ROLES.sportsStaff);
  await seedUser(owner, ROLES.sportsStaff);
  await seedSession(sessionId, owner, 'active');
  await rejectedWithCode(
    attendanceBackend.getRoster(request(staff, { sessionId })),
    'permission-denied',
  );
});

runTest('ineligible student and missing team membership are rejected', async () => {
  const staff = uid('staff');
  const student = uid('student');
  const sessionId = uid('session');
  const teamId = uid('team');
  await seedUser(staff, ROLES.sportsStaff);
  await db.collection('students').doc(student).set({
    name: 'Student',
    registerNumber: 'R-1',
    department: 'Sports',
    status: 'Active',
  });
  await db.collection('sports_teams').doc(teamId).set({
    name: 'Team',
    sport: 'Football',
    status: 'active',
  });
  await seedSession(sessionId, staff, 'active', teamId);
  await rejectedWithCode(
    attendanceBackend.markAttendance(
      request(staff, { sessionId, studentId: student, status: 'Present' }),
    ),
    'failed-precondition',
  );
  await db.collection('students').doc(student).update({ status: 'Inactive' });
  await db.collection('team_memberships').doc(`${teamId}--${student}`).set({
    teamId,
    studentId: student,
  });
  await rejectedWithCode(
    attendanceBackend.markAttendance(
      request(staff, { sessionId, studentId: student, status: 'Present' }),
    ),
    'failed-precondition',
  );
});

runTest('attendance writes are blocked until a session is active', async () => {
  const staff = uid('staff');
  const student = uid('student');
  const sessionId = uid('session');
  await seedUser(staff, ROLES.sportsStaff);
  await db.collection('students').doc(student).set({
    name: 'Student',
    registerNumber: 'R-3',
    department: 'Sports',
    status: 'Active',
  });
  await seedSession(sessionId, staff, 'scheduled');
  await rejectedWithCode(
    attendanceBackend.markAttendance(
      request(staff, { sessionId, studentId: student, status: 'Present' }),
    ),
    'failed-precondition',
  );
  const records = await db
    .collection('attendance')
    .where('sessionId', '==', sessionId)
    .get();
  assert.equal(records.size, 0);
});

runTest('concurrent duplicate marks create one record and corrections are atomic', async () => {
  const staff = uid('staff');
  const student = uid('student');
  const sessionId = uid('session');
  await seedUser(staff, ROLES.sportsStaff);
  await db.collection('students').doc(student).set({
    name: 'Student',
    registerNumber: 'R-2',
    department: 'Sports',
    status: 'Active',
  });
  await seedSession(sessionId, staff, 'active');
  const mark = () =>
    attendanceBackend.markAttendance(
      request(staff, { sessionId, studentId: student, status: 'Present' }),
    );
  const [first, second] = await Promise.all([mark(), mark()]);
  assert.equal(first.attendanceId, second.attendanceId);
  const records = await db
    .collection('attendance')
    .where('sessionId', '==', sessionId)
    .get();
  assert.equal(records.size, 1);

  await rejectedWithCode(
    attendanceBackend.markAttendance(
      request(staff, { sessionId, studentId: student, status: 'Absent' }),
    ),
    'invalid-argument',
  );
  const corrected = await attendanceBackend.markAttendance(
    request(staff, {
      sessionId,
      studentId: student,
      status: 'Absent',
      correctionReason: 'Roster signed by coach',
    }),
  );
  assert.equal(corrected.changed, true);
  const audit = await db
    .collection('attendance_audit')
    .where('sessionId', '==', sessionId)
    .get();
  assert.equal(audit.size, 1);
  assert.equal(audit.docs[0].data().studentId, student);
  assert.equal(audit.docs[0].data().previousStatus, 'Present');
  assert.equal(audit.docs[0].data().newStatus, 'Absent');
  assert.equal(audit.docs[0].data().correctionReason, 'Roster signed by coach');
});

runTest('student history is derived from caller UID, not requested student ID', async () => {
  const student = uid('student');
  const otherStudent = uid('other');
  await seedUser(student, ROLES.student);
  await db.collection('users').doc(otherStudent).set({
    role: ROLES.student,
    status: 'active',
  });
  await db.collection('attendance').doc(uid('record')).set({
    studentId: student,
    status: 'Present',
    sport: 'Football',
    date: new Date(),
  });
  await db.collection('attendance').doc(uid('record')).set({
    studentId: otherStudent,
    status: 'Absent',
    sport: 'Basketball',
    date: new Date(),
  });
  const result = await attendanceBackend.getOwnHistory(
    request(student, { studentId: otherStudent }),
  );
  assert.equal(result.records.length, 1);
  assert.equal(result.records[0].sport, 'Football');
});

runTest('account access endpoint denies self changes and preserves an active Admin', async () => {
  const admin = uid('admin');
  const secondAdmin = uid('admin');
  const manager = uid('manager');
  await seedUser(admin, ROLES.admin);
  await seedUser(secondAdmin, ROLES.admin);
  await seedUser(manager, ROLES.manager);
  await db.collection('system_counters').doc('active_admins').set({ count: 99 });
  await rejectedWithCode(
    accountBackend.setUserAccess(
      request(admin, { targetUid: admin, status: 'inactive' }),
    ),
    'permission-denied',
  );
  const result = await accountBackend.setUserAccess(
    request(admin, { targetUid: secondAdmin, status: 'inactive' }),
  );
  assert.equal(result.authSynchronized, true);
  await rejectedWithCode(
    accountBackend.setUserAccess(
      request(admin, { targetUid: secondAdmin, role: ROLES.admin }),
    ),
    'invalid-argument',
  );
  await accountBackend.setUserAccess(
    request(admin, { targetUid: manager, role: ROLES.student }),
  );
  const changedManager = await db.collection('users').doc(manager).get();
  assert.equal(changedManager.data().role, ROLES.student);
  const counter = await db.collection('system_counters').doc('active_admins').get();
  assert.equal(counter.data().count, 1);
  await db.collection('users').doc(admin).update({
    role: ROLES.student,
    status: 'inactive',
  });
});

runTest('concurrent attempts cannot remove the last two active Admins', async () => {
  const firstAdmin = uid('admin');
  const secondAdmin = uid('admin');
  await seedUser(firstAdmin, ROLES.admin);
  await seedUser(secondAdmin, ROLES.admin);
  const results = await Promise.allSettled([
    accountBackend.setUserAccess(
      request(firstAdmin, { targetUid: secondAdmin, status: 'inactive' }),
    ),
    accountBackend.setUserAccess(
      request(secondAdmin, { targetUid: firstAdmin, status: 'inactive' }),
    ),
  ]);
  assert.equal(results.filter((result) => result.status === 'fulfilled').length, 1);
  assert.equal(results.filter((result) => result.status === 'rejected').length, 1);
  const admins = await db
    .collection('users')
    .where('role', '==', ROLES.admin)
    .get();
  assert.equal(
    admins.docs.filter((document) => document.data().status === 'active').length,
    1,
  );
  await Promise.all([
    db.collection('users').doc(firstAdmin).update({
      role: ROLES.student,
      status: 'inactive',
    }),
    db.collection('users').doc(secondAdmin).update({
      role: ROLES.student,
      status: 'inactive',
    }),
  ]);
});
