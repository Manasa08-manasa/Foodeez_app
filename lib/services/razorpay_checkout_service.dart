import '../core/constants/env.dart';
import '../models/api/registration_models.dart';

/// Partner-chosen payment app for registration fee checkout.
enum RegistrationPaymentApp {
  phonepe('PhonePe', 'phonepe', 'com.phonepe.app'),
  gpay('Google Pay', 'gpay', 'com.google.android.apps.nbu.paisa.user'),
  paytm('Paytm', 'paytm', 'net.one97.paytm'),
  bhim('BHIM UPI', 'bhim', 'in.org.npci.upiapp'),
  anyUpi('Any UPI app', null, null),
  razorpay('Card / Netbanking', null, null);

  const RegistrationPaymentApp(this.label, this.walletId, this.androidPackage);

  final String label;
  final String? walletId;
  final String? androidPackage;
}

class RazorpayCheckoutService {
  RazorpayCheckoutService._();

  static String resolveKeyId(CreateRegistrationOrderResponse order) {
    if (order.keyId.isNotEmpty) return order.keyId;
    return Env.razorpayKeyId;
  }

  static Map<String, dynamic> buildOptions({
    required CreateRegistrationOrderResponse order,
    required String ownerName,
    required String email,
    required String phone,
    required String restaurantId,
    required RegistrationPaymentApp paymentApp,
  }) {
    final description = order.isOfferActive
        ? 'Restaurant registration fee — offer price (MRP ₹${order.basePrice.toStringAsFixed(0)})'
        : 'Restaurant registration fee';

    final options = <String, dynamic>{
      'key': resolveKeyId(order),
      'amount': order.amount,
      'currency': order.currency,
      'order_id': order.orderId,
      'name': 'FooDeeZ',
      'description': description,
      'prefill': {
        'name': ownerName,
        'email': email,
        'contact': phone,
      },
      'notes': {'restaurantId': restaurantId},
      'theme': {'color': '#103A2B'},
      'retry': {'enabled': true, 'max_count': 3},
    };

    switch (paymentApp) {
      case RegistrationPaymentApp.phonepe:
      case RegistrationPaymentApp.gpay:
      case RegistrationPaymentApp.paytm:
      case RegistrationPaymentApp.bhim:
        options['method'] = {'upi': true};
        options['external'] = {
          'wallets': [paymentApp.walletId],
        };
        break;
      case RegistrationPaymentApp.anyUpi:
        options['method'] = {'upi': true};
        options['external'] = {
          'wallets': ['phonepe', 'gpay', 'paytm', 'bhim'],
        };
        break;
      case RegistrationPaymentApp.razorpay:
        options['method'] = {
          'card': true,
          'netbanking': true,
          'wallet': true,
          'upi': true,
        };
        break;
    }

    return options;
  }
}
