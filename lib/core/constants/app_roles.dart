class AppRoles {
  AppRoles._();

  static const admin = 'Admin';
  static const manager = 'Manager';
  static const sportsStaff = 'Sports Staff';
  static const student = 'Student';

  static bool canAccessOperationsPortal(String? role) =>
      role == manager || role == sportsStaff;

  static bool canManageUsers(String? role) => role == admin;

  static bool canRemoveActiveAdministrator(int activeAdminCount) =>
      activeAdminCount > 1;

  static bool canManageStudents(String? role) =>
      role == admin || role == manager;

  static bool canManageTeams(String? role) =>
      role == admin || role == manager || role == sportsStaff;

  static bool canViewTeams(String? role) =>
      role == student || canManageTeams(role);

  static bool canCreateUserWithRole(String? actorRole, String targetRole) =>
      actorRole == admin ||
      (canManageStudents(actorRole) && targetRole == student);

  static bool canManageAttendance(String? role) =>
      role == admin || role == manager || role == sportsStaff;

  static bool canManageEvents(String? role) =>
      role == admin || role == manager || role == sportsStaff;

  static bool canManageGallery(String? role) =>
      role == admin || role == manager || role == sportsStaff;

  static bool canManageEquipmentInventory(String? role) =>
      role == admin || role == manager;

  static bool canManageEquipmentLoans(String? role) =>
      role == admin || role == manager || role == sportsStaff;

  static bool canViewReports(String? role) =>
      role == admin || role == manager;

  static bool canManageReports(String? role) => role == admin;

  static bool canManageAnnouncements(String? role) =>
      role == admin || role == manager;

  static bool canManageSystemSettings(String? role) => role == admin;

  static bool canOpenOperationsTab(String? role, String tab) {
    return switch (tab) {
      'Dashboard' => role == admin || canAccessOperationsPortal(role),
      'Student Management' => canManageStudents(role),
      'Teams' => canManageTeams(role),
      'Sports Teams' => canViewTeams(role),
      'User Management' => canManageUsers(role),
      'Attendance' || 'Attendance Management' =>
        canManageAttendance(role),
      'Sports Equipment' => canManageEquipmentLoans(role),
      'Achievements' => role == admin || canAccessOperationsPortal(role),
      'Sports Calendar' => canManageEvents(role),
      'Gallery' => canManageGallery(role),
      'Reports' => canViewReports(role),
      'Notifications' => canManageAnnouncements(role),
      'Settings' => canManageSystemSettings(role),
      _ => false,
    };
  }
}
