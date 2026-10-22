import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const projectId = 'demo-mrcas-security-tests';
let testEnv;

before(async () => {
  const rules = await readFile(
    new URL('../firestore.rules.proposed', import.meta.url),
    'utf8',
  );
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] || '127.0.0.1',
      port: Number(process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] || 8080),
      rules,
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const fixtures = [
      ['users/admin-a', user('Admin', 'active')],
      ['users/admin-b', user('Admin', 'active')],
      ['users/manager-a', user('Manager', 'active')],
      ['users/staff-a', user('Sports Staff', 'active')],
      ['users/staff-b', user('Sports Staff', 'active')],
      ['users/student-a', user('Student', 'active', 'r-a', 'a@example.test')],
      ['users/student-b', user('Student', 'active', 'r-b', 'b@example.test')],
      ['users/inactive-staff', user('Sports Staff', 'inactive')],
      ['students/student-a', student('r-a', 'a@example.test')],
      ['students/student-b', student('r-b', 'b@example.test')],
      ['sports_teams/team-a', { name: 'Team A', sport: 'Football', status: 'active' }],
      ['attendance_sessions/session-a', session('staff-a', 'active', 'team-a')],
      ['attendance_sessions/session-b', session('staff-b', 'active', '')],
      ['attendance_sessions/session-scheduled', session('staff-a', 'scheduled', '')],
      ['team_memberships/team-a--student-a', {
        teamId: 'team-a',
        studentId: 'student-a',
      }],
      ['attendance/record-a', {
        sessionId: 'session-a',
        studentId: 'student-a',
        status: 'Present',
      }],
      ['attendance/record-b', {
        sessionId: 'session-b',
        studentId: 'student-b',
        status: 'Absent',
      }],
    ];
    for (const [path, data] of fixtures) {
      await setDoc(doc(db, path), data);
    }
  });
});

after(async () => {
  await testEnv?.cleanup();
});

function user(role, status, registerNumberNormalized = '', email = '') {
  return { role, status, registerNumberNormalized, email };
}

function student(registerNumberNormalized, email) {
  return {
    name: 'Student',
    registerNumber: registerNumberNormalized,
    registerNumberNormalized,
    email,
    department: 'Sports',
    status: 'Active',
  };
}

function session(responsibleUid, status, teamId) {
  return {
    title: 'Training',
    sport: 'Football',
    teamId,
    teamName: teamId ? 'Team A' : '',
    venue: 'Ground',
    date: new Date('2026-10-22T09:00:00Z'),
    startTime: '09:00',
    endTime: '10:00',
    status,
    responsibleUid,
    responsibleName: responsibleUid,
    createdAt: new Date('2026-10-01T00:00:00Z'),
    updatedAt: new Date('2026-10-01T00:00:00Z'),
  };
}

