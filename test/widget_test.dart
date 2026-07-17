import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodeez_partner/main.dart';
import 'package:foodeez_partner/models/models.dart';
import 'package:foodeez_partner/controllers/auth_controller.dart';
import 'package:foodeez_partner/controllers/navigation_controller.dart';
import 'package:foodeez_partner/controllers/orders_controller.dart';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _settleBootstrap(WidgetTester tester) async {
  await tester.pump();
  // AuthController.bootstrap is async; allow it to finish without hanging on
  // infinite animations later in the tree.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    final auth = _container(tester).read(authControllerProvider);
    if (!auth.bootstrapping) break;
  }
}

void main() {
  testWidgets('App launches to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);

    expect(find.text('Log in to dashboard'), findsOneWidget);
    expect(find.text('Partner email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Navigating to dashboard shows Live orders', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);

    final container = _container(tester);
    container.read(navigationControllerProvider).tab('dashboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Live orders'), findsOneWidget);
  });

  testWidgets('Register screen renders the multi-step registration form', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);

    final container = _container(tester);
    container.read(navigationControllerProvider).go('register');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Register Restaurant'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
  });

  testWidgets('Register screen shows a back navigation control', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);

    final container = _container(tester);
    container.read(navigationControllerProvider).go('register');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });

  testWidgets('Every screen renders without layout exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);
    final container = _container(tester);
    final nav = container.read(navigationControllerProvider);
    final orders = container.read(ordersControllerProvider);
    nav.tab('dashboard');
    await tester.pump();

    const screens = [
      'dashboard', 'orders', 'menu', 'earnings', 'subscription', 'newCoupon',
      'offers', 'insights', 'reviews', 'settings', 'hours', 'support',
      'address', 'fssai', 'bookings',
    ];

    for (final screen in screens) {
      nav.go(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Exception while rendering "$screen"');
      nav.back();
      await tester.pump();
    }

    orders.oid = orders.orders.first.id;
    nav.go('detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'Exception while rendering "detail"');
  });

  testWidgets('Accepting an incoming order walks the full status lifecycle', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);
    final container = _container(tester);
    final nav = container.read(navigationControllerProvider);
    final orders = container.read(ordersControllerProvider);
    nav.tab('dashboard');
    await tester.pump();

    final incomingId = orders.orders.firstWhere((o) => o.status == OrderStatus.incoming).id;
    expect(orders.newCount, 1);

    orders.askPrep(incomingId);
    expect(orders.prepFor, incomingId);
    await orders.confirmPrep();
    expect(orders.orderById(incomingId)!.status, OrderStatus.preparing);

    await orders.advance(incomingId);
    expect(orders.orderById(incomingId)!.status, OrderStatus.ready);

    final beforeDone = orders.doneToday;
    await orders.advance(incomingId);
    await orders.advance(incomingId);
    expect(orders.orderById(incomingId)!.status, OrderStatus.completed);
    expect(orders.doneToday, beforeDone + 1);
  });

  testWidgets('Back buttons on pushed sub-screens hug the top', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodeezPartnerApp());
    await _settleBootstrap(tester);
    final container = _container(tester);
    final nav = container.read(navigationControllerProvider);
    nav.tab('dashboard');
    await tester.pump();

    for (final screen in ['earnings', 'subscription', 'offers', 'reviews', 'hours', 'support', 'address', 'fssai', 'bookings']) {
      nav.go(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final rect = tester.getRect(find.byIcon(Icons.arrow_back_ios_new).first);
      expect(rect.top, lessThan(60), reason: 'Back button on "$screen" is too far from the top (top=${rect.top})');
      nav.back();
      await tester.pump();
    }
  });
}
