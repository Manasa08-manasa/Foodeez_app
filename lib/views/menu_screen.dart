import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/menu_controller.dart';
import '../controllers/navigation_controller.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuControllerProvider);
    final sections = menu.menuSections;
    const dietChips = [('all', 'All'), ('veg', '🌿 Veg'), ('nonveg', '🔺 Non-veg'), ('in', 'In stock'), ('out', 'Sold out')];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final nav = ref.read(navigationControllerProvider);
              return ScreenHeader(
                title: 'Menu',
                onBack: nav.back,
                trailing: Text('+ Add item', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('${menu.menuAvailableCount} items available · tap price to edit', style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: dietChips
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FzChip(label: c.$2, selected: menu.menuDiet == c.$1, onTap: () => menu.setMenuDiet(c.$1)),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No items match', style: AppText.body(size: 14, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Try a different filter.', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: sections
                        .map((sec) => Padding(
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
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
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
