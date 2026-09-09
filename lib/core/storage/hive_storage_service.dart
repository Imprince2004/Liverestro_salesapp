import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});

/// Hive Document/Cache local key-value storage wrapper.
class HiveStorageService {
  static const String appBoxName = 'liverestro_sales_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(appBoxName);
  }

  Box get _box => Hive.box(appBoxName);

  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  T? get<T>(String key, {T? defaultValue}) {
    return _box.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
