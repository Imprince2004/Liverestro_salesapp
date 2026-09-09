import 'dart:convert';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/pending_request_queue.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';

class OrderRepository {
  static const String _orderCacheKey = 'cached_orders';
  static const String _catalogCacheKey = 'cached_products';

  final List<ProductModel> _mockCatalog = const [
    ProductModel(
      id: 'prd_01',
      title: 'LiveRestro POS License (Annual)',
      category: 'Software',
      price: 24000.0,
      description: 'Cloud Restaurant POS with Billing, Inventory, KDS & Analytics.',
      sku: 'LR-POS-ANN',
    ),
    ProductModel(
      id: 'prd_02',
      title: 'Android Touch POS Terminal (15")',
      category: 'Hardware',
      price: 32000.0,
      description: 'Dual screen Android touch POS terminal with customer display.',
      sku: 'HW-TRM-15D',
    ),
    ProductModel(
      id: 'prd_03',
      title: '80mm Thermal Receipt Printer',
      category: 'Hardware',
      price: 6500.0,
      description: 'High-speed auto-cutter USB/Ethernet thermal printer.',
      sku: 'HW-PRN-80',
    ),
  ];

  final List<OrderModel> _mockOrders = const [
    OrderModel(
      id: 'ORD-9021',
      restaurantName: 'Spice Junction Fine Dine',
      items: [
        OrderItemModel(productId: 'prd_01', title: 'LiveRestro POS License', price: 24000.0, quantity: 1),
        OrderItemModel(productId: 'prd_03', title: 'Thermal Receipt Printer', price: 6500.0, quantity: 2),
      ],
      subtotal: 37000.0,
      discountAmount: 2000.0,
      taxAmount: 6300.0,
      totalAmount: 41300.0,
      paymentTerms: 'Net 15 Days',
      status: 'Confirmed',
      createdAt: 'Today, 11:30 AM',
      isSynced: true,
    ),
  ];

  Future<List<ProductModel>> getProductCatalog() async {
    List<ProductModel> list = [];
    final api = getIt<ApiClient>();
    final hive = getIt<HiveStorageService>();

    try {
      final response = await api.get('/api/products');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List<dynamic>;
        list = rawList.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
        await hive.put(_catalogCacheKey, jsonStr);
      } else {
        throw Exception('API error');
      }
    } catch (_) {
      final jsonStr = hive.get<String>(_catalogCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        list = decoded.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        list = List.from(_mockCatalog);
      }
    }
    return list;
  }

  Future<List<OrderModel>> getOrders() async {
    List<OrderModel> list = [];
    final api = getIt<ApiClient>();
    final hive = getIt<HiveStorageService>();

    try {
      final response = await api.get('/api/orders');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List<dynamic>;
        list = rawList.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
        await hive.put(_orderCacheKey, jsonStr);
      } else {
        throw Exception('API error');
      }
    } catch (_) {
      final jsonStr = hive.get<String>(_orderCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        list = decoded.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        list = List.from(_mockOrders);
      }
    }
    return list;
  }

  Future<void> createOrder(OrderModel order) async {
    final api = getIt<ApiClient>();
    final queue = getIt<PendingRequestQueue>();
    final hive = getIt<HiveStorageService>();

    // Update local cache immediately (Optimistic UI update)
    final cached = await getOrders();
    final updated = [order, ...cached];
    await hive.put(_orderCacheKey, jsonEncode(updated.map((e) => e.toJson()).toList()));

    try {
      await api.post('/api/orders', data: order.toJson());
    } catch (_) {
      await queue.enqueueRequest(
        id: order.id,
        endpoint: '/api/orders',
        method: 'POST',
        payload: jsonEncode(order.toJson()),
      );
    }
  }
}
