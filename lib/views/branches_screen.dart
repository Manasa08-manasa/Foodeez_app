import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/menu_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class _AddBranchSheet extends ConsumerStatefulWidget {
  const _AddBranchSheet();

  @override
  ConsumerState<_AddBranchSheet> createState() => _AddBranchSheetState();
}

class _AddBranchSheetState extends ConsumerState<_AddBranchSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _openingController = TextEditingController(text: '09:00');
  final _closingController = TextEditingController(text: '22:00');
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _openingController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zipCode = _zipController.text.trim();
    final openingTime = _openingController.text.trim();
    final closingTime = _closingController.text.trim();

    if ([name, address, city, state, zipCode, openingTime, closingTime].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required branch fields.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _serverError = null;
    });

    try {
      await ref.read(authControllerProvider).createBranch({
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'latitude': 0,
        'longitude': 0,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'isOnline': false,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch created')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add branch', style: AppText.body(size: 16, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Create a new outlet for this restaurant.',
                        style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(_serverError!, style: AppText.body(size: 12.5, color: AppColors.red)),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branch details', style: AppText.body(size: 11.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.6)),
                  const SizedBox(height: 12),
                  FzTextField(label: 'Branch name', controller: _nameController),
                  const SizedBox(height: 10),
                  FzTextField(label: 'Address', controller: _addressController),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: FzTextField(label: 'City', controller: _cityController)),
                      const SizedBox(width: 10),
                      Expanded(child: FzTextField(label: 'State', controller: _stateController)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FzTextField(label: 'ZIP / PIN', controller: _zipController, keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Operating hours', style: AppText.body(size: 11.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.6)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: FzTextField(label: 'Opening time', controller: _openingController)),
                      const SizedBox(width: 10),
                      Expanded(child: FzTextField(label: 'Closing time', controller: _closingController)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _saving ? 'Creating branch...' : 'Create branch',
                style: AppText.body(size: 13, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            ScreenHeader(
              title: 'Branches',
              onBack: nav.back,
              trailing: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _AddBranchSheet(),
                ),
                child: Text('+ Add branch', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No branches are available for this restaurant account.', style: AppText.body(size: 13.5, color: AppColors.bodyGrey)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _AddBranchSheet(),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Add first branch', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
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
                              await ref.read(authControllerProvider).setBranch(branch.id, force: true);
                              await ref.read(menuControllerProvider).refresh();
                              ref.read(navigationControllerProvider).go('menu');
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
