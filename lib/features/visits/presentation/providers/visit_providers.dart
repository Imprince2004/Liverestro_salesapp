import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/visit_model.dart';
import '../../domain/repositories/visit_repository.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final visitListProvider = FutureProvider<List<VisitModel>>((ref) async {
  final repo = ref.watch(visitRepositoryProvider);
  return repo.getVisits();
});
