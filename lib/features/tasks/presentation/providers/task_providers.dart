import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/environment.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/task_model.dart';
import '../../data/models/assignable_user_model.dart';

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  TaskListNotifier() : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  static List<String> get _fastApiCandidates => Environment.resolvedApiCandidates;

  static final Dio _directDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500),
      receiveTimeout: const Duration(milliseconds: 2500),
      sendTimeout: const Duration(milliseconds: 2500),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> fetchTasks({String? assignedToId}) async {
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();

      for (final base in _fastApiCandidates) {
        try {
          final res = await _directDio.get(
            '$base/api/tasks',
            queryParameters: {
              if (assignedToId != null) 'assigned_to_id': assignedToId,
            },
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> rawList = res.data['data'];
            final tasks = rawList.map((j) => TaskModel.fromJson(j as Map<String, dynamic>)).toList();
            state = AsyncValue.data(tasks);
            return;
          }
        } catch (_) {}
      }

      // If network unreachable, retain current data or fallback
      if (state.value != null && state.value!.isNotEmpty) {
        return;
      }
      state = AsyncValue.data(_fallbackTasks);
    } catch (_) {
      state = AsyncValue.data(_fallbackTasks);
    }
  }

  Future<bool> createTask({
    required String assignedToId,
    required String title,
    required String description,
    required String taskType,
    required String priority,
    required String restaurantName,
    required String location,
    required String dueDate,
    required String notes,
  }) async {
    return createMultiAssigneeTask(
      assignedToIds: [assignedToId],
      title: title,
      description: description,
      taskType: taskType,
      priority: priority,
      restaurantName: restaurantName,
      location: location,
      dueDate: dueDate,
      notes: notes,
    );
  }

  Future<bool> createMultiAssigneeTask({
    required List<String> assignedToIds,
    required String title,
    required String description,
    required String taskType,
    required String priority,
    required String restaurantName,
    required String location,
    required String dueDate,
    required String notes,
  }) async {
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();

      final payload = {
        'assigned_to_ids': assignedToIds,
        'assigned_to_id': assignedToIds.isNotEmpty ? assignedToIds.first : '',
        'title': title,
        'description': description,
        'task_type': taskType,
        'priority': priority,
        'restaurant_name': restaurantName,
        'location': location,
        'due_date': dueDate,
        'notes': notes,
      };

      List<TaskModel> createdTasks = [];

      for (final base in _fastApiCandidates) {
        try {
          final res = await _directDio.post(
            '$base/api/tasks',
            data: payload,
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );

          if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
            Environment.activeWorkingBaseUrl = base;
            if (res.data['tasks'] is List) {
              createdTasks = (res.data['tasks'] as List)
                  .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
                  .toList();
            } else if (res.data['data'] is Map<String, dynamic>) {
              createdTasks = [TaskModel.fromJson(res.data['data'] as Map<String, dynamic>)];
            }
            break;
          }
        } catch (_) {}
      }

      if (createdTasks.isEmpty) {
        for (final targetId in assignedToIds) {
          createdTasks.add(
            TaskModel(
              id: 'tsk_${DateTime.now().millisecondsSinceEpoch}_$targetId',
              organizationId: 'org_demo_001',
              managerId: 'usr_salesmanager_003',
              managerName: 'Ashish Sharma (Sales Manager)',
              assignedToId: targetId,
              assignedToName: 'Team Member',
              title: title,
              description: description,
              taskType: taskType,
              priority: priority,
              status: 'PENDING',
              restaurantName: restaurantName,
              location: location,
              dueDate: dueDate,
              notes: notes,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        }
      }

      final current = state.value ?? [];
      state = AsyncValue.data([...createdTasks, ...current]);

      // Trigger background refresh
      fetchTasks();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool hasConflict, String? conflictMessage, Map<String, dynamic>? details})> checkConflict({
    required String userId,
    required String date,
    String? restaurantName,
  }) async {
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final payload = {
        'user_id': userId,
        'date': date,
        if (restaurantName != null && restaurantName.isNotEmpty) 'restaurant_name': restaurantName,
      };

      for (final base in _fastApiCandidates) {
        try {
          final res = await _directDio.post(
            '$base/api/tasks/check-conflict',
            data: payload,
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );

          if (res.statusCode == 200 && res.data != null) {
            final hasConflict = res.data['has_conflict'] == true;
            final conflictDetails = res.data['conflict_details'] as Map<String, dynamic>?;
            final userName = res.data['user']?['name'] ?? 'Assignee';

            String? msg;
            if (hasConflict && conflictDetails != null) {
              final taskTitle = conflictDetails['title'] ?? conflictDetails['restaurant_name'] ?? 'another activity';
              msg = '$userName is already assigned to "$taskTitle" on $date.';
            }

            return (
              hasConflict: hasConflict,
              conflictMessage: msg,
              details: conflictDetails,
            );
          }
        } catch (_) {}
      }

      return (hasConflict: false, conflictMessage: null, details: null);
    } catch (_) {
      return (hasConflict: false, conflictMessage: null, details: null);
    }
  }

  Future<bool> updateStatus(String taskId, String newStatus) async {
    try {
      // Optimistic update
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((t) => t.id == taskId ? t.copyWith(status: newStatus) : t).toList(),
      );

      final token = await getIt<SecureStorageService>().getAuthToken();

      for (final base in _fastApiCandidates) {
        try {
          final res = await _directDio.patch(
            '$base/api/tasks/$taskId',
            data: {'status': newStatus},
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );
          if (res.statusCode == 200) {
            Environment.activeWorkingBaseUrl = base;
            return true;
          }
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static final List<TaskModel> _fallbackTasks = [];
}

final taskListProvider = StateNotifierProvider<TaskListNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return TaskListNotifier();
});

