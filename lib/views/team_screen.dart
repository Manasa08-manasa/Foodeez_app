import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/team_controller.dart';
import '../core/constants/app_constants.dart';
import '../models/api/user_models.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final team = ref.read(teamControllerProvider);
      setState(() => _role = team.defaultInviteRole);
      team.refresh();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncRoleWithOptions(TeamController team) {
    final options = team.inviteRoleOptions;
    if (options.isEmpty) {
      _role = null;
      return;
    }
    if (_role == null || !options.any((option) => option.value == _role)) {
      _role = team.defaultInviteRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationControllerProvider);
    final team = ref.watch(teamControllerProvider);
    _syncRoleWithOptions(team);
    final roleOptions = team.inviteRoleOptions;

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppResponsive.of(context).scrollPadding(showDock: true, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Restaurant team', onBack: nav.back),
            const SizedBox(height: 12),
            Text(
              'Add and manage partner users for your restaurant.',
              style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
            ),
            if (team.successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(team.successMessage!, style: AppText.body(size: 12.5, color: AppColors.green)),
              ),
            ],
            if (team.error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(team.error!, style: AppText.body(size: 12.5, color: AppColors.red)),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite a team member', style: AppText.body(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FzTextField(label: 'Name', controller: _nameController),
                  const SizedBox(height: 12),
                  FzTextField(label: 'Email', controller: _emailController),
                  const SizedBox(height: 12),
                  Text('Role', style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surface,
                    ),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_role),
                      initialValue: _role,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      ),
                      items: roleOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label, style: AppText.body(size: 13.5)),
                            ),
                          )
                          .toList(),
                      onChanged: roleOptions.isEmpty
                          ? null
                          : (value) {
                              if (value != null) setState(() => _role = value);
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: team.loading || _role == null
                        ? null
                        : () async {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            if (name.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter name and email.')),
                              );
                              return;
                            }
                            final success = await ref.read(teamControllerProvider).invite(name, email, _role!);
                            if (success) {
                              _nameController.clear();
                              _emailController.clear();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      team.loading ? 'Inviting…' : 'Invite user',
                      style: AppText.body(size: 13.5, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Existing users', style: AppText.body(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (team.loading && team.users.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppColors.accent))
            else if (team.users.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'No users have been invited yet.',
                  style: AppText.body(size: 13.5, color: AppColors.bodyGrey),
                ),
              )
            else
              Column(
                children: team.users.map(_buildUserTile).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ApiRestaurantUser user) {
    final roleLabel = AppConstants.restaurantRoleLabel(user.role);
    final displayName = user.name.isNotEmpty ? user.name : user.email;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.maroonTint,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppText.body(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.email, style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
                const SizedBox(height: 4),
                Text(roleLabel, style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
              ],
            ),
          ),
          if (user.status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.status.replaceFirstMapped(RegExp(r'^(.)'), (m) => m[0]!.toUpperCase()),
                style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
