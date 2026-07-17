import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants/app_constants.dart';
import '../models/api/order_models.dart';

typedef PartnerOrderHandler = void Function(ApiOrder order);
typedef PartnerOrderCancelledHandler = void Function(String orderId);

/// Real-time partner order events — mirrors web KDS Socket.IO:
/// `join-restaurant-room`, `new-order`, `order-cancelled`.
class PartnerOrdersSocket {
  io.Socket? _socket;
  String? _restaurantId;

  void connect({
    required String token,
    required String restaurantId,
    required PartnerOrderHandler onNewOrder,
    required PartnerOrderCancelledHandler onOrderCancelled,
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
  }) {
    if (restaurantId.isEmpty) return;
    if (_socket != null && _restaurantId == restaurantId && _socket!.connected) return;

    disconnect();
    _restaurantId = restaurantId;

    final url = '${AppConstants.wsOrigin}${AppConstants.partnerOrdersLiveSocket}';
    debugPrint('[PartnerSocket] connecting → $url');

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionDelay(5000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('[PartnerSocket] connected');
        onConnected?.call();
        _socket?.emit('join-restaurant-room', {'restaurantId': restaurantId});
      })
      ..onDisconnect((_) {
        debugPrint('[PartnerSocket] disconnected');
        onDisconnected?.call();
      })
      ..onConnectError((err) {
        debugPrint('[PartnerSocket] connect error: $err');
        onDisconnected?.call();
      })
      ..on('new-order', (data) {
        if (data is! Map) return;
        try {
          onNewOrder(ApiOrder.fromJson(Map<String, dynamic>.from(data)));
        } catch (e) {
          debugPrint('[PartnerSocket] new-order parse failed: $e');
        }
      })
      ..on('order-cancelled', (data) {
        if (data is! Map) return;
        final id = data['orderId']?.toString();
        if (id != null && id.isNotEmpty) onOrderCancelled(id);
      });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _restaurantId = null;
  }

  bool get isConnected => _socket?.connected == true;
}
