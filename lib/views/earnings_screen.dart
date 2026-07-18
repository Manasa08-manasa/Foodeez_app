import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_data.dart';
import '../models/models.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/earnings_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../utils/utils.dart';
import '../widgets/common.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  static const _periods = ['today', 'week', 'month'];
  static const _periodLabels = ['Today', 'Week', 'Month'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final earningsCtrl = ref.watch(earningsControllerProvider);
    final d = earningsCtrl.currentEarningsPeriod;
    final settlements = earningsCtrl.visibleSettlements;
    final r = AppResponsive.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: r.scrollPadding(showDock: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Earnings', onBack: nav.back),
            const SizedBox(height: 10),
            SegmentedPills(labels: _periodLabels, selectedIndex: _periods.indexOf(earningsCtrl.earnPeriod), onSelect: (i) => earningsCtrl.setEarnPeriod(_periods[i])),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.heroGradientDeep, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Net payout · ${d.label}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, color: Colors.white.withValues(alpha: 0.85))),
                      ),
                      const SizedBox(width: 8),
                      Text(d.span, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(moneyFmt(d.net), style: AppText.display(size: 34, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.orders} orders  ·  GMV ${moneyFmt(d.gmv)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 11.5, color: Colors.white.withValues(alpha: 0.82)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.greenPaleBg2, border: Border.all(color: AppColors.greenPaleBorder), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You saved vs 30% commission', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.greenDark)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(moneyFmt(d.saved), style: AppText.display(size: 24, color: AppColors.green)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.show_chart_outlined, size: 26, color: AppColors.green),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: nav.toSubscription,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.maroonTint, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(Icons.credit_card_outlined, size: 18, color: Colors.white)),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subscription · Tier ${earningsCtrl.subscriptionTierToday}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13.5, weight: FontWeight.w800)),
                          Text('${moneyFmt(earningsCtrl.subscriptionFeeToday)} · ${subscriptionTiers[earningsCtrl.subscriptionTierToday - 1].range} orders/day', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.chevronGrey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.label} breakdown', style: AppText.body(size: 14, weight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _row('Gross item sales', moneyFmt(d.gmv), AppColors.ink),
                  _row('FooDeeZ commission', '₹0 · never', AppColors.green),
                  _row('Daily subscription (${d.subNote})', '– ${moneyFmt(d.subscriptionFee)}', AppColors.red),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(top: 11),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net payout', style: AppText.body(size: 15, weight: FontWeight.w800)),
                        Text(moneyFmt(d.net), style: AppText.body(size: 15, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Recent settlements', style: AppText.display(size: 15)),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [('all', 'All'), ('7', 'Last 7 days'), ('30', 'Last 30 days')]
                    .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: FzChip(label: c.$2, selected: earningsCtrl.settleRange == c.$1, onTap: () => earningsCtrl.setSettleRange(c.$1))))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            ...settlements.map((s) => _SettlementCard(settlement: s)),
            const SizedBox(height: 20),
            Text('Download reports', style: AppText.display(size: 15)),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [('today', 'Today'), ('week', 'This week'), ('month', 'This month'), ('year', 'This year')]
                    .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: FzChip(label: c.$2, selected: earningsCtrl.reportPeriod == c.$1, onTap: () => earningsCtrl.setReportPeriod(c.$1))))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(children: reportDefs.map((r) => _ReportRow(id: r.id, name: r.name, desc: r.desc)).toList()),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Reports pull from your live data and download as Excel (.xlsx) for the selected period.', style: AppText.body(size: 11, color: AppColors.bodyGrey, height: 1.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.midGrey)),
            Text(value, style: AppText.body(size: 13, weight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _SettlementCard extends ConsumerWidget {
  final Settlement settlement;
  const _SettlementCard({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsCtrl = ref.watch(earningsControllerProvider);
    final open = earningsCtrl.openSettleId == settlement.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => earningsCtrl.toggleSettle(settlement.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.greenPaleBg, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 16))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settlement.week, style: AppText.body(size: 13, weight: FontWeight.w700)),
                        Text(settlement.date, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                      ],
                    ),
                  ),
                  Text(moneyFmt(settlement.net), style: AppText.body(size: 14, weight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  AnimatedRotation(turns: open ? 0.25 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.chevron_right, size: 18, color: AppColors.chevronGrey)),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.cardBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EARNINGS', style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.5)),
                      Text('${settlement.orders} orders · ${settlement.tierLabel}', style: AppText.body(size: 10, weight: FontWeight.w600, color: AppColors.lightGreyText)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _kv('Item sales (net of discount)', '+ ${moneyFmt(settlement.itemSales)}', AppColors.green),
                  _kv('Packaging charges', '+ ${moneyFmt(settlement.packaging)}', AppColors.green),
                  _divider(),
                  _kv('Gross earnings', moneyFmt(settlement.gross), AppColors.ink, bold: true),
                  const SizedBox(height: 12),
                  Text('DEDUCTIONS', style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.5)),
                  const SizedBox(height: 7),
                  _kv('Customer discount (you funded)', '– ${moneyFmt(settlement.discount)}', AppColors.red),
                  _kv('FooDeeZ subscription · ${settlement.tierLabel}', '– ${moneyFmt(settlement.subscriptionFee)}', AppColors.red),
                  _kv('Ads & promotions', '– ${moneyFmt(settlement.ads)}', AppColors.red),
                  _kv('Delivery subsidy (your share)', '– ${moneyFmt(settlement.delivery)}', AppColors.red),
                  _kv('TCS @1% (GST, Sec 52)', '– ${moneyFmt(settlement.tcs)}', AppColors.red),
                  _kv('TDS @0.1% (income tax, Sec 194-O)', '– ${moneyFmt(settlement.tds)}', AppColors.red),
                  _divider(),
                  _kv('Total deductions', '– ${moneyFmt(settlement.totalDeductions)}', AppColors.red, bold: true),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.only(top: 11),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline, width: 1.5))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net payout to bank', style: AppText.body(size: 15, weight: FontWeight.w800)),
                        Text(moneyFmt(settlement.net), style: AppText.body(size: 15, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(color: AppColors.bluePaleBg2, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ℹ️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'GST ${moneyFmt(settlement.gst)} collected from customers is remitted to government on your behalf — it is not part of your payout. TCS & TDS are adjustable against your tax filings.',
                            style: AppText.body(size: 10.5, color: const Color(0xFF5C6B78), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Container(margin: const EdgeInsets.symmetric(vertical: 6), height: 1, color: AppColors.hairline);

  Widget _kv(String label, String value, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: AppText.body(size: 12, weight: bold ? FontWeight.w700 : FontWeight.w600, color: bold ? AppColors.ink : AppColors.midGrey))),
            Text(value, style: AppText.body(size: 12, weight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _ReportRow extends ConsumerWidget {
  final String id;
  final String name;
  final String desc;
  const _ReportRow({required this.id, required this.name, required this.desc});

  static const _tint = {
    'orders': AppColors.maroonTint,
    'payments': AppColors.bluePaleBg2,
    'gst': AppColors.amberPaleBg,
    'items': AppColors.neutralTint3,
    'invoices': AppColors.greenPaleBg2,
  };
  static const _emoji = {'orders': '🧾', 'payments': '💳', 'gst': '🏛️', 'items': '📊', 'invoices': '📄'};
  static const _periodLabel = {'today': 'today', 'week': 'this week', 'month': 'this month', 'year': 'this year'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsCtrl = ref.watch(earningsControllerProvider);
    final state = earningsCtrl.reportState(id);
    final label = switch (state) {
      'loading' => 'Preparing…',
      'done' => '✓ Saved',
      _ => '⬇ XLSX',
    };
    final bg = switch (state) {
      'done' => AppColors.greenPaleBg2,
      'loading' => AppColors.cardBorder,
      _ => AppColors.maroonTint,
    };
    final fg = switch (state) {
      'done' => AppColors.green,
      'loading' => AppColors.bodyGrey,
      _ => AppColors.accent,
    };

    return GestureDetector(
      onTap: () => earningsCtrl.downloadReport(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: _tint[id], borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(_emoji[id]!, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                  Text('$desc · ${_periodLabel[earningsCtrl.reportPeriod]}', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Text(label, style: AppText.body(size: 11.5, weight: FontWeight.w800, color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}
