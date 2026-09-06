import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/services/notification_service.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entries_list_page.dart';

class ProjectFormPage extends ConsumerStatefulWidget {
  final Project? project;
  final String? clientId; // Pre-select client if creating new

  const ProjectFormPage({super.key, this.project, this.clientId});

  @override
  ConsumerState<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends ConsumerState<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _zipController;
  late final TextEditingController _cityController;
  late final TextEditingController _notesController;
  late final TextEditingController _technicalNotesController;
  late final TextEditingController _accessNotesController;
  late final TextEditingController _distanceController;

  late ProjectType _selectedType;
  late ProjectStatus _selectedStatus = ProjectStatus.actif;
  String? _selectedClientId;
  DateTime? _reminderDate;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;

    _labelController = TextEditingController(text: project?.label ?? '');
    _streetController = TextEditingController(text: project?.address.street ?? '');
    _numberController = TextEditingController(text: project?.address.number ?? '');
    _zipController = TextEditingController(text: project?.address.zip ?? '');
    _cityController = TextEditingController(text: project?.address.city ?? '');
    _notesController = TextEditingController(text: project?.notes ?? '');
    _technicalNotesController = TextEditingController(text: project?.technicalNotes ?? '');
    _accessNotesController = TextEditingController(text: project?.accessNotes ?? '');
    _distanceController = TextEditingController(text: project?.distanceKm?.toString() ?? '');

    _selectedType = project?.type ?? ProjectType.nouvelle_installation;
    _selectedStatus = project?.status ?? ProjectStatus.actif;
    _selectedClientId = project?.clientId ?? widget.clientId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _technicalNotesController.dispose();
    _accessNotesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    final controller = ref.read(projectsControllerProvider.notifier);

    final project = Project(
      id: widget.project?.id ?? '',
      clientId: _selectedClientId!,
      label: _labelController.text.trim(),
      type: _selectedType,
      status: _selectedStatus,
      address: Address(
        street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        number: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
        zip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: 'Belgique',
      ),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      technicalNotes: _technicalNotesController.text.trim().isEmpty ? null : _technicalNotesController.text.trim(),
      accessNotes: _accessNotesController.text.trim().isEmpty ? null : _accessNotesController.text.trim(),
      distanceKm: double.tryParse(_distanceController.text.trim().replaceAll(',', '.')),
      createdAt: widget.project?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      await controller.updateProject(project);
    } else {
      await controller.createProject(project);
    }

    final state = ref.read(projectsControllerProvider);
    if (mounted && !state.hasError) {
      // Schedule reminder if selected
      if (_reminderDate != null) {
        final notifId = project.id.isNotEmpty ? project.id.hashCode : DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await ref.read(notificationServiceProvider).scheduleReminder(
          id: notifId,
          title: 'Rappel Chantier',
          body: 'Chantier : ${project.label} à venir !',
          scheduledDate: _reminderDate!,
        );
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Chantier modifié' : 'Chantier créé'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${state.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce chantier ?'),
        content: const Text(
          'Cette action est irréversible. Toutes les données associées seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(projectsControllerProvider.notifier);
    await controller.deleteProject(widget.project!.id);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chantier supprimé'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsControllerProvider);
    final clientsAsync = widget.clientId == null
        ? ref.watch(clientsStreamProvider)
        : const AsyncValue<List<Client>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Chantier' : 'Nouveau Chantier'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.access_time_filled),
              tooltip: 'Voir les prestations',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkEntriesListPage(projectId: widget.project!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: projectsState.isLoading ? null : _deleteProject,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Client Selection (only if not pre-defined)
                if (widget.clientId == null) ...[
                  clientsAsync.when(
                    data: (clients) {
                      final sortedClients = List<Client>.from(clients)
                        ..sort((a, b) => a.name.compareTo(b.name));
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedClientId,
                        decoration: const InputDecoration(
                          labelText: 'Client *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: sortedClients.map((client) {
                          return DropdownMenuItem(
                            value: client.id,
                            child: Text(client.name),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedClientId = value;
                                });
                              },
                        validator: (value) => value == null ? 'Sélectionnez un client' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, stack) => Text('Erreur chargement clients: $e'),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du chantier *',
                    hintText: 'Ex: Rénovation cuisine',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ProjectType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de travaux',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ProjectType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.displayName));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ProjectStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status.displayName));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'Adresse du chantier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _streetController,
                        decoration: const InputDecoration(
                          labelText: 'Rue',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(labelText: 'N°'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _zipController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Code postal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Ville'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Distance aller simple (km)',
                    hintText: 'Distance entre le dépôt et le chantier',
                    prefixIcon: Icon(Icons.directions_car),
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Notes et détails',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes générales',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _technicalNotesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes techniques',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.build),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _accessNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Accès (code, clés...)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.alarm, color: Colors.orange),
                    title: const Text('Rappel'),
                    subtitle: Text(
                      _reminderDate == null
                          ? 'Aucun rappel programmé'
                          : 'Le ${_reminderDate!.day.toString().padLeft(2, '0')}/${_reminderDate!.month.toString().padLeft(2, '0')}/${_reminderDate!.year} à ${_reminderDate!.hour.toString().padLeft(2, '0')}h${_reminderDate!.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: _reminderDate != null
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _reminderDate = null),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      // Request notification permission first
                      await ref.read(notificationServiceProvider).requestPermission();
                      if (!mounted) return;

                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (date == null || !mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time == null || !mounted) return;
                      setState(() {
                        _reminderDate = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: projectsState.isLoading ? null : _saveProject,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: projectsState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Enregistrer les modifications' : 'Créer le chantier',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
