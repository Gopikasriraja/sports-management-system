import 'dart:convert';

class TeamValidator {
  TeamValidator._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a team name.';
    return null;
  }

  static String? validateSport(String? value) {
    if (value == null || value.trim().isEmpty) return 'Select a sport.';
    return null;
  }

  static bool hasDuplicateMember(
    Iterable<String> currentMemberIds,
    String id,
  ) => currentMemberIds.contains(id);

  static String reservationId(String name, String sport) => base64Url.encode(
    utf8.encode(
      '${name.trim().toLowerCase()}\u0000${sport.trim().toLowerCase()}',
    ),
  );
}
