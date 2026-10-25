import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/core/validation/training_session_validator.dart';
import 'package:sports_management_system/models/training_session_model.dart';

void main() {
  final validSession = TrainingSession(
    sessionId: '',
    sport: 'Football',
    team: 'Varsity',
    coach: 'Coach Lee',
    venue: 'Main Ground',
    startsAt: DateTime(2026, 10, 24, 9),
    endsAt: DateTime(2026, 10, 24, 10),
    notes: '',
    status: 'Scheduled',
  );

  test('accepts a complete session with a positive duration', () {
    expect(TrainingSessionValidator.validate(validSession), isNull);
  });

  test('requires sport, coach, and venue', () {
    expect(
      TrainingSessionValidator.validate(validSession.copyWith(sport: '  ')),
      'Select a sport.',
    );
    expect(
      TrainingSessionValidator.validate(validSession.copyWith(coach: '  ')),
      'Enter a coach name.',
    );
    expect(
      TrainingSessionValidator.validate(validSession.copyWith(venue: '  ')),
      'Enter a training venue.',
    );
  });

  test('rejects zero-duration and reversed sessions', () {
    expect(
      TrainingSessionValidator.validate(
        validSession.copyWith(endsAt: validSession.startsAt),
      ),
      'The end time must be after the start time.',
    );
    expect(
      TrainingSessionValidator.validate(
        validSession.copyWith(
          endsAt: validSession.startsAt.subtract(const Duration(minutes: 1)),
        ),
      ),
      'The end time must be after the start time.',
    );
  });
}
