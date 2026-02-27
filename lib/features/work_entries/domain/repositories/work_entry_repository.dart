import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

abstract class WorkEntryRepository {
  /// Watch work entries with optional filters
  Stream<List<WorkEntry>> watchWorkEntries({
    DateOnly? from, 
    DateOnly? to, 
    String? clientId, 
    String? projectId
  });

  /// Get work entries with optional filters (one-time fetch)
  Future<List<WorkEntry>> getWorkEntries({
    DateOnly? from, 
    DateOnly? to, 
    String? clientId, 
    String? projectId
  });

  /// Get a single work entry by ID
  Future<WorkEntry?> getWorkEntry(String id);

  /// Create a new work entry
  Future<WorkEntry> createWorkEntry(WorkEntry workEntry);

  /// Update an existing work entry
  Future<WorkEntry> updateWorkEntry(WorkEntry workEntry);

  /// Delete a work entry
  Future<void> deleteWorkEntry(String id);
}
