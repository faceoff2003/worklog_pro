import 'package:worklog_pro/features/projects/domain/entities/project.dart';

abstract class ProjectRepository {
  Stream<List<Project>> watchProjects({String? clientId});
  Stream<Project?> watchProject(String id);
  Future<List<Project>> getProjects({String? clientId});
  Future<Project?> getProject(String id);
  Future<Project> createProject(Project project);
  Future<Project> updateProject(Project project);
  Future<void> deleteProject(String id);
  Future<List<Project>> searchProjectsByLabel(String query);
}
