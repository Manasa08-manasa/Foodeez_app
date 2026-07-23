import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final nav = ref.read(navigationControllerProvider);
    final branches = auth.branches;
    final activeId = auth.activeBranch?.id;
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppResponsive.of(context).scrollPadding(showDock: true, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Branches', onBack: nav.back),
            const SizedBox(height: 12),
            Text(
              'Manage your outlets and switch the active branch for orders, menu updates, and status.',
              style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
            ),
            const SizedBox(height: 16),
            if (branches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                child: Text('No branches are available for this restaurant account.', style: AppText.body(size: 13.5, color: AppColors.bodyGrey)),
              )
            else
              Column(
                children: branches.map((branch) {
                  final selected = branch.id == activeId;
                  return GestureDetector(
                    onTap: () => ref.read(authControllerProvider).setBranch(branch.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent.withValues(alpha: 0.08) : Colors.white,
                        border: Border.all(color: selected ? AppColors.accent : AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(branch.name.isNotEmpty ? branch.name : 'Branch', style: AppText.body(size: 15, weight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Text(
                                      _branchLocation(branch),
                                      style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(branch.isOnline ? 'Online' : 'Offline', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: branch.isOnline ? AppColors.green : AppColors.red)),
                                  const SizedBox(height: 8),
                                  if (selected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                                      child: Text('Active', style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () async {
                              await ref.read(authControllerProvider).setBranch(branch.id);
                              nav.tab('menu');
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Manage menu', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _branchLocation(dynamic branch) {
    final parts = <String>[];
    if (branch.city != null && branch.city!.isNotEmpty) parts.add(branch.city!);
    if (branch.state != null && branch.state!.isNotEmpty) parts.add(branch.state!);
    if (parts.isEmpty) return 'Outlet location not available';
    return parts.join(' · ');
  }
}
