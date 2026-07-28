import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/menu_controller.dart';
import '../controllers/navigation_controller.dart';
import '../models/api/menu_models.dart';
import '../models/models.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final nav = ref.read(navigationControllerProvider);
    final sections = menu.menuSections;
    final branch = auth.activeBranch;
    final branchLabel = branch != null && branch.name.isNotEmpty ? branch.name : 'Selected branch';
    const dietChips = [('all', 'All'), ('veg', '🌿 Veg'), ('nonveg', '🔺 Non-veg'), ('in', 'In stock'), ('out', 'Sold out')];
    final bottomPad = AppResponsive.of(context).dockClearance(showDock: true);

    if (auth.branchId == null || auth.branchId!.isEmpty) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Branch menu', onBack: () => nav.toBranches()),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Select a branch first', style: AppText.body(size: 15, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        'Open Branches, choose an outlet, then tap Manage menu to create categories and items for that branch.',
                        textAlign: TextAlign.center,
                        style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => nav.toBranches(),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                        child: Text('Go to branches', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Branch menu',
            onBack: () => nav.toBranches(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branchLabel, style: AppText.body(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  menu.loading
                      ? 'Loading menu for this branch...'
                      : '${menu.menuAvailableCount} items available · ${menu.categories.length} categories',
                  style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
              children: [
                const _CreateCategoryCard(),
                const SizedBox(height: 12),
                const _CreateItemCard(),
                const SizedBox(height: 16),
                Text('Menu overview', style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['all', ...menu.sectionOrder]
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FzChip(label: c == 'all' ? 'All' : c, selected: menu.menuCat == c, onTap: () => menu.setMenuCat(c)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: dietChips
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FzChip(label: c.$2, selected: menu.menuDiet == c.$1, onTap: () => menu.setMenuDiet(c.$1)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (menu.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  )
                else if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Text('No items yet', style: AppText.body(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            menu.categories.isEmpty
                                ? 'Create a category above, then add items for this branch.'
                                : 'Try a different filter or add an item above.',
                            style: AppText.body(size: 12, color: AppColors.bodyGrey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...sections.map((sec) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 10),
                              child: Text(sec.name, style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.5)),
                            ),
                            ...sec.items.map((m) => _MenuItemCard(item: m)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCategoryCard extends ConsumerStatefulWidget {
  const _CreateCategoryCard();

  @override
  ConsumerState<_CreateCategoryCard> createState() => _CreateCategoryCardState();
}

class _CreateCategoryCardState extends ConsumerState<_CreateCategoryCard> {
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final displayName = _displayNameController.text.trim();
    if (name.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both internal name and display name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(menuControllerProvider).createCategory(name, displayName);
      _nameController.clear();
      _displayNameController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create category', style: AppText.body(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Adds a category to the active branch menu.', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
          const SizedBox(height: 12),
          FzTextField(label: 'Internal name', controller: _nameController),
          const SizedBox(height: 10),
          FzTextField(label: 'Display name', controller: _displayNameController),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _saving ? 'Adding...' : 'Add category',
              style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateItemCard extends ConsumerStatefulWidget {
  const _CreateItemCard();

  @override
  ConsumerState<_CreateItemCard> createState() => _CreateItemCardState();
}

class _CreateItemCardState extends ConsumerState<_CreateItemCard> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR');
  final _discountValueController = TextEditingController();
  final _discountTitleController = TextEditingController();
  final _discountStartsAtController = TextEditingController();
  final _discountEndsAtController = TextEditingController();
  String? _selectedCategoryId;
  bool _isVisible = true;
  bool _isInStock = true;
  bool _discountEnabled = false;
  bool _saving = false;
  String _discountValueType = 'PERCENTAGE';

  @override
  void initState() {
    super.initState();
    _syncSelectedCategory(ref.read(menuControllerProvider).categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _discountValueController.dispose();
    _discountTitleController.dispose();
    _discountStartsAtController.dispose();
    _discountEndsAtController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CreateItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedCategory(ref.read(menuControllerProvider).categories);
  }

  void _syncSelectedCategory(List<ApiMenuCategory> categories) {
    if (categories.isEmpty) {
      _selectedCategoryId = null;
      return;
    }
    if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuControllerProvider);
    final categories = menu.categories;
    _syncSelectedCategory(categories);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create item', style: AppText.body(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Adds an item under the selected branch category.', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Text('Create a category first, then you can add items here.', style: AppText.body(size: 12.5, color: AppColors.bodyGrey))
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.accent)),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.displayName.isNotEmpty ? c.displayName : c.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
            const SizedBox(height: 10),
            FzTextField(label: 'Name', controller: _nameController),
            const SizedBox(height: 10),
            FzTextField(label: 'Description', controller: _descriptionController),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: FzTextField(label: 'Price', controller: _priceController, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                SizedBox(width: 96, child: FzTextField(label: 'Currency', controller: _currencyController)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 8,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(value: _isVisible, onChanged: (v) => setState(() => _isVisible = v ?? true)),
                    Text('Visible', style: AppText.body(size: 12.5)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(value: _isInStock, onChanged: (v) => setState(() => _isInStock = v ?? true)),
                    Text('In stock', style: AppText.body(size: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _discountEnabled = !_discountEnabled),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_discountEnabled ? 'Remove discount' : 'Add discount', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
            ),
            if (_discountEnabled) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _discountValueType,
                decoration: InputDecoration(
                  labelText: 'Discount type',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.accent)),
                ),
                items: const [
                  DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
                  DropdownMenuItem(value: 'FLAT', child: Text('Flat amount')),
                ],
                onChanged: (value) => setState(() => _discountValueType = value ?? 'PERCENTAGE'),
              ),
              const SizedBox(height: 10),
              FzTextField(label: 'Discount amount', controller: _discountValueController, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              FzTextField(label: 'Title', controller: _discountTitleController),
              const SizedBox(height: 10),
              FzTextField(label: 'Valid from (YYYY-MM-DD)', controller: _discountStartsAtController),
              const SizedBox(height: 10),
              FzTextField(label: 'Valid until (YYYY-MM-DD)', controller: _discountEndsAtController),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : () => _submit(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _saving ? 'Adding...' : 'Add item',
                style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first.')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an item name.')));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price greater than 0.')));
      return;
    }
    if (_discountEnabled) {
      final discountValue = double.tryParse(_discountValueController.text.trim()) ?? 0;
      if (discountValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid discount amount.')));
        return;
      }
    }

    final currency = _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim().toUpperCase() : 'INR';
    final description = _descriptionController.text.trim();
    final discount = _discountEnabled
        ? {
            'valueType': _discountValueType,
            'value': double.tryParse(_discountValueController.text.trim()) ?? 0,
            'title': _discountTitleController.text.trim().isNotEmpty ? _discountTitleController.text.trim() : null,
            'startsAt': _discountStartsAtController.text.trim().isNotEmpty ? _discountStartsAtController.text.trim() : null,
            'endsAt': _discountEndsAtController.text.trim().isNotEmpty ? _discountEndsAtController.text.trim() : null,
          }
        : null;

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmCreateItemDialog(
      context,
      ref,
      name: name,
      categoryId: _selectedCategoryId!,
      price: price,
      currency: currency,
      description: description,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(menuControllerProvider).createMenuItem(
            name: name,
            categoryId: _selectedCategoryId!,
            price: price,
            description: description,
            currency: currency,
            isVisible: _isVisible,
            isInStock: _isInStock,
            discount: discount,
          );
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _currencyController.text = 'INR';
      _discountValueController.clear();
      _discountTitleController.clear();
      _discountStartsAtController.clear();
      _discountEndsAtController.clear();
      setState(() {
        _discountEnabled = false;
        _isVisible = true;
        _isInStock = true;
      });
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Item created')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<bool?> _confirmCreateItemDialog(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required String categoryId,
  required double price,
  required String currency,
  required String description,
}) {
  final auth = ref.read(authControllerProvider);
  final categories = ref.read(menuControllerProvider).categories;
  String categoryName = 'Selected category';
  for (final category in categories) {
    if (category.id == categoryId) {
      categoryName = category.displayName.isNotEmpty ? category.displayName : category.name;
      break;
    }
  }

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirm item creation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You are about to add a new menu item to this branch.'),
          const SizedBox(height: 12),
          Text('Branch: ${auth.activeBranch?.name ?? 'Selected branch'}'),
          Text('Category: $categoryName'),
          Text('Item: $name'),
          Text('Price: $currency ${price.toStringAsFixed(2)}'),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Description: ${description.trim()}'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Create item'),
        ),
      ],
    ),
  );
}

class _MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuControllerProvider);
    final avail = menu.isAvail(item);
    return Opacity(
      opacity: avail ? 1 : 0.62,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: FoodImage(photoKey: item.photoKey, imageUrl: item.imageUrl, width: 58, height: 58)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(border: Border.all(color: item.veg ? AppColors.vegDot : AppColors.nonVegDot, width: 2), borderRadius: BorderRadius.circular(3)),
                        alignment: Alignment.center,
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: item.veg ? AppColors.vegDot : AppColors.nonVegDot)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 14, weight: FontWeight.w700))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('${item.soldThisWeek} sold this week', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InlineStepper(
                      valueStr: '₹${menu.priceOf(item)}',
                      onDec: () => menu.changePrice(item.id, -10),
                      onInc: () => menu.changePrice(item.id, 10),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ToggleSwitch(on: avail, onTap: () => menu.toggleAvail(item.id)),
                Text(avail ? 'In stock' : 'Sold out', style: AppText.body(size: 11, weight: FontWeight.w700, color: avail ? AppColors.green : AppColors.nonVegDot)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
