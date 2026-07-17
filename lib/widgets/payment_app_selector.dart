import 'package:flutter/material.dart';

import '../services/razorpay_checkout_service.dart';
import '../utils/theme.dart';

class PaymentAppSelector extends StatelessWidget {
  const PaymentAppSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.effectivePrice,
  });

  final RegistrationPaymentApp selected;
  final ValueChanged<RegistrationPaymentApp> onChanged;
  final double? effectivePrice;

  static const _icons = {
    RegistrationPaymentApp.phonepe: Icons.account_balance_wallet_outlined,
    RegistrationPaymentApp.gpay: Icons.payments_outlined,
    RegistrationPaymentApp.paytm: Icons.wallet_outlined,
    RegistrationPaymentApp.bhim: Icons.qr_code_2_outlined,
    RegistrationPaymentApp.anyUpi: Icons.apps_outlined,
    RegistrationPaymentApp.razorpay: Icons.credit_card_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose payment app',
            style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep),
          ),
          if (effectivePrice != null) ...[
            const SizedBox(height: 4),
            Text(
              'Registration fee: ₹${effectivePrice!.toStringAsFixed(0)} — opens your selected app to pay',
              style: AppText.body(size: 12, color: AppColors.bodyGrey),
            ),
          ],
          const SizedBox(height: 12),
          ...RegistrationPaymentApp.values.map((app) {
            final active = selected == app;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: active ? AppColors.maroonTint : AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onChanged(app),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? AppColors.accent : AppColors.inputBorder,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent.withValues(alpha: 0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _icons[app] ?? Icons.payment,
                            size: 18,
                            color: active ? AppColors.accent : AppColors.bodyGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            app.label,
                            style: AppText.body(
                              size: 13.5,
                              weight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? AppColors.accentDeep : AppColors.ink,
                            ),
                          ),
                        ),
                        Icon(
                          active ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: active ? AppColors.accent : AppColors.bodyGrey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
