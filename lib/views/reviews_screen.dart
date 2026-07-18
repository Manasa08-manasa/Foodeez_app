import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/reviews_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final reviewsCtrl = ref.watch(reviewsControllerProvider);
    final reviews = reviewsCtrl.filteredReviews;
    const chips = [('all', 'All'), ('5', '5 ★'), ('4', '4 ★'), ('3', '3 ★'), ('2', '2 ★'), ('1', '1 ★')];

    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(title: 'Reviews', onBack: nav.back),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, AppResponsive.of(context).dockClearance(showDock: false)),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(reviewsCtrl.averageRating.toStringAsFixed(1), style: AppText.display(size: 40, height: 1)),
                          const Padding(padding: EdgeInsets.only(top: 2), child: Text('★★★★★', style: TextStyle(color: AppColors.star, fontSize: 14))),
                          Padding(padding: const EdgeInsets.only(top: 3), child: Text('${reviewsCtrl.totalRatings} ratings', style: AppText.body(size: 11, weight: FontWeight.w600, color: AppColors.bodyGrey))),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: reviewsCtrl.distribution
                              .map((d) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 8, child: Text('${d.star}', style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.bodyGrey))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(value: d.pct / 100, minHeight: 7, backgroundColor: AppColors.cardBorder, valueColor: const AlwaysStoppedAnimation(AppColors.star)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: FzChip(label: c.$2, selected: reviewsCtrl.reviewFilter == c.$1, onTap: () => reviewsCtrl.setReviewFilter(c.$1)))).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No reviews at this rating', style: AppText.body(size: 14, weight: FontWeight.w700))),
                  )
                else
                  ...reviews.map((r) {
                    final chipColor = r.rating >= 4 ? AppColors.green : (r.rating >= 3 ? AppColors.amberDark : AppColors.red);
                    final initials = r.name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.maroonTint), alignment: Alignment.center, child: Text(initials, style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.accent))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name, style: AppText.body(size: 13, weight: FontWeight.w700)),
                                    Text('${r.when} · ${r.item}', style: AppText.body(size: 11, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(8)), child: Text('${r.rating} ★', style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white))),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 9), child: Text(r.text, style: AppText.body(size: 13, color: AppColors.midGrey, height: 1.5))),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
