import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_detail_page.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_form_page.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';


class ClientsListPage extends ConsumerWidget {
  const ClientsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun client',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier client',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: clients.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final client = clients[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    foregroundColor: Colors.indigo.shade700,
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    client.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        client.type.displayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      if (client.phone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client.phone!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.indigo.shade400, size: 20),
                        tooltip: 'Modifier',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ClientFormPage(client: client)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                        tooltip: 'Supprimer',
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmDialog(
                            context,
                            name: client.name,
                            type: 'le client',
                          );
                          if (confirmed == true) {
                            await ref.read(clientsControllerProvider.notifier).deleteClient(client.id);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClientDetailPage(client: client),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ClientFormPage(),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
