import 'package:worklog_pro/features/clients/domain/entities/client.dart';

/// Repository interface for Client operations.
/// 
/// This defines the contract for client data access.
/// Implementation will use Cloud Firestore.
abstract class ClientRepository {
  /// Stream of all clients for the current user.
  /// Results are ordered by name.
  Stream<List<Client>> watchClients();

  /// Stream of a single client by ID.
  Stream<Client?> watchClient(String clientId);

  /// Get a single client by ID (one-time read).
  Future<Client?> getClient(String clientId);

  /// Get all clients (one-time read).
  Future<List<Client>> getClients();

  /// Create a new client.
  /// Returns the created client with generated ID.
  Future<Client> createClient(Client client);

  /// Update an existing client.
  Future<void> updateClient(Client client);

  /// Delete a client.
  /// 
  /// Warning: This should check for related data (projects, work entries)
  /// before deletion in a real app.
  Future<void> deleteClient(String clientId);

  /// Search clients by name.
  Future<List<Client>> searchClientsByName(String query);
}
