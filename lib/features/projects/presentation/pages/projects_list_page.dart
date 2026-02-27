import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/features/projects/presentation/pages/project_detail_page.dart';
import 'package:worklog_pro/features/projects/presentation/pages/project_form_page.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';

class ProjectsListPage extends ConsumerWidget {
  final String? clientId;

  const ProjectsListPage({super.key, this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which provider to use based on filter
    final projectsAsync = clientId != null 
        ? ref.watch(projectsByClientStreamProvider(clientId!))
        : ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chantiers'),
        backgroundColor: Colors.orange, // Different color for distinction
        foregroundColor: Colors.white,
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun chantier',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier chantier',
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
            itemCount: projects.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final project = projects[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade700,
                    child: const Icon(Icons.home_work),
                  ),
                  title: Text(
                    project.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        project.type.displayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.address.format(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(project.status).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(project.status).withAlpha(80)),
                        ),
                        child: Text(
                          project.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(project.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.orange.shade400, size: 20),
                        tooltip: 'Modifier',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProjectFormPage(project: project)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                        tooltip: 'Supprimer',
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmDialog(
                            context,
                            name: project.label,
                            type: 'le chantier',
                          );
                          if (confirmed == true) {
                            await ref.read(projectsControllerProvider.notifier).deleteProject(project.id);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailPage(project: project),
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
              builder: (context) => ProjectFormPage(clientId: clientId),
            ),
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.actif:
        return Colors.green;
      case ProjectStatus.termine:
        return Colors.grey;
      case ProjectStatus.en_attente:
        return Colors.orange;
    }
  }
}
