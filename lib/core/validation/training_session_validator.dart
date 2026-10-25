import '../../models/training_session_model.dart';

class TrainingSessionValidator {
  TrainingSessionValidator._();

  static String? validate(TrainingSession session) {
    if (session.sport.trim().isEmpty) return 'Select a sport.';
    if (session.coach.trim().isEmpty) return 'Enter a coach name.';
    if (session.venue.trim().isEmpty) return 'Enter a training venue.';
    if (!session.endsAt.isAfter(session.startsAt)) {
      return 'The end time must be after the start time.';
    }
    if (!const ['Scheduled', 'Completed', 'Cancelled'].contains(
      session.status,
    )) {
      return 'Choose a valid session status.';
    }
    return null;
  }
}
