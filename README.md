# sports_management_system

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Training schedule

Admins, managers, and sports staff can create, update, and delete training
sessions from the operations portal. Students can view the schedule from their
portal. Sessions are stored in Firestore's `training_sessions` collection and
include the sport, optional team, coach, venue, start and end times, notes, and
status.

Before deploying this feature, ensure the active Firestore rules authorize
schedule reads for students and operations roles and restrict writes to
authorized operations roles. The `firestore.rules.proposed` file is not active
and does not yet define rules for this collection.
