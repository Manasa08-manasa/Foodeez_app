import 'env.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl => Env.apiBaseUrl;
  static const String tokenKey = 'restaurant_onboarding_token';
  static String get encryptionKeyHex => Env.passwordEncryptionKeyHex;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 20;
  static const Duration ordersPollInterval = Duration(seconds: 15);

  /// Partner KDS pool — Orders screen (GET /partner/orders).
  static const String partnerActiveStatuses = 'PLACED,ACCEPTED,PREPARING';

  /// Home live orders (GET /restaurant/orders).
  static const String homeLiveOrderStatuses = 'PLACED,CONFIRMED,PREPARING,READY_FOR_PICKUP';
  static const int homeLiveOrdersPage = 1;
  static const int homeLiveOrdersLimit = 20;

  /// Restaurant-admin ongoing pool — catches CONFIRMED orders not in partner API.
  static const String ongoingOrderStatuses = 'PLACED,ACCEPTED,CONFIRMED,PREPARING';

  /// Ready / out-for-delivery pool (GET /restaurant/orders).
  static const String readyOrderStatuses = 'READY,READY_FOR_PICKUP,PICKED_UP,ON_THE_WAY';

  /// Completed / terminal orders for history tab.
  static const String completedOrderStatuses = 'DELIVERED,CANCELLED,REJECTED,FAILED';

  static const int ordersPage = 1;
  static const int ordersLimit = 20;
  static const int historyOrdersLimit = 30;

  /// Backend auto-rejects PLACED orders after 180 seconds.
  static const int autoRejectSeconds = 180;

  /// Prep time presets (minutes) — matches web KDS.
  static const List<int> prepTimePresets = [10, 15, 20, 30, 45, 60];
  static const int defaultPrepMinutes = 15;
  static const int minPrepMinutes = 1;
  static const int maxPrepMinutes = 120;

  static String get wsOrigin {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return base;
  }

  static const String partnerOrdersLiveSocket = '/ws/partner/orders/live';

  static const String roleRestaurantAdmin = 'restaurant_admin';
  static const String roleRestaurantOwner = 'restaurant_owner';
  static const String roleRestaurantManager = 'restaurant_manager';
  static const String roleRestaurantStaff = 'restaurant_staff';

  static const List<String> restaurantRoles = [
    roleRestaurantAdmin,
    roleRestaurantOwner,
    roleRestaurantManager,
    roleRestaurantStaff,
  ];
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String passwordReset = '/auth/password-reset';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';

  static String restaurant(String id) => '/restaurants/$id';
  static String restaurantOnboarding(String id) => '/restaurants/$id/onboarding';
  static String restaurantDocuments(String id) => '/restaurants/$id/documents';
  static String restaurantUsers(String id) => '/restaurants/$id/users';

  static String branches(String restaurantId) => '/restaurants/$restaurantId/branches';
  static String branch(String restaurantId, String branchId) =>
      '/restaurants/$restaurantId/branches/$branchId';

  static String menuCategories(String branchId) => '/branches/$branchId/menu-categories';
  static String menuCategory(String categoryId) => '/menu-categories/$categoryId';
  static String menuItems(String branchId) => '/branches/$branchId/menu-items';
  static String menuItem(String itemId) => '/menu-items/$itemId';
  static String menuItemAddons(String itemId) => '/menu-items/$itemId/addons';

  static const String restaurantOrders = '/restaurant/orders';
  static String restaurantOrder(String orderId) => '/restaurant/orders/$orderId';
  static String restaurantOrderStatus(String orderId) => '/restaurant/orders/$orderId/status';

  static const String partnerOrders = '/partner/orders';
  static String partnerOrderAccept(String orderId) => '/partner/orders/$orderId/accept';
  static String partnerOrderReject(String orderId) => '/partner/orders/$orderId/reject';
  static String partnerOrderReady(String orderId) => '/partner/orders/$orderId/ready';

  static const String settlementToday = '/partner/settlement/today';
  static const String settlementTodayOrders = '/partner/settlement/today/orders';

  static String coupons(String restaurantId) => '/coupons/restaurants/$restaurantId';

  static String restaurantReviews(String restaurantId) =>
      '/customer/reviews/restaurant/$restaurantId';

  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Partner self-registration (OTP → step1 → step2 → step3)
  static const String partnerRequestOtp = '/partner/request-otp';
  static const String partnerSendOtp = '/partner/send-otp';
  static const String partnerVerifyOtp = '/partner/verify-otp';
  static const String partnerRegisterStep1 = '/partner/register-step1';
  static String partnerRegisterStep2(String restaurantId) =>
      '/partner/register-step2/$restaurantId';
  static String partnerRegisterStep3(String restaurantId) =>
      '/partner/register-step3/$restaurantId';

  static const String createRestaurant = '/restaurants';
  static const String registrationPricing = '/restaurants/register/pricing';
  static const String verifyPan = '/restaurants/verify-pan';
  static const String menuScan = '/menu-scan';
  static String registrationDocuments(String restaurantId) =>
      '/restaurants/$restaurantId/documents/registration';
  static String registrationCoverPhoto(String restaurantId) =>
      '/restaurants/$restaurantId/register/step3/cover-photo';
  static String registrationPaymentCreateOrder(String restaurantId) =>
      '/restaurants/$restaurantId/register/payment/create-order';
  static String registrationPaymentVerify(String restaurantId) =>
      '/restaurants/$restaurantId/register/payment/verify';
}
