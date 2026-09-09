import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/order_repository.dart';

/// Provider for the Order Repository.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return getIt<OrderRepository>();
});

/// FutureProvider for the product catalog.
final productCatalogProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getProductCatalog();
});

/// FutureProvider for the list of orders.
final orderListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrders();
});
