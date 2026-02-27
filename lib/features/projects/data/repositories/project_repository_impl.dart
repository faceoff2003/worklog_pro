import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/domain/repositories/project_repository.dart';

// Provider moved to projects_provider.dart

class ProjectRepositoryImpl implements ProjectRepository {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  ProjectRepositoryImpl(this.userId);

  CollectionReference<Map<String, dynamic>> _projectsCollection() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects');
  }

  @override
  Stream<List<Project>> watchProjects({String? clientId}) {
    Query<Map<String, dynamic>> query = _projectsCollection()
        .orderBy('label'); // Order by name (label) by default

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          // Add ID to JSON if missing (it should be in the doc data, but safety first)
          final data = doc.data();
          data['id'] = doc.id;
          return Project.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing project ${doc.id}: $e');
          // Return null here would break the list type, so we filter out invalid docs
          // But map needs to return Project. 
          // Rethrowing might break the stream.
          // Let's create a "safe" parsing and filter later if needed, 
          // or just fail for that item.
          // For now, rethrow to see errors in dev.
          rethrow;
        }
      }).toList();
    });
  }

  @override
  Stream<Project?> watchProject(String id) {
    return _projectsCollection().doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Project.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing project $id: $e');
        return null;
      }
    });
  }

  @override
  Future<List<Project>> getProjects({String? clientId}) async {
    Query<Map<String, dynamic>> query = _projectsCollection().orderBy('label');

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Project.fromJson(data);
    }).toList();
  }

  @override
  Future<Project?> getProject(String id) async {
    final doc = await _projectsCollection().doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Project.fromJson(data);
  }

  @override
  Future<Project> createProject(Project project) async {
    final now = DateTime.now();
    final projectId = _uuid.v4();

    final projectWithTimestamps = project.copyWith(
      id: projectId,
      createdAt: now,
      updatedAt: now,
    );

    final json = projectWithTimestamps.toJson();
    // Remove id from JSON (it's the document ID)
    json.remove('id');

    await _projectsCollection().doc(projectId).set(json);

    return projectWithTimestamps;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final now = DateTime.now();
    
    final projectToUpdate = project.copyWith(
      updatedAt: now,
    );

    final json = projectToUpdate.toJson();
    json.remove('id');
    // Remove createdAt to avoid overwriting it if it wasn't passed correctly (though it should be)
    // Actually, set/update behavior:
    // If we use set(json), we overwrite everything. 
    // If we want to preserve createdAt, we should ensure project.createdAt is correct.
    // In update, usually we just update fields passed. 
    // But here we pass full object.
    
    // Firestore security rules ensure createdAt is unchanged.
    // But let's be safe and use update() instead of set()
    
    await _projectsCollection().doc(project.id).update(json);

    return projectToUpdate;
  }

  @override
  Future<void> deleteProject(String id) async {
    await _projectsCollection().doc(id).delete();
  }

  @override
  Future<List<Project>> searchProjectsByLabel(String query) async {
    final snapshot = await _projectsCollection()
        .where('label', isGreaterThanOrEqualTo: query)
        .where('label', isLessThan: '${query}z')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Project.fromJson(data);
    }).toList();
  }
}
