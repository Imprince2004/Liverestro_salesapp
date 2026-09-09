import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/restaurant_model.dart';
import '../../domain/repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository();
});

final restaurantSearchQueryProvider = StateProvider<String>((ref) => '');
final restaurantStatusFilterProvider = StateProvider<String>((ref) => 'All');
final restaurantCityFilterProvider = StateProvider<String?>((ref) => null);

final restaurantListProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final repo = ref.watch(restaurantRepositoryProvider);
  final query = ref.watch(restaurantSearchQueryProvider);
  final status = ref.watch(restaurantStatusFilterProvider);
  final city = ref.watch(restaurantCityFilterProvider);

  return repo.getRestaurants(
    query: query,
    status: status,
    city: city,
  );
});
