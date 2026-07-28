import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/api/user_models.dart';
import '../repositories/restaurant_repository.dart';
import 'auth_controller.dart';

class TeamController extends ChangeNotifier {
  TeamController(this.ref);

  final Ref ref;

  bool loading = false;
  String? error;
  String? successMessage;
  List<ApiRestaurantUser> users = [];

  List<RestaurantInviteRole> get inviteRoleOptions {
    final inviterRole = ref.read(authControllerProvider).user?.role;
    return AppConstants.inviteRolesForInviter(inviterRole);
  }

  String get defaultInviteRole {
    final options = inviteRoleOptions;
    if (options.any((option) => option.value == AppConstants.defaultInviteRole)) {
      return AppConstants.defaultInviteRole;
    }
    return options.isNotEmpty ? options.first.value : AppConstants.defaultInviteRole;
  }

  Future<void> refresh() async {
    final auth = ref.read(authControllerProvider);
    final restaurantId = auth.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return;
    loading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      users = await ref.read(restaurantRepositoryProvider).getRestaurantUsers(restaurantId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> invite(String displayName, String email, String role) async {
    final auth = ref.read(authControllerProvider);
    final restaurantId = auth.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return false;
    loading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      await ref.read(restaurantRepositoryProvider).inviteRestaurantUser(restaurantId, {
        'displayName': displayName.trim(),
        'email': email.trim(),
        'role': role,
      });
      successMessage = 'User invited successfully. Credentials will be sent.';
      await refresh();
      return true;
    } catch (e) {
      error = 'Unable to invite user. Check the email and role.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

final teamControllerProvider = ChangeNotifierProvider<TeamController>((ref) => TeamController(ref));
