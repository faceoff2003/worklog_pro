import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/pages/projects_list_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entries_list_page.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expenses_list_page.dart';
import 'package:worklog_pro/features/payments/presentation/pages/payments_list_page.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  final Client? client; // null for create, non-null for edit

  const ClientFormPage({super.key, this.client});

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late final TextEditingController _rateHourController;
  late final TextEditingController _rateHalfDayController;
  late final TextEditingController _rateDayController;
  late final TextEditingController _rateFixedJobController;
  
  late ClientType _selectedType;
  late List<String> _tags;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    
    final client = widget.client;
    
    _nameController = TextEditingController(text: client?.name ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
    
    _rateHourController = TextEditingController(
      text: client?.defaultRates.hour?.inEuros.toString() ?? '',
    );
    _rateHalfDayController = TextEditingController(
      text: client?.defaultRates.halfDay?.inEuros.toString() ?? '',
    );
    _rateDayController = TextEditingController(
      text: client?.defaultRates.day?.inEuros.toString() ?? '',
    );
    _rateFixedJobController = TextEditingController(
      text: client?.defaultRates.fixedJob?.inEuros.toString() ?? '',
    );
    
    _selectedType = client?.type ?? ClientType.patron;
    _tags = List.from(client?.tags ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _rateHourController.dispose();
    _rateHalfDayController.dispose();
    _rateDayController.dispose();
    _rateFixedJobController.dispose();
    super.dispose();
  }

  Money? _parseMoneyFromEuros(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final euros = double.parse(text.trim().replaceAll(',', '.'));
      return Money.fromEuros(euros);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(clientsControllerProvider.notifier);

    final client = Client(
      id: widget.client?.id ?? '', // Will be replaced in repository for new clients
      name: _nameController.text.trim(),
      type: _selectedType,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      defaultRates: DefaultRates(
        hour: _parseMoneyFromEuros(_rateHourController.text),
        halfDay: _parseMoneyFromEuros(_rateHalfDayController.text),
        day: _parseMoneyFromEuros(_rateDayController.text),
        fixedJob: _parseMoneyFromEuros(_rateFixedJobController.text),
      ),
      tags: _tags,
      createdAt: widget.client?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      await controller.updateClient(client);
    } else {
      await controller.createClient(client);
    }

    // Check for errors
    final state = ref.read(clientsControllerProvider);
    if (mounted && !state.hasError) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Client modifié' : 'Client créé',
          ),
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

  Future<void> _deleteClient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: const Text(
          'Cette action est irréversible. Le client et toutes ses données seront supprimés.',
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

    final controller = ref.read(clientsControllerProvider.notifier);
    await controller.deleteClient(widget.client!.id);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client supprimé'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Client' : 'Nouveau Client'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.construction),
              tooltip: 'Voir les chantiers',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProjectsListPage(clientId: widget.client!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.access_time_filled),
              tooltip: 'Voir les prestations',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkEntriesListPage(clientId: widget.client!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Voir les dépenses',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExpensesListPage(clientId: widget.client!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.euro),
              tooltip: 'Voir les paiements',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaymentsListPage(clientId: widget.client!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: clientState.isLoading ? null : _deleteClient,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing)
                _ClientBalanceCard(clientId: widget.client!.id),
              if (_isEditing)
                const SizedBox(height: 24),
              
              // Basic Info Section
              const Text(
                'Informations de base',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Nom du client ou patron',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<ClientType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ClientType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+32 123 45 67 89',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'email@exemple.com',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tarifs Section
              const Text(
                'Tarifs par défaut (€)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateHourController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tarif horaire',
                        hintText: '25.00',
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rateHalfDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Demi-journée',
                        hintText: '100.00',
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Journée',
                        hintText: '200.00',
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rateFixedJobController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Forfait',
                        hintText: '500.00',
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes Section
              const Text(
                'Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Remarques',
                  hintText: 'Notes internes...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: clientState.isLoading ? null : _saveClient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: clientState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Enregistrer' : 'Créer le client',
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

class _ClientBalanceCard extends ConsumerWidget {
  final String clientId;

  const _ClientBalanceCard({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(clientBalanceProvider(clientId));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: balanceAsync.when(
          data: (balance) {
            final isOwed = balance.balance.amountCents > 0;
            final isSettled = balance.balance.amountCents == 0;
            
            Color statusColor;
            String statusText;
            
            if (isSettled) {
              statusColor = Colors.green;
              statusText = 'Soldé';
            } else if (isOwed) {
              statusColor = Colors.orange;
              statusText = 'À Payer';
            } else {
              statusColor = Colors.blue;
              statusText = 'Créditeur'; // Overpaid
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'État du compte',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildRow('Prestations', balance.totalWork, Colors.black87),
                const SizedBox(height: 8),
                _buildRow('Dépenses', balance.totalExpenses, Colors.black87),
                const SizedBox(height: 8),
                _buildRow('Paiements reçus', balance.totalPayments, Colors.green),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Solde',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      balance.balance.toEurosString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildRow(String label, Money amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          amount.toEurosString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}


