import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/user_models.dart';
import '../repositories/restaurant_repository.dart';
import 'auth_controller.dart';

class TeamController extends ChangeNotifier {
  TeamController(this.ref);

  final Ref ref;

  bool loading = false;
  String? error;
  List<ApiRestaurantUser> users = [];

  Future<void> refresh() async {
    final auth = ref.read(authControllerProvider);
    final restaurantId = auth.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return;
    loading = true;
    error = null;
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

  Future<bool> invite(String name, String email, String role) async {
    final auth = ref.read(authControllerProvider);
    final restaurantId = auth.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await ref.read(restaurantRepositoryProvider).inviteRestaurantUser(restaurantId, {
        'name': name,
        'email': email,
        'role': role,
      });
      await refresh();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

final teamControllerProvider = ChangeNotifierProvider<TeamController>((ref) => TeamController(ref));
