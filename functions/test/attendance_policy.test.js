const test = require('node:test');
const assert = require('node:assert/strict');

const {
  attendanceId,
  attendanceSummary,
  validateAttendanceStatus,
  validateCorrection,
  validateSessionInput,
  validateSessionTransition,
} = require('../src/attendance_policy');
const { Buffer } = require('node:buffer');

test('stable attendance IDs uniquely encode session and student tuple', () => {
  const id = attendanceId('session/a', 'student-1');
  assert.equal(id, attendanceId('session/a', 'student-1'));
  assert.notEqual(id, attendanceId('session', 'a/student-1'));
  assert.equal(
    id,
    Buffer.from(JSON.stringify(['session/a', 'student-1']))
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_'),
  );
  assert.equal(id.includes('/'), false);
});

test('attendance status and correction reason are validated', () => {
  for (const status of ['Present', 'Absent', 'Late', 'Excused']) {
    assert.equal(validateAttendanceStatus(status), true);
  }
  assert.equal(validateAttendanceStatus('Unknown'), false);
  assert.equal(
    validateCorrection({
      existing: true,
      previousStatus: 'Absent',
      status: 'Present',
      reason: '',
    }),
    'A correction reason is required.',
  );
  assert.equal(
    validateCorrection({
      existing: true,
      previousStatus: 'Absent',
      status: 'Present',
      reason: 'Paper record verified',
    }),
    null,
  );
  assert.equal(
    validateCorrection({
      existing: true,
      previousStatus: 'Present',
      status: 'Present',
      reason: '',
    }),
    null,
  );
});

test('session input rejects client IDs, invalid times, and malformed dates', () => {
  const input = {
    title: 'Training',
    sport: 'Football',
    venue: 'Ground',
    startTime: '09:00',
    endTime: '10:00',
    dateMillis: Date.UTC(2026, 9, 22),
  };
  assert.equal(validateSessionInput(input).error, undefined);
  assert.ok(validateSessionInput({ ...input, endTime: '08:00' }).error);
  assert.ok(validateSessionInput({ ...input, dateMillis: NaN }).error);
  assert.ok(validateSessionInput({ ...input, dateMillis: null }).error);
  assert.ok(validateSessionInput({ ...input, dateMillis: 8.65e15 }).error);
  assert.ok(validateSessionInput({ ...input, sessionId: 'client-id' }, {
    creating: true,
  }).error);
});

test('session transitions reject reopening terminal sessions', () => {
  assert.equal(validateSessionTransition('scheduled', 'active'), true);
  assert.equal(validateSessionTransition('active', 'completed'), true);
  assert.equal(validateSessionTransition('completed', 'active'), false);
  assert.equal(validateSessionTransition('cancelled', 'active'), false);
});

test('summary excludes excused records and cancelled sessions', () => {
  const records = [
    { status: 'Present' },
    { status: 'Late' },
    { status: 'Absent' },
    { status: 'Excused' },
  ];
  assert.deepEqual(attendanceSummary(records, 'active'), {
    present: 1,
    absent: 1,
    late: 1,
    excused: 1,
    denominator: 3,
    percentage: 200 / 3,
  });
  assert.deepEqual(attendanceSummary(records, 'cancelled'), {
    present: 0,
    absent: 0,
    late: 0,
    excused: 0,
    denominator: 0,
    percentage: null,
  });
});
