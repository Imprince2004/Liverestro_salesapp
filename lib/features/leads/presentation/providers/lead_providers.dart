import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lead_model.dart';
import '../../domain/repositories/lead_repository.dart';

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepository();
});

class LeadListNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  final LeadRepository _repository;

  LeadListNotifier(this._repository) : super(const AsyncValue.loading()) {
    // 1. Eagerly populate from Hive cache (0ms instant startup display)
    final cached = _repository.getCachedLeads();
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }
    loadLeads();
  }

  Future<void> loadLeads() async {
    try {
      final cached = _repository.getCachedLeads();
      if (cached.isNotEmpty && (state.value == null || state.value!.isEmpty)) {
        state = AsyncValue.data(cached);
      } else if (state.value == null) {
        state = const AsyncValue.loading();
      }

      final fresh = await _repository.getLeads();
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addLead(LeadModel lead) async {
    try {
      await _repository.addLead(lead);
      final currentLeads = state.value ?? [];
      state = AsyncValue.data([lead, ...currentLeads]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void filterLeads(String query, String filter) {
    // Instant zero-latency in-memory filter on cached/loaded data
    final allLeads = _repository.getCachedLeads();
    final cleanQuery = query.toLowerCase().trim();
    final cleanFilter = filter.toLowerCase().trim();

    final filtered = allLeads.where((lead) {
      final matchesQuery = cleanQuery.isEmpty ||
          lead.id.toLowerCase().contains(cleanQuery) ||
          lead.restaurantName.toLowerCase().contains(cleanQuery) ||
          lead.contactPersonName.toLowerCase().contains(cleanQuery) ||
          lead.ownerName.toLowerCase().contains(cleanQuery) ||
          lead.mobile.replaceAll(RegExp(r'[^0-9]'), '').contains(cleanQuery.replaceAll(RegExp(r'[^0-9]'), '')) ||
          lead.city.toLowerCase().contains(cleanQuery) ||
          lead.area.toLowerCase().contains(cleanQuery) ||
          lead.cuisine.toLowerCase().contains(cleanQuery);

      bool matchesFilter = true;
      if (cleanFilter != 'all' && cleanFilter.isNotEmpty) {
        final statusLower = lead.status.toLowerCase();
        final priorityLower = lead.priority.toLowerCase();

        if (cleanFilter == 'new') {
          matchesFilter = statusLower.contains('new');
        } else if (cleanFilter == 'qualified') {
          matchesFilter = statusLower.contains('qualified') || statusLower.contains('interest');
        } else if (cleanFilter == 'proposal') {
          matchesFilter = statusLower.contains('proposal') || statusLower.contains('demo');
        } else if (cleanFilter == 'negotiation') {
          matchesFilter = statusLower.contains('negotiat') || statusLower.contains('discussion');
        } else if (cleanFilter == 'won') {
          matchesFilter = statusLower.contains('won') || statusLower.contains('convert') || statusLower.contains('close');
        } else if (cleanFilter == 'high priority') {
          matchesFilter = priorityLower == 'high' || priorityLower == 'urgent';
        } else {
          matchesFilter = statusLower.contains(cleanFilter) || priorityLower.contains(cleanFilter);
        }
      }

      return matchesQuery && matchesFilter;
    }).toList();
    state = AsyncValue.data(filtered);
  }
}

final leadListProvider =
    StateNotifierProvider<LeadListNotifier, AsyncValue<List<LeadModel>>>((ref) {
  final repo = ref.watch(leadRepositoryProvider);
  return LeadListNotifier(repo);
});
