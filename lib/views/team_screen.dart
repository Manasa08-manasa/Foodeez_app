import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/team_controller.dart';
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
  String _role = 'restaurant_manager';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamControllerProvider).refresh();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationControllerProvider);
    final team = ref.watch(teamControllerProvider);
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
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
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
                    decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(14), color: AppColors.surface),
                    child: DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                      items: [
                        DropdownMenuItem(value: 'restaurant_manager', child: Text('Manager', style: AppText.body(size: 13.5))),
                        DropdownMenuItem(value: 'restaurant_staff', child: Text('Staff', style: AppText.body(size: 13.5))),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _role = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: team.loading
                        ? null
                        : () async {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            if (name.isEmpty || email.isEmpty) {
                              return;
                            }
                            final success = await ref.read(teamControllerProvider).invite(name, email, _role);
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
                    child: Text(team.loading ? 'Inviting…' : 'Invite user', style: AppText.body(size: 13.5, weight: FontWeight.w700, color: Colors.white)),
                  ),
                  if (team.error != null) ...[
                    const SizedBox(height: 12),
                    Text(team.error!, style: AppText.body(size: 12.5, color: AppColors.red)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Team members', style: AppText.body(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (team.loading)
              const Center(child: CircularProgressIndicator(color: AppColors.accent))
            else if (team.users.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                child: Text('No team members found.', style: AppText.body(size: 13.5, color: AppColors.bodyGrey)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: AppColors.maroonTint, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.accent))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.email, style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
                const SizedBox(height: 4),
                Text(user.role.replaceAll('_', ' ').replaceFirst('restaurant ', '').capitalize(), style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
              ],
            ),
          ),
          if (user.status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(user.status.replaceFirstMapped(RegExp(r'^(.)'), (m) => m[0]!.toUpperCase()), style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : substring(0, 1).toUpperCase() + substring(1);
}
