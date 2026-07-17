import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/order_view.dart';
import '../controllers/orders_controller.dart';
import '../utils/theme.dart';

class PrepTimePrompt extends ConsumerWidget {
  const PrepTimePrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final order = orders.prepFor != null ? orders.orderById(orders.prepFor!) : null;
    if (order == null) return const SizedBox.shrink();
    final v = OrderView.of(order);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.inputBorder, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 16),
              Text('How long to prepare?', style: AppText.display(size: 19)),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '#${order.id} · ${v.typeLine}\nWe combine this with rider & delivery time for the customer\'s ETA.',
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 12.5, color: AppColors.bodyGrey, height: 1.45),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: AppConstants.prepTimePresets
                      .map(
                        (m) => GestureDetector(
                          onTap: () => orders.setPrepChoice(m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: orders.prepChoice == m ? AppColors.accent : Colors.white,
                              border: Border.all(color: orders.prepChoice == m ? AppColors.accent : AppColors.inputBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${m}m',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: orders.prepChoice == m ? Colors.white : AppColors.bodyGrey,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepBtn('–', () => orders.bumpPrep(-1)),
                    SizedBox(
                      width: 120,
                      child: Column(
                        children: [
                          Text('${orders.prepChoice}', style: AppText.display(size: 40, height: 1)),
                          Text('minutes', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                        ],
                      ),
                    ),
                    _stepBtn('+', () => orders.bumpPrep(1)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: orders.confirmPrep,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text('Accept · start cooking', style: AppText.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
              GestureDetector(
                onTap: orders.cancelPrep,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Cancel', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(String s, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5), borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(s, style: AppText.body(size: 28, weight: FontWeight.w700, color: AppColors.accent)),
        ),
      );
}
