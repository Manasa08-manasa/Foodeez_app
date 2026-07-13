import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../repositories/restaurant_repository.dart';
import '../services/mock_data.dart';
import 'auth_controller.dart';

/// Owns the reviews list and the rating filter on the Reviews screen.
class ReviewsController extends ChangeNotifier {
  ReviewsController(this.ref) {
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated && next.restaurantId != null) refresh();
    });
    if (ref.read(authControllerProvider).isAuthenticated) refresh();
  }

  final Ref ref;
  ProviderSubscription<AuthController>? _authSub;

  List<Review> reviews = seedReviews();
  String reviewFilter = 'all';
  bool usingApi = false;
  bool loading = false;
  double averageRating = 4.5;
  int totalRatings = 1140;
  List<({int star, int pct})> distribution = ratingDistribution;

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  Future<void> refresh() async {
    final rid = ref.read(authControllerProvider).restaurantId;
    if (rid == null) return;
    loading = true;
    notifyListeners();
    try {
      final raw = await ref.read(restaurantRepositoryProvider).getRestaurantReviews(rid);
      if (raw.isEmpty) {
        usingApi = false;
        loading = false;
        notifyListeners();
        return;
      }
      reviews = raw.map(_mapReview).toList();
      _recomputeStats();
      usingApi = true;
    } catch (e) {
      debugPrint('[Reviews] refresh failed: $e');
      if (!usingApi) {
        reviews = seedReviews();
        averageRating = 4.5;
        totalRatings = 1140;
        distribution = ratingDistribution;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Review _mapReview(Map<String, dynamic> json) {
    final rating = _toInt(
      json['restaurantRating'] ?? json['foodRating'] ?? json['rating'] ?? json['stars'],
      fallback: 5,
    );
    final name = (json['customerName'] ??
            json['customer']?['name'] ??
            json['name'] ??
            (json['isAnonymous'] == true ? 'Anonymous' : 'Customer'))
        .toString();
    final when = _formatWhen(json['createdAt'] ?? json['created_at']);
    final item = (json['menuItemName'] ??
            json['itemName'] ??
            json['item'] ??
            json['orderNumber'] ??
            'Order')
        .toString();
    final text = (json['reviewText'] ?? json['comment'] ?? json['text'] ?? '').toString();
    final reply = (json['reply'] ?? json['restaurantReply'] ?? '').toString();
    return Review(name: name, rating: rating.clamp(1, 5), when: when, item: item, text: text, reply: reply);
  }

  void _recomputeStats() {
    totalRatings = reviews.length;
    if (reviews.isEmpty) {
      averageRating = 0;
      distribution = List.generate(5, (i) => (star: 5 - i, pct: 0));
      return;
    }
    averageRating = reviews.fold<int>(0, (a, r) => a + r.rating) / reviews.length;
    distribution = List.generate(5, (i) {
      final star = 5 - i;
      final count = reviews.where((r) => r.rating == star).length;
      return (star: star, pct: ((count / reviews.length) * 100).round());
    });
  }

  void setReviewFilter(String f) {
    reviewFilter = f;
    notifyListeners();
  }

  List<Review> get filteredReviews =>
      reviewFilter == 'all' ? reviews : reviews.where((r) => r.rating == int.parse(reviewFilter)).toList();

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  static String _formatWhen(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '');
    if (dt == null) return raw?.toString() ?? '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

final reviewsControllerProvider =
    ChangeNotifierProvider<ReviewsController>((ref) => ReviewsController(ref));
