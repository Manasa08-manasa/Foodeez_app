import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/bookings_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../utils/utils.dart';
import '../widgets/common.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final bookingsCtrl = ref.watch(bookingsControllerProvider);
    final onBookings = bookingsCtrl.bookTab == 'bookings';
    final bottomPad = AppResponsive.of(context).dockClearance(showDock: false);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: 'Table bookings', onBack: nav.back),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedPills(labels: const ['Bookings', 'Payments'], selectedIndex: onBookings ? 0 : 1, onSelect: (i) => bookingsCtrl.setBookTab(i == 0 ? 'bookings' : 'payments')),
          ),
          Expanded(
            child: onBookings
                ? ListView(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                    children: bookingsCtrl.bookings.map((b) {
                      final stBg = {'Confirmed': AppColors.greenPaleBg2, 'Completed': AppColors.cardBorder, 'Cancelled': AppColors.redPaleBg2}[b.status]!;
                      final stFg = {'Confirmed': AppColors.green, 'Completed': AppColors.bodyGrey, 'Cancelled': AppColors.redDark}[b.status]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusBadge(label: b.status, fg: stFg, bg: stBg),
                                const SizedBox(width: 9),
                                Flexible(child: Text('#${b.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13, weight: FontWeight.w700))),
                                const SizedBox(width: 8),
                                Flexible(child: Text('${b.date} · ${b.time}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AppText.body(size: 12, color: AppColors.bodyGrey))),
                              ],
                            ),
                            Padding(padding: const EdgeInsets.only(top: 10), child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(size: 15))),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('👥 ${b.party} guests  ·  ${b.ref}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 11),
                              padding: const EdgeInsets.only(top: 11),
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline, style: BorderStyle.solid))),
                              child: Row(
                                children: [
                                  StatusBadge(
                                    label: b.paid ? 'Prepaid ${moneyFmt(b.amount)}' : 'Pay at venue',
                                    fg: b.paid ? AppColors.blue : AppColors.amber,
                                    bg: b.paid ? AppColors.bluePaleBg2 : const Color(0xFFFBF7ED),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(b.note, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AppText.body(size: 11.5, color: AppColors.lightGreyText))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                        decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Received via Foodeez', style: AppText.body(size: 12, color: Colors.white.withValues(alpha: 0.85))),
                            Text(moneyFmt(bookingsCtrl.paymentsTotal), style: AppText.display(size: 26, color: Colors.white)),
                            Padding(padding: const EdgeInsets.only(top: 2), child: Text('Prepaid table advances & online orders', style: AppText.body(size: 11.5, color: Colors.white.withValues(alpha: 0.82)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: bookingsCtrl.payments.map((p) {
                            final isDebit = p.kind == 'debit';
                            final isPaid = p.kind == 'paid';
                            final icon = isDebit ? '↩' : (isPaid ? '✓' : '₹');
                            final iconBg = isDebit ? AppColors.redPaleBg2 : (isPaid ? AppColors.cardBorder : AppColors.greenPaleBg2);
                            final iconFg = isDebit ? AppColors.redDark : (isPaid ? AppColors.bodyGrey : AppColors.green);
                            final amtColor = isDebit ? AppColors.redDark : (isPaid ? AppColors.bodyGrey : AppColors.green);
                            final amtLabel = (isDebit ? '– ' : (isPaid ? 'Paid · ' : '+ ')) + moneyFmt(p.amount);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                              child: Row(
                                children: [
                                  Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Text(icon, style: AppText.body(size: 15, weight: FontWeight.w800, color: iconFg))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13, weight: FontWeight.w700)),
                                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('${p.method} · ${p.when}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11, color: AppColors.bodyGrey))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(amtLabel, style: AppText.body(size: 13.5, weight: FontWeight.w800, color: amtColor)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
