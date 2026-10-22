const ALLOWED_ROLES = new Set(['Admin', 'Manager', 'Sports Staff', 'Student']);
const MAX_MESSAGE_LENGTH = 2000;
const MAX_HISTORY_MESSAGES = 4;

function validateMessage(message) {
  if (typeof message !== 'string' || message.trim().length === 0) {
    return { error: 'Message must not be empty.' };
  }
  if (message.length > MAX_MESSAGE_LENGTH) {
    return { error: 'Message must be no longer than 2000 characters.' };
  }
  return { value: message.trim() };
}

function validateHistory(history) {
  if (history === undefined) return { value: [] };
  if (!Array.isArray(history) || history.length > MAX_HISTORY_MESSAGES) {
    return { error: 'Conversation history is invalid.' };
  }

  const normalized = [];
  for (const entry of history) {
    if (
      entry === null ||
      typeof entry !== 'object' ||
      !['user', 'model'].includes(entry.role) ||
      typeof entry.text !== 'string' ||
      entry.text.trim().length === 0 ||
      entry.text.length > MAX_MESSAGE_LENGTH
    ) {
      return { error: 'Conversation history is invalid.' };
    }
    normalized.push({ role: entry.role, text: entry.text.trim() });
  }
  return { value: normalized };
}

function isAuthorizedRole(role) {
  return ALLOWED_ROLES.has(role);
}

function canViewAttendanceAggregate(role) {
  return role === 'Admin' || role === 'Manager' || role === 'Sports Staff';
}

function isActiveStatus(status) {
  return typeof status === 'string' && status.toLowerCase() === 'active';
}

function getQuestionTopics(message) {
  const text = message.toLowerCase();
  const topics = new Set();
  if (/\b(event|events|calendar|schedule|tournament|team|teams|registration|upcoming)\b/.test(text)) {
    topics.add('events');
  }
  if (/\b(attendance|present|absent|percentage|attendance history)\b/.test(text)) {
    topics.add('attendance');
  }
  if (/\b(achievement|achievements|medal|medals|participat\w*|sports profile|performance)\b/.test(text)) {
    topics.add('achievements');
  }
  if (/\b(equipment|inventory|stock|low-stock|availability|available)\b/.test(text)) {
    topics.add('equipment');
  }
  if (/\b(my issue|my loan|issued|return|returned|equipment issue|equipment loan)\b/.test(text)) {
    topics.add('equipmentIssues');
  }
  return [...topics];
}

function getNextRateLimitState(
  data,
  minuteStart,
  dayStart,
  perMinute = 8,
  perDay = 100,
) {
  const minuteCount = readWindowCount(
    data,
    'minuteWindowStart',
    'minuteRequestCount',
    minuteStart,
  );
  const dayCount = readWindowCount(
    data,
    'dayWindowStart',
    'dayRequestCount',
    dayStart,
  );

  if (
    minuteCount === null ||
    dayCount === null ||
    minuteCount >= perMinute ||
    dayCount >= perDay
  ) {
    return null;
  }
  return {
    minuteWindowStart: minuteStart,
    minuteRequestCount: minuteCount + 1,
    dayWindowStart: dayStart,
    dayRequestCount: dayCount + 1,
  };
}

function readWindowCount(data, startField, countField, expectedStart) {
  if (data[startField] !== expectedStart) return 0;
  const count = data[countField];
  return Number.isSafeInteger(count) && count >= 0 ? count : null;
}

module.exports = {
  getNextRateLimitState,
  getQuestionTopics,
  canViewAttendanceAggregate,
  isActiveStatus,
  isAuthorizedRole,
  validateHistory,
  validateMessage,
};
