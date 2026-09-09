import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/target_remote_data_source.dart';
import '../../data/models/monthly_target_model.dart';
import '../../data/models/implementation_model.dart';
import '../../../leads/presentation/providers/lead_providers.dart';

// Filter state providers
final implementationSearchQueryProvider = StateProvider<String>((ref) => '');
final implementationStageFilterProvider = StateProvider<String>((ref) => 'ALL');
final implementationStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

// Selected month/year filter for targets
final targetSelectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final targetSelectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// Target Providers
final myMonthlyTargetProvider = FutureProvider.autoDispose<MonthlyTargetModel>((ref) async {
  final month = ref.watch(targetSelectedMonthProvider);
  final year = ref.watch(targetSelectedYearProvider);
  // Auto-recalculate whenever leads change in real-time
  ref.watch(leadListProvider);
  return TargetRemoteDataSource.fetchMyTarget(month: month, year: year);
});

final teamMonthlyTargetsProvider = FutureProvider.autoDispose<List<MonthlyTargetModel>>((ref) async {
  final month = ref.watch(targetSelectedMonthProvider);
  final year = ref.watch(targetSelectedYearProvider);
  ref.watch(leadListProvider);
  return TargetRemoteDataSource.fetchTeamTargets(month: month, year: year);
});

// Implementation Providers
final myImplementationTasksProvider = FutureProvider.autoDispose<List<ImplementationModel>>((ref) async {
  ref.watch(leadListProvider);
  return TargetRemoteDataSource.fetchMyImplementationTasks();
});

final allImplementationsProvider = FutureProvider.autoDispose<List<ImplementationModel>>((ref) async {
  final stage = ref.watch(implementationStageFilterProvider);
  final status = ref.watch(implementationStatusFilterProvider);
  final search = ref.watch(implementationSearchQueryProvider);
  ref.watch(leadListProvider);

  return TargetRemoteDataSource.fetchAllImplementations(
    stage: stage,
    status: status,
    search: search,
  );
});

class TargetActionNotifier extends StateNotifier<bool> {
  final Ref ref;
  TargetActionNotifier(this.ref) : super(false);

  Future<bool> assignTarget({
    required String userId,
    required int targetLeads,
    int? month,
    int? year,
    int? targetVisits,
    String? notes,
  }) async {
    state = true;
    try {
      await TargetRemoteDataSource.assignTarget(
        userId: userId,
        targetLeads: targetLeads,
        month: month,
        year: year,
        targetVisits: targetVisits,
        notes: notes,
      );
      ref.invalidate(myMonthlyTargetProvider);
      ref.invalidate(teamMonthlyTargetsProvider);
      state = false;
      return true;
    } catch (_) {
      state = false;
      return false;
    }
  }

  Future<bool> assignStage({
    required String id,
    required String stage,
    required String assignedToId,
    String? assignedToName,
    String? assignedDate,
    String? notes,
  }) async {
    state = true;
    try {
      final res = await TargetRemoteDataSource.assignStage(
        id: id,
        stage: stage,
        assignedToId: assignedToId,
        assignedToName: assignedToName,
        assignedDate: assignedDate,
        notes: notes,
      );
      ref.invalidate(myImplementationTasksProvider);
      ref.invalidate(allImplementationsProvider);
      state = false;
      return res != null;
    } catch (_) {
      state = false;
      return false;
    }
  }

  Future<bool> updateStageStatus({
    required String id,
    required String stage,
    required String status,
    String? completedDate,
    String? notes,
  }) async {
    state = true;
    try {
      final res = await TargetRemoteDataSource.updateStageStatus(
        id: id,
        stage: stage,
        status: status,
        completedDate: completedDate,
        notes: notes,
      );
      ref.invalidate(myImplementationTasksProvider);
      ref.invalidate(allImplementationsProvider);
      state = false;
      return res != null;
    } catch (_) {
      state = false;
      return false;
    }
  }

  void refreshAll() {
    ref.invalidate(myMonthlyTargetProvider);
    ref.invalidate(teamMonthlyTargetsProvider);
    ref.invalidate(myImplementationTasksProvider);
    ref.invalidate(allImplementationsProvider);
  }
}

final targetActionProvider = StateNotifierProvider<TargetActionNotifier, bool>((ref) {
  return TargetActionNotifier(ref);
});
