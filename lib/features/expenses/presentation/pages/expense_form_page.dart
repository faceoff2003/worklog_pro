import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  final Expense? expense;
  final String? initialClientId;
  final String? initialProjectId;

  const ExpenseFormPage({
    super.key,
    this.expense,
    this.initialClientId,
    this.initialProjectId,
  });

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  late DateOnly _date;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late TextEditingController _distanceController;

  String? _selectedClientId;
  String? _selectedProjectId;
  ExpenseCategory _category = ExpenseCategory.materials;
  bool _isBillable = true;

  // Optional details
  MaterialCategory? _materialCategory;
  TravelMode? _travelMode;

  bool get _isEditing => widget.expense != null && widget.expense!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    _date = expense?.date ?? DateOnly.today();
    _descriptionController = TextEditingController(text: expense?.description ?? '');
    _amountController = TextEditingController(text: expense?.amountHT.inEuros.toString() ?? '');
    _vendorController = TextEditingController(text: expense?.vendor ?? '');
    _distanceController = TextEditingController(text: expense?.travelDistanceKm?.toString() ?? '');

    _selectedClientId = expense?.clientId ?? widget.initialClientId;
    _selectedProjectId = expense?.projectId ?? widget.initialProjectId;
    
    // Sanitize empty strings
    if (_selectedClientId != null && _selectedClientId!.isEmpty) _selectedClientId = null;
    if (_selectedProjectId != null && _selectedProjectId!.isEmpty) _selectedProjectId = null;

    if (expense != null) {
      _category = expense.category;
      _isBillable = expense.isBillable;
      _materialCategory = expense.materialCategory;
      _travelMode = expense.travelMode;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _date = DateOnly.fromDateTime(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    final amountValue = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final amountMoney = Money.fromEuros(amountValue);
    
    final distanceValue = double.tryParse(_distanceController.text.replaceAll(',', '.'));

    final expense = Expense(
      id: widget.expense?.id ?? '',
      date: _date,
      clientId: _selectedClientId!,
      projectId: _selectedProjectId,
      category: _category,
      amountHT: amountMoney,
      description: _descriptionController.text,
      vendor: _vendorController.text.isEmpty ? null : _vendorController.text,
      isBillable: _isBillable,
      materialCategory: _category == ExpenseCategory.materials ? _materialCategory : null,
      travelMode: _category == ExpenseCategory.travel ? _travelMode : null,
      travelDistanceKm: _category == ExpenseCategory.travel ? distanceValue : null,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = ref.read(expensesControllerProvider.notifier);
    
    try {
      if (_isEditing) {
        await controller.updateExpense(expense);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépense modifiée')));
      } else {
        await controller.createExpense(expense);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépense créée')));
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Dépense' : 'Nouvelle Dépense'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
            if (_isEditing)
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                        final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                                title: const Text('Supprimer ?'),
                                content: const Text('Cette action est irréversible.'),
                                actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                                ],
                            ),
                        );
                        
                        if (confirm == true) {
                            await ref.read(expensesControllerProvider.notifier).deleteExpense(widget.expense!.id);
                            if (context.mounted) Navigator.pop(context);
                        }
                    },
                ),
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
              // 1. Client & Project
              clientsAsync.when(
                data: (clients) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedClientId,
                    decoration: const InputDecoration(labelText: 'Client *', prefixIcon: Icon(Icons.person)),
                    items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClientId = value;
                        _selectedProjectId = null;
                      });
                    },
                    validator: (v) => v == null ? 'Requis' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 16),

              if (_selectedClientId != null)
                Consumer(
                  builder: (context, ref, child) {
                    final projectsAsync = ref.watch(projectsByClientStreamProvider(_selectedClientId!));
                    return projectsAsync.when(
                      data: (projects) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedProjectId,
                          decoration: const InputDecoration(labelText: 'Chantier', prefixIcon: Icon(Icons.construction)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Aucun / Général')),
                            ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
                          ],
                          onChanged: (value) => setState(() => _selectedProjectId = value),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 2. Date & Description
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(_date.formatEuropean()),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 24),

              // 3. Category & Details
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                items: ExpenseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              if (_category == ExpenseCategory.materials) ...[
                DropdownButtonFormField<MaterialCategory>(
                  initialValue: _materialCategory,
                  decoration: const InputDecoration(labelText: 'Type de Matériel'),
                  items: MaterialCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                  onChanged: (v) => setState(() => _materialCategory = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vendorController,
                  decoration: const InputDecoration(labelText: 'Fournisseur / Magasin', prefixIcon: Icon(Icons.store)),
                ),
              ],

              if (_category == ExpenseCategory.travel) ...[
                DropdownButtonFormField<TravelMode>(
                  initialValue: _travelMode,
                  decoration: const InputDecoration(labelText: 'Mode de Déplacement'),
                  items: TravelMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                  onChanged: (v) => setState(() => _travelMode = v),
                ),
                const SizedBox(height: 16),
                if (_travelMode == TravelMode.per_km)
                  TextFormField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Distance (km)', suffixText: 'km'),
                  ),
              ],

              const SizedBox(height: 24),

              // 4. Amount & Billing
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Montant HT *', suffixText: '€', prefixIcon: Icon(Icons.euro)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Refacturable'),
                      subtitle: const Text('au client'),
                      value: _isBillable,
                      onChanged: (v) => setState(() => _isBillable = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isEditing ? 'Modifier' : 'Enregistrer', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

