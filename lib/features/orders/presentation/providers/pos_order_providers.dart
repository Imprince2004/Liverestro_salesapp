import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/pos_software_order_model.dart';

final posSoftwareOrderListProvider = StateNotifierProvider<PosSoftwareOrderListNotifier, AsyncValue<List<PosSoftwareOrderModel>>>((ref) {
  return PosSoftwareOrderListNotifier();
});

class PosSoftwareOrderListNotifier extends StateNotifier<AsyncValue<List<PosSoftwareOrderModel>>> {
  PosSoftwareOrderListNotifier() : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      if (state.value == null || state.value!.isEmpty) {
        state = const AsyncValue.loading();
      }
      final api = getIt<ApiClient>();
      final response = await api.get('/api/pos-orders');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is String ? jsonDecode(response.data) : response.data;
        final rawList = (body['data'] as List<dynamic>?) ?? [];
        final orders = rawList.map((e) => PosSoftwareOrderModel.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(orders);
      } else {
        throw Exception('Failed to load POS software orders');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updatePosStatus({
    required String orderId,
    required String posType,
    required double amount,
  }) async {
    try {
      final api = getIt<ApiClient>();
      final isPaid = posType.toUpperCase() == 'PAID';
      final response = await api.put('/api/pos-orders/$orderId', data: {
        'pos_type': isPaid ? 'Paid' : 'Free',
        'amount': isPaid ? amount : 0.0,
      });

      if (response.statusCode == 200) {
        await loadOrders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createPosOrder(Map<String, dynamic> data) async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.post('/api/pos-orders', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadOrders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
