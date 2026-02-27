import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

class WorkEntryRepositoryImpl implements WorkEntryRepository {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  WorkEntryRepositoryImpl(this.userId);

  CollectionReference<Map<String, dynamic>> _workEntriesCollection() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workEntries');
  }

  @override
  Stream<List<WorkEntry>> watchWorkEntries({
    DateOnly? from, 
    DateOnly? to, 
    String? clientId, 
    String? projectId
  }) {
    Query<Map<String, dynamic>> query = _workEntriesCollection()
        .orderBy('date', descending: true)
        .orderBy('startTime');

    if (from != null) {
      // String comparison for YYYY-MM-DD works
      query = query.where('date', isGreaterThanOrEqualTo: from.toJson());
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: to.toJson());
    }
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return WorkEntry.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing work entry ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    });
  }

  @override
  Future<List<WorkEntry>> getWorkEntries({
    DateOnly? from, 
    DateOnly? to, 
    String? clientId, 
    String? projectId
  }) async {
    Query<Map<String, dynamic>> query = _workEntriesCollection()
        .orderBy('date', descending: true)
        .orderBy('startTime');

    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: from.toJson());
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: to.toJson());
    }
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return WorkEntry.fromJson(data);
    }).toList();
  }

  @override
  Future<WorkEntry?> getWorkEntry(String id) async {
    final doc = await _workEntriesCollection().doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return WorkEntry.fromJson(data);
  }

  @override
  Future<WorkEntry> createWorkEntry(WorkEntry workEntry) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final entryWithMeta = workEntry.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    final json = entryWithMeta.toJson();
    json.remove('id');

    await _workEntriesCollection().doc(id).set(json);

    return entryWithMeta;
  }

  @override
  Future<WorkEntry> updateWorkEntry(WorkEntry workEntry) async {
    final now = DateTime.now();
    
    final entryToUpdate = workEntry.copyWith(
      updatedAt: now,
    );

    final json = entryToUpdate.toJson();
    json.remove('id');
    
    await _workEntriesCollection().doc(workEntry.id).update(json);

    return entryToUpdate;
  }

  @override
  Future<void> deleteWorkEntry(String id) async {
    await _workEntriesCollection().doc(id).delete();
  }
}
