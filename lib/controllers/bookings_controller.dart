import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/mock_data.dart';

/// Owns table bookings and the linked payments/settlement-advance ledger.
class BookingsController extends ChangeNotifier {
  final List<TableBooking> bookings = seedBookings();
  final List<PaymentTxn> payments = seedPayments();
  String bookTab = 'bookings'; // bookings | payments

  void setBookTab(String t) {
    bookTab = t;
    notifyListeners();
  }

  int get paymentsTotal => payments.where((p) => p.kind == 'credit').fold(0, (a, p) => a + p.amount);
}

final bookingsControllerProvider =
    ChangeNotifierProvider<BookingsController>((ref) => BookingsController());
