import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/orders_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';

class DockNav extends ConsumerWidget {
  const DockNav({super.key});

  static const _tabs = [
    ('dashboard', 'Home', Icons.home_outlined),
    ('orders', 'Orders', Icons.receipt_long_outlined),
    ('menu', 'Menu', Icons.restaurant_menu_outlined),
    ('insights', 'Insights', Icons.bar_chart_outlined),
    ('settings', 'More', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final compact = AppResponsive.of(context).isCompact;
    final hPad = compact ? 6.0 : 15.0;
    final iconSize = compact ? 21.0 : 23.0;
    final labelSize = compact ? 9.0 : 10.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9, horizontal: hPad),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            boxShadow: [BoxShadow(color: AppColors.accentDeep.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Row(
            children: _tabs.map((t) {
              final active = nav.activeTab == t.$1;
              final color = active ? AppColors.accent.withValues(alpha: 0.86) : AppColors.lightGreyText.withValues(alpha: 0.6);
              final badge = t.$1 == 'orders' ? orders.newCount : 0;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => nav.tab(t.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.$3, color: color, size: iconSize),
                            const SizedBox(height: 3),
                            Text(
                              t.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: labelSize,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        if (badge > 0)
                          Positioned(
                            top: -2,
                            right: compact ? 4 : 10,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 17),
                              height: 17,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
