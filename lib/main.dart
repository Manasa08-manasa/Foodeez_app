import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/auth_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/orders_controller.dart';
import 'utils/responsive.dart';
import 'utils/theme.dart';
import 'widgets/dock_nav.dart';
import 'widgets/incoming_order_alert.dart';
import 'widgets/kot_modal.dart';
import 'widgets/prep_time_prompt.dart';

import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/orders_screen.dart';
import 'views/order_detail_screen.dart';
import 'views/menu_screen.dart';
import 'views/earnings_screen.dart';
import 'views/subscription_screen.dart';
import 'views/new_coupon_screen.dart';
import 'views/offers_screen.dart';
import 'views/insights_screen.dart';
import 'views/branches_screen.dart';
import 'views/reviews_screen.dart';
import 'views/settings_screen.dart';
import 'views/team_screen.dart';
import 'views/hours_screen.dart';
import 'views/support_screen.dart';
import 'views/address_screen.dart';
import 'views/fssai_screen.dart';
import 'views/bookings_screen.dart';
import 'views/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodeezPartnerApp());
}

class FoodeezPartnerApp extends StatelessWidget {
  const FoodeezPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'FooDeeZ Partner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            primary: AppColors.accent,
          ),
          fontFamily: 'Plus Jakarta Sans',
          splashFactory: InkRipple.splashFactory,
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = {
    'splash': SplashScreen(),
    'login': LoginScreen(),
    'register': RegisterScreen(),
    'dashboard': DashboardScreen(),
    'orders': OrdersScreen(),
    'detail': OrderDetailScreen(),
    'menu': MenuScreen(),
    'branches': BranchesScreen(),
    'earnings': EarningsScreen(),
    'subscription': SubscriptionScreen(),
    'newCoupon': NewCouponScreen(),
    'offers': OffersScreen(),
    'insights': InsightsScreen(),
    'reviews': ReviewsScreen(),
    'settings': SettingsScreen(),
    'team': TeamScreen(),
    'hours': HoursScreen(),
    'support': SupportScreen(),
    'address': AddressScreen(),
    'fssai': FssaiScreen(),
    'bookings': BookingsScreen(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final auth = ref.watch(authControllerProvider);

    if (auth.bootstrapping) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final screen = _screens[nav.screen] ?? const DashboardScreen();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(navigationControllerProvider).back();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: AdaptiveContentWidth(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  layoutBuilder: (currentChild, previousChildren) {
                    final children = [...previousChildren];
                    if (currentChild != null) {
                      children.add(currentChild);
                    }
                    return Stack(fit: StackFit.expand, children: children);
                  },
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(key: ValueKey(nav.screen), child: screen),
                ),
              ),
            ),
            // Navigation header is rendered by individual screens using
            // `ScreenHeader` / `BackCircleButton` to avoid duplicate buttons.
            if (nav.showTabBar)
              Positioned(
                left: 14,
                right: 14,
                // Sit above Android/iOS system nav (gesture bar / 3-button nav).
                bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
                child: AdaptiveContentWidth(
                  maxWidth: AppResponsive.of(context).dockMaxWidth,
                  child: const DockNav(),
                ),
              ),
            if (orders.showAlert) const IncomingOrderAlert(),
            if (orders.prepFor != null) const PrepTimePrompt(),
            if (orders.kotFor != null) const KotModal(),
          ],
        ),
      ),
    );
  }
}
