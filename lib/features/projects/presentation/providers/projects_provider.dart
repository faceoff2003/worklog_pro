import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/projects/data/repositories/project_repository_impl.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/domain/repositories/project_repository.dart';

// Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  
  if (user == null) {
    throw Exception('User must be authenticated to access projects');
  }
  
  return ProjectRepositoryImpl(user.uid);
});

// Stream of all projects
final projectsStreamProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});

// Stream of projects by client
final projectsByClientStreamProvider = StreamProvider.family.autoDispose<List<Project>, String>((ref, clientId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects(clientId: clientId);
});

// Stream of a single project
final projectStreamProvider = StreamProvider.family.autoDispose<Project?, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProject(projectId);
});

// Controller for Project CRUD operations
class ProjectsController extends StateNotifier<AsyncValue<void>> {
  final ProjectRepository _repository;

  ProjectsController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.createProject(project));
  }

  Future<void> updateProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProject(project));
  }

  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteProject(projectId));
  }
}

final projectsControllerProvider = StateNotifierProvider<ProjectsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectsController(repository);
});
