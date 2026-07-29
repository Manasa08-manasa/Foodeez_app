import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez_partner/core/constants/app_constants.dart';

void main() {
  test('owner and admin can assign owner, manager, staff and sales roles', () {
    final options = AppConstants.inviteRolesForInviter(AppConstants.roleRestaurantOwner);

    expect(
      options.map((option) => option.value).toList(),
      [
        AppConstants.roleRestaurantOwner,
        AppConstants.roleRestaurantManager,
        AppConstants.roleRestaurantStaff,
        AppConstants.roleSalesOperator,
      ],
    );
  });

  test('manager can only assign manager and staff roles', () {
    final options = AppConstants.inviteRolesForInviter(AppConstants.roleRestaurantManager);

    expect(
      options.map((option) => option.value).toList(),
      [
        AppConstants.roleRestaurantManager,
        AppConstants.roleRestaurantStaff,
      ],
    );
  });

  test('sales operator can see all assignable roles', () {
    final options = AppConstants.inviteRolesForInviter(AppConstants.roleSalesOperator);

    expect(
      options.map((option) => option.value).toList(),
      [
        AppConstants.roleRestaurantOwner,
        AppConstants.roleRestaurantManager,
        AppConstants.roleRestaurantStaff,
        AppConstants.roleSalesOperator,
      ],
    );
  });
}
