import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/follow_up_model.dart';
import '../../data/repositories/follow_up_repository.dart';

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepository();
});

class FollowUpsState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final FollowUpCounts counts;
  final List<FollowUpModel> allFollowUps;
  final int selectedTabIndex;
  final String searchQuery;

  const FollowUpsState({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.counts = const FollowUpCounts(),
    this.allFollowUps = const [],
    this.selectedTabIndex = 0,
    this.searchQuery = '',
  });

  int get todayCount => counts.today;
  int get upcomingCount => counts.upcoming;
  int get overdueCount => counts.overdue;
  int get completedCount => counts.completed;

  List<FollowUpModel> getItemsForStatus(FollowUpStatus status) {
    return allFollowUps.where((item) {
      final matchesStatus = item.computedStatus == status;
      if (!matchesStatus) return false;
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return item.restaurantName.toLowerCase().contains(q) ||
          item.contactPerson.toLowerCase().contains(q) ||
          item.address.toLowerCase().contains(q) ||
          item.notes.toLowerCase().contains(q);
    }).toList();
  }

  FollowUpsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    FollowUpCounts? counts,
    List<FollowUpModel>? allFollowUps,
    int? selectedTabIndex,
    String? searchQuery,
  }) {
    return FollowUpsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      counts: counts ?? this.counts,
      allFollowUps: allFollowUps ?? this.allFollowUps,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FollowUpsNotifier extends StateNotifier<FollowUpsState> {
  final FollowUpRepository _repository;

  FollowUpsNotifier(this._repository) : super(const FollowUpsState()) {
    loadFollowUps();
  }

  Future<void> loadFollowUps({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _repository.getFollowUps(
        tab: 'all',
        search: state.searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        clearError: true,
        counts: result.counts,
        allFollowUps: result.items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  Future<bool> createFollowUp({
    required String restaurantName,
    required String contactPerson,
    required String phone,
    required String address,
    required String type,
    required String priority,
    required DateTime scheduledTime,
    required String notes,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final data = {
        'restaurant_name': restaurantName,
        'contact_person': contactPerson,
        'phone': phone,
        'address': address,
        'follow_up_type': type,
        'priority': priority,
        'status': 'PENDING',
        'scheduled_time': scheduledTime.toIso8601String(),
        'notes': notes,
      };

      await _repository.createFollowUp(data);
      await loadFollowUps(showLoading: false);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> markAsCompleted(FollowUpModel item) async {
    // Optimistic update
    final updatedList = state.allFollowUps.map((f) {
      if (f.id == item.id) {
        return f.copyWith(status: 'COMPLETED');
      }
      return f;
    }).toList();

    // Compute updated counts
    int today = 0, upcoming = 0, overdue = 0, completed = 0;
    for (final f in updatedList) {
      if (f.status.toUpperCase() == 'COMPLETED') {
        completed++;
      } else {
        final status = f.computedStatus;
        if (status == FollowUpStatus.today) today++;
        if (status == FollowUpStatus.upcoming) upcoming++;
        if (status == FollowUpStatus.overdue) overdue++;
      }
    }

    state = state.copyWith(
      allFollowUps: updatedList,
      counts: FollowUpCounts(today: today, upcoming: upcoming, overdue: overdue, completed: completed),
    );

    try {
      await _repository.updateFollowUp(item.id, {'status': 'COMPLETED'});
      await loadFollowUps(showLoading: false);
      return true;
    } catch (e) {
      await loadFollowUps(showLoading: false);
      return false;
    }
  }

  Future<bool> rescheduleFollowUp(FollowUpModel item, DateTime newScheduledTime) async {
    // Optimistic update
    final updatedList = state.allFollowUps.map((f) {
      if (f.id == item.id) {
        return f.copyWith(scheduledTime: newScheduledTime, status: 'PENDING');
      }
      return f;
    }).toList();

    state = state.copyWith(allFollowUps: updatedList);

    try {
      await _repository.updateFollowUp(item.id, {
        'scheduled_time': newScheduledTime.toIso8601String(),
        'status': 'PENDING',
      });
      await loadFollowUps(showLoading: false);
      return true;
    } catch (e) {
      await loadFollowUps(showLoading: false);
      return false;
    }
  }

  Future<bool> deleteFollowUp(String id) async {
    try {
      await _repository.deleteFollowUp(id);
      await loadFollowUps(showLoading: false);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final followUpsProvider = StateNotifierProvider<FollowUpsNotifier, FollowUpsState>((ref) {
  final repository = ref.watch(followUpRepositoryProvider);
  return FollowUpsNotifier(repository);
});