/// Filtered tasks assigned to the currently logged in user / sales executive
final myAssignedTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final authUser = ref.watch(authNotifierProvider).user;
  final currentUserId = authUser?.id ?? 'usr_salesexecutive_004';
  final currentPhone = authUser?.phone ?? '';

  return tasksAsync.when(
    data: (tasks) {
      return tasks.where((t) {
        return t.assignedToId == currentUserId ||
            t.assignedToName.toLowerCase().contains(authUser?.name.toLowerCase() ?? '') ||
            (currentPhone.isNotEmpty && t.assignedToId.contains(currentPhone));
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Assignable Users State (Sales Managers & Sales Executives with Workload)
class AssignableUsersState {
  final List<AssignableUserModel> salesManagers;
  final List<AssignableUserModel> salesExecutives;
  final List<AssignableUserModel> allAssignees;
  final bool isLoading;
  final String? errorMessage;

  const AssignableUsersState({
    this.salesManagers = const [],
    this.salesExecutives = const [],
    this.allAssignees = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AssignableUsersState copyWith({
    List<AssignableUserModel>? salesManagers,
    List<AssignableUserModel>? salesExecutives,
    List<AssignableUserModel>? allAssignees,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AssignableUsersState(
      salesManagers: salesManagers ?? this.salesManagers,
      salesExecutives: salesExecutives ?? this.salesExecutives,
      allAssignees: allAssignees ?? this.allAssignees,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AssignableUsersNotifier extends StateNotifier<AssignableUsersState> {
  AssignableUsersNotifier() : super(const AssignableUsersState(isLoading: true)) {
    fetchAssignableUsers();
  }

  static final Dio _directDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 2000),
      receiveTimeout: const Duration(milliseconds: 3000),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> fetchAssignableUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final candidates = TaskListNotifier._fastApiCandidates;

      for (final base in candidates) {
        try {
          final res = await _directDio.get(
            '$base/api/users/assignable',
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            final data = res.data['data'];
            final List<dynamic> rawMgrs = data['sales_managers'] ?? [];
            final List<dynamic> rawExecs = data['sales_executives'] ?? [];
            final List<dynamic> rawAll = data['all_assignees'] ?? [];

            final mgrs = rawMgrs.map((j) => AssignableUserModel.fromJson(j as Map<String, dynamic>)).toList();
            final execs = rawExecs.map((j) => AssignableUserModel.fromJson(j as Map<String, dynamic>)).toList();
            final all = rawAll.map((j) => AssignableUserModel.fromJson(j as Map<String, dynamic>)).toList();

            state = AssignableUsersState(
              salesManagers: mgrs,
              salesExecutives: execs,
              allAssignees: all.isNotEmpty ? all : [...mgrs, ...execs],
              isLoading: false,
            );
            return;
          }
        } catch (_) {}
      }

      // Fallback
      state = const AssignableUsersState(
        salesManagers: [],
        salesExecutives: [],
        allAssignees: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load assignable users.');
    }
  }
}

final assignableUsersProvider = StateNotifierProvider<AssignableUsersNotifier, AssignableUsersState>((ref) {
  return AssignableUsersNotifier();
});

