/// Raw API order status groupings — aligned with web KDS + restaurant orders pages.
class OrderStatusUtils {
  OrderStatusUtils._();

  static const ongoing = {'PLACED', 'ACCEPTED', 'CONFIRMED', 'PREPARING'};
  static const preparing = {'ACCEPTED', 'CONFIRMED', 'PREPARING'};
  static const ready = {'READY', 'READY_FOR_PICKUP', 'PICKED_UP', 'ON_THE_WAY'};
  static const completed = {'DELIVERED', 'COMPLETED', 'CANCELLED', 'REJECTED', 'FAILED'};

  static String norm(String? status) => status?.toUpperCase().trim() ?? '';

  static bool isOngoing(String? status) => ongoing.contains(norm(status));
  static bool isPreparing(String? status) => preparing.contains(norm(status));
  static bool isReady(String? status) => ready.contains(norm(status));
  static bool isCompleted(String? status) => completed.contains(norm(status));
  static bool isPlaced(String? status) => norm(status) == 'PLACED';
  static bool isAccepted(String? status) => norm(status) == 'ACCEPTED';
  static bool canPartnerMarkReady(String? status) => isAccepted(status);

  /// Prefer the more advanced status when the same order appears in multiple API pools.
  static int rank(String? status) => switch (norm(status)) {
        'PLACED' => 1,
        'CONFIRMED' => 2,
        'ACCEPTED' => 2,
        'PREPARING' => 3,
        'READY' => 4,
        'READY_FOR_PICKUP' => 4,
        'PICKED_UP' => 5,
        'ON_THE_WAY' => 6,
        'DELIVERED' => 7,
        'COMPLETED' => 7,
        'CANCELLED' => 7,
        'REJECTED' => 7,
        'FAILED' => 7,
        _ => 0,
      };

  static String displayLabel(String? apiStatus) => switch (norm(apiStatus)) {
        'PLACED' => 'NEW',
        'ACCEPTED' => 'ACCEPTED',
        'CONFIRMED' => 'CONFIRMED',
        'PREPARING' => 'PREPARING',
        'READY' => 'READY',
        'READY_FOR_PICKUP' => 'READY',
        'PICKED_UP' => 'PICKED UP',
        'ON_THE_WAY' => 'OUT FOR DELIVERY',
        'DELIVERED' => 'DELIVERED',
        'CANCELLED' => 'CANCELLED',
        'REJECTED' => 'REJECTED',
        'FAILED' => 'FAILED',
        _ => 'ORDER',
      };
}
