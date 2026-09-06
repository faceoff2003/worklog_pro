import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/core/constants/enums.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  final Payment? payment;
  final String? clientId;

  const PaymentFormPage({super.key, this.payment, this.clientId});

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  
  String? _selectedClientId;
  String? _selectedProjectId;
  late DateTime _selectedDate;
  PaymentMethod _selectedMethod = PaymentMethod.virement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.payment?.clientId ?? widget.clientId;
    _selectedProjectId = widget.payment?.projectId; 
    _selectedDate = widget.payment?.date.toDateTime() ?? DateTime.now();
    _selectedMethod = widget.payment?.method ?? PaymentMethod.virement;
    
    _amountController = TextEditingController(
      text: widget.payment?.amount.inEuros.toString() ?? '',
    );
    _noteController = TextEditingController(text: widget.payment?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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

    setState(() => _isLoading = true);

    try {
      final amountValue = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final amount = Money.fromEuros(amountValue);

      final payment = Payment(
        id: widget.payment?.id ?? const Uuid().v4(),
        clientId: _selectedClientId!,
        projectId: _selectedProjectId,
        date: DateOnly.fromDateTime(_selectedDate),
        amount: amount,
        method: _selectedMethod,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        createdAt: widget.payment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(paymentsControllerProvider.notifier);
      
      if (widget.payment == null) {
        await controller.createPayment(payment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement enregistré'), backgroundColor: Colors.green),
          );
        }
      } else {
        await controller.updatePayment(payment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement mis à jour'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce paiement ?'),
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

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(paymentsControllerProvider.notifier).deletePayment(widget.payment!.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement supprimé'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment == null ? 'Nouveau Paiement' : 'Modifier Paiement'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (widget.payment != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.clientId == null)
              clientsAsync.when(
                data: (clients) => DropdownButtonFormField<String>(
                  initialValue: _selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: clients.map((client) {
                    return DropdownMenuItem(
                      value: client.id,
                      child: Text(client.name),
                    );
                  }).toList(),
                  onChanged: widget.payment == null
                      ? (value) => setState(() {
                           _selectedClientId = value;
                           _selectedProjectId = null;
                        })
                      : null, 
                  validator: (value) => value == null ? 'Requis' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Erreur: $e'),
              ),

            const SizedBox(height: 16),

            // Project Selector (Optional)
            if (_selectedClientId != null)
              Consumer(
                builder: (context, ref, child) {
                  // We need the projects provider. 
                  // It seems not imported or defined in this file.
                  // We need to import it.
                  final projectsAsync = ref.watch(projectsByClientStreamProvider(_selectedClientId!));
                  
                  return projectsAsync.when(
                    data: (projects) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedProjectId,
                        decoration: const InputDecoration(
                          labelText: 'Chantier (Optionnel)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.construction),
                          helperText: 'Lier ce paiement à un chantier spécifique',
                        ),
                        items: [
                          const DropdownMenuItem(
                             value: null,
                             child: Text('Aucun / Général'),
                          ),
                          ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label))),
                        ],
                        onChanged: (value) => setState(() => _selectedProjectId = value),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_,__) => const SizedBox.shrink(),
                  );
                },
              ),

            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date du paiement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null) return 'Montant invalide';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Method
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Moyen de paiement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMethod = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENREGISTRER',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

