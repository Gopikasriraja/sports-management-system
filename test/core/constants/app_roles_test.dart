import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/core/constants/app_roles.dart';

void main() {
  group('AppRoles', () {
    test('keeps the existing role names and defines Manager separately', () {
      expect(AppRoles.admin, 'Admin');
      expect(AppRoles.manager, 'Manager');
      expect(AppRoles.sportsStaff, 'Sports Staff');
      expect(AppRoles.student, 'Student');
    });

    test('grants the approved Manager operational capabilities', () {
      expect(AppRoles.canAccessOperationsPortal(AppRoles.manager), isTrue);
      expect(AppRoles.canManageStudents(AppRoles.manager), isTrue);
      expect(AppRoles.canManageAttendance(AppRoles.manager), isTrue);
      expect(AppRoles.canManageEvents(AppRoles.manager), isTrue);
      expect(AppRoles.canManageGallery(AppRoles.manager), isTrue);
      expect(AppRoles.canManageEquipmentInventory(AppRoles.manager), isTrue);
      expect(AppRoles.canViewReports(AppRoles.manager), isTrue);
      expect(AppRoles.canManageReports(AppRoles.manager), isFalse);
      expect(AppRoles.canManageAnnouncements(AppRoles.manager), isTrue);
    });

    test('keeps privileged user and settings management Admin-only', () {
      for (final role in [
        AppRoles.manager,
        AppRoles.sportsStaff,
        AppRoles.student,
      ]) {
        expect(AppRoles.canManageUsers(role), isFalse);
        expect(AppRoles.canManageSystemSettings(role), isFalse);
      }
      expect(AppRoles.canManageUsers(AppRoles.admin), isTrue);
      expect(AppRoles.canManageSystemSettings(AppRoles.admin), isTrue);
      expect(AppRoles.canManageReports(AppRoles.admin), isTrue);
    });

    test('limits Sports Staff to operational sections', () {
      expect(AppRoles.canAccessOperationsPortal(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageAttendance(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageEvents(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageGallery(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageEquipmentLoans(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageStudents(AppRoles.sportsStaff), isFalse);
      expect(
        AppRoles.canManageEquipmentInventory(AppRoles.sportsStaff),
        isFalse,
      );
      expect(AppRoles.canViewReports(AppRoles.sportsStaff), isFalse);
      expect(AppRoles.canManageAnnouncements(AppRoles.sportsStaff), isFalse);
      expect(AppRoles.canManageTeams(AppRoles.sportsStaff), isTrue);
      expect(AppRoles.canManageStudents(AppRoles.sportsStaff), isFalse);
    });

    test('allows only authorized roles to manage teams and create accounts', () {
      expect(AppRoles.canViewTeams(AppRoles.student), isTrue);
      expect(AppRoles.canManageTeams(AppRoles.student), isFalse);
      expect(AppRoles.canManageTeams(AppRoles.manager), isTrue);
      expect(AppRoles.canManageTeams(AppRoles.admin), isTrue);

      expect(
        AppRoles.canCreateUserWithRole(AppRoles.manager, AppRoles.student),
        isTrue,
      );
      expect(
        AppRoles.canCreateUserWithRole(AppRoles.manager, AppRoles.admin),
        isFalse,
      );
      expect(
        AppRoles.canCreateUserWithRole(
          AppRoles.sportsStaff,
          AppRoles.student,
        ),
        isFalse,
      );
      expect(
        AppRoles.canCreateUserWithRole(AppRoles.student, AppRoles.admin),
        isFalse,
      );
    });

    test('only allows removing an active admin when another remains', () {
      expect(AppRoles.canRemoveActiveAdministrator(0), isFalse);
      expect(AppRoles.canRemoveActiveAdministrator(1), isFalse);
      expect(AppRoles.canRemoveActiveAdministrator(2), isTrue);
    });

    test('enforces section access for Manager, Sports Staff, and Student', () {
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.manager, 'Student Management'),
        isTrue,
      );
      expect(AppRoles.canOpenOperationsTab(AppRoles.manager, 'Reports'), isTrue);
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.manager, 'Notifications'),
        isTrue,
      );
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.manager, 'User Management'),
        isFalse,
      );
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.manager, 'Settings'),
        isFalse,
      );

      expect(
        AppRoles.canOpenOperationsTab(
          AppRoles.sportsStaff,
          'Attendance Management',
        ),
        isTrue,
      );
      expect(
        AppRoles.canOpenOperationsTab(
          AppRoles.sportsStaff,
          'Student Management',
        ),
        isFalse,
      );
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.sportsStaff, 'Reports'),
        isFalse,
      );
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.sportsStaff, 'Notifications'),
        isFalse,
      );
      expect(
        AppRoles.canOpenOperationsTab(AppRoles.student, 'Dashboard'),
        isFalse,
      );
    });

    test(
      'does not grant admin portal sections to Students or unknown roles',
      () {
        for (final role in [AppRoles.student, 'Unknown']) {
          expect(AppRoles.canAccessOperationsPortal(role), isFalse);
          expect(
            AppRoles.canOpenOperationsTab(role, 'Attendance Management'),
            isFalse,
          );
          expect(
            AppRoles.canOpenOperationsTab(role, 'User Management'),
            isFalse,
          );
        }
      },
    );
  });
}
