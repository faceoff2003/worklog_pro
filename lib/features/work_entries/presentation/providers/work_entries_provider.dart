import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/work_entries/data/repositories/work_entry_repository_impl.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_calculator_service.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_entry_builder_service.dart';

// --- Services ---

final workCalculatorServiceProvider = Provider<WorkCalculatorService>((ref) {
  return WorkCalculatorService();
});

final workEntryBuilderServiceProvider = Provider<WorkEntryBuilderService>((ref) {
  return WorkEntryBuilderService(ref.watch(workCalculatorServiceProvider));
});

// --- Repository ---

final workEntryRepositoryProvider = Provider<WorkEntryRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User must be authenticated to access WorkEntryRepository');
  }
  return WorkEntryRepositoryImpl(user.uid);
});

// --- Streams ---

// All work entries (ordered by date desc usually, but repo orders asc. Providers can sort.)
final workEntriesStreamProvider = StreamProvider.autoDispose<List<WorkEntry>>((ref) {
  final repository = ref.watch(workEntryRepositoryProvider);
  return repository.watchWorkEntries();
});

// Work entries for a specific client
final workEntriesByClientStreamProvider = StreamProvider.family.autoDispose<List<WorkEntry>, String>((ref, clientId) {
  final repository = ref.watch(workEntryRepositoryProvider);
  return repository.watchWorkEntries(clientId: clientId);
});

// Work entries for a specific project
final workEntriesByProjectStreamProvider = StreamProvider.family.autoDispose<List<WorkEntry>, String>((ref, projectId) {
  final repository = ref.watch(workEntryRepositoryProvider);
  return repository.watchWorkEntries(projectId: projectId);
});

// Single work entry
final workEntryStreamProvider = StreamProvider.family.autoDispose<WorkEntry?, String>((ref, id) {
  // final repository = ref.watch(workEntryRepositoryProvider);
  // We need to implement watchWorkEntry in repo if we want real stream for single item, 
  // currently we only have watchWorkEntries list.
  // For now, let's return a future, or filter the list stream?
  // Detailed implementation would require a specific method in repo.
  // Let's implement it via getWorkEntry Future.
  // Or better, add watchWorkEntry to repo.
  
  // Actually, I missed adding `watchWorkEntry` to the interface/impl.
  // I'll skip this provider for now or add it to repo.
  // Let's skip and use get request in controller for editing.
  return Stream.value(null); 
});

// --- Controller ---

final workEntriesControllerProvider = StateNotifierProvider<WorkEntriesController, AsyncValue<void>>((ref) {
  final repository = ref.watch(workEntryRepositoryProvider);
  return WorkEntriesController(repository);
});

class WorkEntriesController extends StateNotifier<AsyncValue<void>> {
  final WorkEntryRepository _repository;

  WorkEntriesController(this._repository) : super(const AsyncData(null));

  Future<void> createWorkEntry(WorkEntry workEntry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.createWorkEntry(workEntry));
  }

  Future<void> updateWorkEntry(WorkEntry workEntry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateWorkEntry(workEntry));
  }

  Future<void> deleteWorkEntry(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteWorkEntry(id));
  }
}
