const STATUSES = Object.freeze(['Present', 'Absent', 'Late', 'Excused']);
const SESSION_STATUSES = Object.freeze([
  'scheduled',
  'active',
  'completed',
  'cancelled',
]);
const SESSION_TRANSITIONS = Object.freeze({
  scheduled: new Set(['scheduled', 'active', 'cancelled']),
  active: new Set(['active', 'completed', 'cancelled']),
  completed: new Set(['completed']),
  cancelled: new Set(['cancelled']),
});

function attendanceId(sessionId, studentId) {
  return Buffer.from(JSON.stringify([sessionId, studentId]))
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function validateAttendanceStatus(status) {
  return STATUSES.includes(status);
}

function validateCorrection({ existing, previousStatus, status, reason }) {
  if (!validateAttendanceStatus(status)) {
    return 'Choose a valid attendance status.';
  }
  if (existing && previousStatus !== status) {
    if (typeof reason !== 'string' || reason.trim().length === 0) {
      return 'A correction reason is required.';
    }
    if (reason.trim().length > 500) {
      return 'The correction reason must be 500 characters or fewer.';
    }
  }
  return null;
}

function validateSessionInput(data, { creating = false } = {}) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { error: 'Session details are required.' };
  }
  const title = typeof data.title === 'string' ? data.title.trim() : '';
  const sport = typeof data.sport === 'string' ? data.sport.trim() : '';
  const venue = typeof data.venue === 'string' ? data.venue.trim() : '';
  const startTime =
    typeof data.startTime === 'string' ? data.startTime.trim() : '';
  const endTime = typeof data.endTime === 'string' ? data.endTime.trim() : '';
  const teamId = typeof data.teamId === 'string' ? data.teamId.trim() : '';
  const dateMillis = data.dateMillis;

  if (!title || title.length > 120) {
    return { error: 'Session title is required and must be at most 120 characters.' };
  }
  if (!sport || sport.length > 100) {
    return { error: 'Sport is required and must be at most 100 characters.' };
  }
  if (!venue || venue.length > 160) {
    return { error: 'Venue is required and must be at most 160 characters.' };
  }
  const timePattern = /^(?:[01]\d|2[0-3]):[0-5]\d$/;
  if (!timePattern.test(startTime) || !timePattern.test(endTime)) {
    return { error: 'Session times must use HH:mm format.' };
  }
  if (startTime >= endTime) {
    return { error: 'Session end time must be after its start time.' };
  }
  if (
    typeof dateMillis !== 'number' ||
    !Number.isFinite(dateMillis) ||
    dateMillis < 0 ||
    dateMillis > 8.64e15
  ) {
    return { error: 'A valid session date is required.' };
  }
  if (teamId.length > 128) {
    return { error: 'The selected team is invalid.' };
  }
  if (creating && data.sessionId) {
    return { error: 'Session IDs are assigned by the server.' };
  }
  return {
    value: {
      title,
      sport,
      venue,
      startTime,
      endTime,
      date: new Date(dateMillis),
      teamId,
    },
  };
}

function validateSessionTransition(previous, next) {
  return Boolean(SESSION_TRANSITIONS[previous]?.has(next));
}

function attendanceSummary(records, sessionStatus) {
  if (sessionStatus === 'cancelled') {
    return {
      present: 0,
      absent: 0,
      late: 0,
      excused: 0,
      denominator: 0,
      percentage: null,
    };
  }
  const counts = {
    present: 0,
    absent: 0,
    late: 0,
    excused: 0,
  };
  for (const record of records) {
    switch (record.status) {
      case 'Present':
        counts.present += 1;
        break;
      case 'Absent':
        counts.absent += 1;
        break;
      case 'Late':
        counts.late += 1;
        break;
      case 'Excused':
        counts.excused += 1;
        break;
      default:
        break;
    }
  }
  const denominator = counts.present + counts.absent + counts.late;
  return {
    ...counts,
    denominator,
    percentage:
      denominator === 0
        ? null
        : ((counts.present + counts.late) * 100) / denominator,
  };
}

module.exports = {
  SESSION_STATUSES,
  STATUSES,
  attendanceId,
  attendanceSummary,
  validateAttendanceStatus,
  validateCorrection,
  validateSessionInput,
  validateSessionTransition,
};
