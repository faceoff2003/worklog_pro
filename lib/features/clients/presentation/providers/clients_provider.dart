import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/clients/data/repositories/client_repository_impl.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';

/// Provider for ClientRepository instance.
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl();
});

/// Provider for clients stream (real-time updates).
/// 
/// Watches all clients for the current user, ordered by name.
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.watchClients();
});

/// Provider for a single client stream.
/// 
/// Watches a specific client by ID with real-time updates.
final clientStreamProvider =
    StreamProvider.family<Client?, String>((ref, clientId) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.watchClient(clientId);
});

/// Controller for client CRUD operations.
class ClientsController extends StateNotifier<AsyncValue<void>> {
  final ClientRepository _repository;

  ClientsController(this._repository) : super(const AsyncValue.data(null));

  /// Create a new client.
  Future<void> createClient(Client client) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createClient(client);
    });
  }

  /// Update an existing client.
  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateClient(client);
    });
  }

  /// Delete a client.
  Future<void> deleteClient(String clientId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteClient(clientId);
    });
  }

  /// Search clients by name.
  Future<List<Client>> searchClients(String query) async {
    return await _repository.searchClientsByName(query);
  }
}

/// Provider for ClientsController.
final clientsControllerProvider =
    StateNotifierProvider<ClientsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(clientRepositoryProvider);
  return ClientsController(repository);
});