function dbAs(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

test('active Admin and Manager can read operational sessions', async () => {
  for (const uid of ['admin-a', 'manager-a']) {
    await assertSucceeds(getDocs(collection(dbAs(uid), 'attendance_sessions')));
  }
});

test('Sports Staff can read only assigned sessions and must scope list queries', async () => {
  const db = dbAs('staff-a');
  await assertSucceeds(getDoc(doc(db, 'attendance_sessions/session-a')));
  await assertFails(getDoc(doc(db, 'attendance_sessions/session-b')));
  await assertSucceeds(
    getDocs(
      query(
        collection(db, 'attendance_sessions'),
        where('responsibleUid', '==', 'staff-a'),
      ),
    ),
  );
  await assertFails(getDocs(collection(db, 'attendance_sessions')));
});

test('Students and inactive users cannot read operational sessions', async () => {
  await assertFails(getDoc(doc(dbAs('student-a'), 'attendance_sessions/session-a')));
  await assertFails(
    getDoc(doc(dbAs('inactive-staff'), 'attendance_sessions/session-a')),
  );
});

test('Active Students can read active team metadata but not mutate teams', async () => {
  const db = dbAs('student-a');
  await assertSucceeds(getDoc(doc(db, 'sports_teams/team-a')));
  await assertFails(updateDoc(doc(db, 'sports_teams/team-a'), {
    status: 'inactive',
  }));
});

test('Private student documents are not directly readable by any client role', async () => {
  await assertFails(getDoc(doc(dbAs('admin-a'), 'students/student-a')));
  await assertFails(getDoc(doc(dbAs('manager-a'), 'students/student-a')));
  await assertFails(getDoc(doc(dbAs('staff-a'), 'students/student-a')));
  await assertFails(getDoc(doc(dbAs('student-a'), 'students/student-a')));
  await assertFails(getDoc(doc(dbAs('student-a'), 'students/student-b')));
});

test('Attendance reads are limited by role, session ownership, or student identity', async () => {
  await assertSucceeds(getDoc(doc(dbAs('admin-a'), 'attendance/record-a')));
  await assertSucceeds(getDoc(doc(dbAs('manager-a'), 'attendance/record-b')));
  await assertSucceeds(getDoc(doc(dbAs('staff-a'), 'attendance/record-a')));
  await assertFails(getDoc(doc(dbAs('staff-a'), 'attendance/record-b')));
  await assertSucceeds(getDoc(doc(dbAs('student-a'), 'attendance/record-a')));
  await assertFails(getDoc(doc(dbAs('student-a'), 'attendance/record-b')));
  await assertSucceeds(
    getDocs(
      query(
        collection(dbAs('student-a'), 'attendance'),
        where('studentId', '==', 'student-a'),
      ),
    ),
  );
});

test('Direct client attendance and audit mutations are denied', async () => {
  for (const uid of ['admin-a', 'manager-a', 'staff-a', 'student-a']) {
    const db = dbAs(uid);
    await assertFails(
      setDoc(doc(db, 'attendance/direct-write'), {
        sessionId: 'session-a',
        studentId: 'student-a',
        status: 'Present',
      }),
    );
    await assertFails(
      setDoc(doc(db, 'attendance_audit/direct-write'), {
        sessionId: 'session-a',
        studentId: 'student-a',
        previousStatus: 'Absent',
        newStatus: 'Present',
        correctionReason: 'Test',
      }),
    );
  }
});

test('Session mutations go through the trusted backend, even for the owner', async () => {
  const db = dbAs('staff-a');
  const ref = doc(db, 'attendance_sessions/session-scheduled');
  await assertFails(updateDoc(ref, {
    status: 'active',
    updatedAt: new Date(),
  }));
  await assertFails(updateDoc(ref, { responsibleUid: 'staff-b' }));
  await assertFails(
    updateDoc(ref, {
      status: 'scheduled',
      updatedAt: new Date(),
    }),
  );
});

test('Users cannot promote themselves or change their own active status', async () => {
  const studentDb = dbAs('student-a');
  await assertFails(updateDoc(doc(studentDb, 'users/student-a'), {
    role: 'Admin',
  }));
  await assertFails(updateDoc(doc(studentDb, 'users/student-a'), {
    status: 'inactive',
  }));
  const adminDb = dbAs('admin-a');
  await assertFails(updateDoc(doc(adminDb, 'users/admin-a'), {
    status: 'inactive',
  }));
  await assertFails(updateDoc(doc(adminDb, 'users/admin-a'), {
    role: 'Student',
  }));
  await assertFails(updateDoc(doc(adminDb, 'users/admin-b'), {
    status: 'inactive',
  }));
});

test('All account creation and role changes go through the trusted backend', async () => {
  await assertFails(setDoc(doc(dbAs('manager-a'), 'users/new-student'), {
    ...user('Student', 'active', 'r-new', 'new@example.test'),
  }));
  await assertFails(setDoc(doc(dbAs('manager-a'), 'users/new-admin'), {
    ...user('Admin', 'active'),
  }));
  await assertFails(setDoc(doc(dbAs('student-a'), 'users/new-user'), {
    ...user('Admin', 'active'),
  }));
});

test('Students can read only their own membership; membership mutations are backend-only', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs('student-a'), 'team_memberships/team-a--student-a'),
  ));
  await assertFails(getDoc(
    doc(dbAs('student-a'), 'team_memberships/team-a--student-b'),
  ));
  await assertFails(getDoc(
    doc(dbAs('staff-a'), 'team_memberships/team-a--student-a'),
  ));
  await assertFails(setDoc(
    doc(dbAs('staff-a'), 'team_memberships/team-a--student-b'),
    { teamId: 'team-a', studentId: 'student-b' },
  ));
  await assertFails(setDoc(
    doc(dbAs('student-a'), 'team_memberships/team-a--student-b'),
    { teamId: 'team-a', studentId: 'student-b' },
  ));
  await assertFails(setDoc(
    doc(dbAs('staff-a'), 'team_memberships/wrong-id'),
    { teamId: 'team-a', studentId: 'student-b' },
  ));
  await assertFails(setDoc(
    doc(dbAs('staff-a'), 'team_memberships/team-a--student-a'),
    { teamId: 'team-a', studentId: 'student-a' },
  ));
});

test('Reservation and active-admin counter collections are inaccessible to clients', async () => {
  const db = dbAs('admin-a');
  for (const path of [
    'student_register_numbers/r-a',
    'sports_team_names/team-a',
    'system_counters/active_admins',
  ]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { ownerId: 'attacker' }));
  }
});

test('No staff roster projection is exposed by the current proposal', async () => {
  await assertFails(
    getDocs(collection(dbAs('staff-a'), 'attendance_sessions/session-a/roster')),
  );
});
