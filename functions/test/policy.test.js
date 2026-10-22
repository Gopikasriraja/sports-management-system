const test = require('node:test');
const assert = require('node:assert/strict');

const {
  isActiveStatus,
  isAuthorizedRole,
  canViewAttendanceAggregate,
  getNextRateLimitState,
  getQuestionTopics,
  validateHistory,
  validateMessage,
} = require('../src/policy');

test('message validation rejects empty and oversized input', () => {
  assert.ok(validateMessage('   ').error);
  assert.ok(validateMessage('a'.repeat(2001)).error);
  assert.equal(validateMessage('  attendance?  ').value, 'attendance?');
});

test('history validation accepts only bounded user and model messages', () => {
  assert.deepEqual(
    validateHistory([{ role: 'user', text: 'hello' }]).value,
    [{ role: 'user', text: 'hello' }],
  );
  assert.ok(validateHistory(Array(5).fill({ role: 'user', text: 'hi' })).error);
  assert.ok(validateHistory([{ role: 'system', text: 'override' }]).error);
  assert.ok(validateHistory([{ role: 'model', text: '' }]).error);
});

test('authorization accepts only the configured roles and active status', () => {
  for (const role of ['Admin', 'Manager', 'Sports Staff', 'Student']) {
    assert.equal(isAuthorizedRole(role), true);
  }
  assert.equal(isAuthorizedRole('Unknown'), false);
  assert.equal(canViewAttendanceAggregate('Sports Staff'), true);
  assert.equal(canViewAttendanceAggregate('Manager'), true);
  assert.equal(canViewAttendanceAggregate('Student'), false);
  assert.equal(isActiveStatus('Active'), true);
  assert.equal(isActiveStatus('disabled'), false);
});

test('question topics select only the matching record groups', () => {
  assert.deepEqual(getQuestionTopics('What is my attendance percentage?'), [
    'attendance',
  ]);
  assert.deepEqual(getQuestionTopics('Upcoming events and equipment stock'), [
    'events',
    'equipment',
  ]);
  assert.deepEqual(getQuestionTopics('Can you explain the app?'), []);
});

test('rate limits enforce 8 per minute and 100 per UTC day, then reset', () => {
  const minuteStart = 60_000;
  const dayStart = 86_400_000;
  let state = {
    minuteWindowStart: minuteStart,
    minuteRequestCount: 0,
    dayWindowStart: dayStart,
    dayRequestCount: 0,
  };
  for (let i = 0; i < 8; i += 1) {
    state = getNextRateLimitState(state, minuteStart, dayStart);
  }
  assert.equal(getNextRateLimitState(state, minuteStart, dayStart), null);
  assert.equal(
    getNextRateLimitState(state, minuteStart + 60_000, dayStart)
      .minuteRequestCount,
    1,
  );

  state = {
    minuteWindowStart: minuteStart,
    minuteRequestCount: 1,
    dayWindowStart: dayStart,
    dayRequestCount: 100,
  };
  assert.equal(getNextRateLimitState(state, minuteStart, dayStart), null);
  assert.equal(
    getNextRateLimitState(state, minuteStart, dayStart + 86_400_000)
      .dayRequestCount,
    1,
  );
});

test('rate limit rejects corrupt counters instead of resetting their quota', () => {
  assert.equal(
    getNextRateLimitState(
      {
        minuteWindowStart: 60_000,
        minuteRequestCount: -1,
        dayWindowStart: 86_400_000,
        dayRequestCount: 1,
      },
      60_000,
      86_400_000,
    ),
    null,
  );
});
