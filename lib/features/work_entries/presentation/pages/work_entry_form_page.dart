import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class WorkEntryFormPage extends ConsumerStatefulWidget {
  final WorkEntry? workEntry;
  final String? initialClientId;
  final String? initialProjectId;

  const WorkEntryFormPage({
    super.key, 
    this.workEntry,
    this.initialClientId,
    this.initialProjectId,
  });

  @override
  ConsumerState<WorkEntryFormPage> createState() => _WorkEntryFormPageState();
}

class _WorkEntryFormPageState extends ConsumerState<WorkEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form State
  late DateOnly _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _pauseController;
  late TextEditingController _notesController;
  late TextEditingController _priceController;
  late TextEditingController _travelDistanceController;
  late TextEditingController _travelRateController;
  
  String? _selectedClientId;
  String? _selectedProjectId;
  late BillingMode _billingMode;
  
  // Calculated values
  int _durationMinutes = 0;
  
  bool get _isEditing => widget.workEntry != null && widget.workEntry!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final entry = widget.workEntry;
    
    _date = entry?.date ?? DateOnly.today();
    _startTime = entry != null 
        ? _minutesToTimeOfDay(entry.startTime) 
        : const TimeOfDay(hour: 8, minute: 0);
    _endTime = entry != null 
        ? _minutesToTimeOfDay(entry.endTime) 
        : const TimeOfDay(hour: 17, minute: 0);
        
    _pauseController = TextEditingController(text: entry?.pauseMinutes.toString() ?? '60');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    
    final initialPrice = entry?.laborAmountHT.inEuros ?? 0.0;
    _priceController = TextEditingController(text: initialPrice > 0 ? initialPrice.toStringAsFixed(2) : '0.00');
    
    _travelDistanceController = TextEditingController(text: entry?.travelDistanceKm.toString() ?? '0.0');
    _travelRateController = TextEditingController(text: entry?.travelRatePerKm.toString() ?? '0.20');
    
    final initialClientId = entry?.clientId ?? widget.initialClientId;
    _selectedClientId = (initialClientId != null && initialClientId.isNotEmpty) ? initialClientId : null;
    
    final initialProjectId = entry?.projectId ?? widget.initialProjectId;
    _selectedProjectId = (initialProjectId != null && initialProjectId.isNotEmpty) ? initialProjectId : null;
    
    _billingMode = entry?.billingMode ?? BillingMode.hourly;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculate(updatePrice: false);
    });
  }

  @override
  void dispose() {
    _pauseController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _travelDistanceController.dispose();
    _travelRateController.dispose();
    super.dispose();
  }

  // --- Helpers ---

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void _recalculate({bool updatePrice = true}) async {
    final calculator = ref.read(workCalculatorServiceProvider);
    
    final start = _timeOfDayToMinutes(_startTime);
    final end = _timeOfDayToMinutes(_endTime);
    final pause = int.tryParse(_pauseController.text) ?? 0;
    
    final duration = calculator.calculateDuration(start, end, pauseMinutes: pause);
    
    setState(() {
      _durationMinutes = duration;
    });

    if (updatePrice && _selectedClientId != null) {
        final clients = await ref.read(clientsStreamProvider.future);
        final client = clients.firstWhereOrNull((c) => c.id == _selectedClientId);
        if (client != null) {
          final calculatedCost = calculator.calculateLaborCost(
              durationMinutes: duration,
              mode: _billingMode,
              rates: client.defaultRates,
              roundingStep: 15
          );
          _priceController.text = calculatedCost.inEuros.toStringAsFixed(2);
        }
    }
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

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _recalculate();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _recalculate();
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
    
    final priceStr = _priceController.text.replaceAll(',', '.');
    final cost = Money.fromEuros(double.tryParse(priceStr) ?? 0.0);

    final calculator = ref.read(workCalculatorServiceProvider);
    final start = _timeOfDayToMinutes(_startTime);
    final end = _timeOfDayToMinutes(_endTime);
    final pause = int.tryParse(_pauseController.text) ?? 0;
    final duration = calculator.calculateDuration(start, end, pauseMinutes: pause);

    final clients = await ref.read(clientsStreamProvider.future);
    final client = clients.firstWhereOrNull((c) => c.id == _selectedClientId);
    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client introuvable. Veuillez re-sélectionner le client.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final tDist = double.tryParse(_travelDistanceController.text.replaceAll(',', '.')) ?? 0.0;
    final tRate = double.tryParse(_travelRateController.text.replaceAll(',', '.')) ?? 0.0;
    // Calculation is (Distance * 2 (Round trip)) * Rate
    final tAmount = Money.fromEuros((tDist * 2) * tRate);

    final workEntry = WorkEntry(
      id: widget.workEntry?.id ?? '',
      date: _date,
      startTime: start,
      endTime: end,
      pauseMinutes: pause,
      durationMinutes: duration,
      clientId: _selectedClientId!,
      projectId: _selectedProjectId,
      billingMode: _billingMode,
      rateApplied: cost,
      laborAmountHT: cost,
      travelDistanceKm: tDist,
      travelRatePerKm: tRate,
      travelAmountHT: tAmount,
      notes: _notesController.text,
      createdAt: widget.workEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ).copyWith(
        rateApplied: _getUnitRate(client.defaultRates, _billingMode)
    );

    final controller = ref.read(workEntriesControllerProvider.notifier);
    if (_isEditing) {
      await controller.updateWorkEntry(workEntry);
    } else {
      await controller.createWorkEntry(workEntry);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Money _getUnitRate(DefaultRates rates, BillingMode mode) {
    switch (mode) {
      case BillingMode.hourly: return rates.hour ?? Money.zero;
      case BillingMode.half_day: return rates.halfDay ?? Money.zero;
      case BillingMode.day: return rates.day ?? Money.zero;
      case BillingMode.fixed_job: return rates.fixedJob ?? Money.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Prestation' : 'Nouvelle Prestation'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
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
                    value: _selectedClientId,
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
                error: (e,s) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 16),
              
              if (_selectedClientId != null)
                Consumer(
                  builder: (context, ref, child) {
                    final projectsAsync = ref.watch(projectsByClientStreamProvider(_selectedClientId!));
                    return projectsAsync.when(
                      data: (projects) {
                        return DropdownButtonFormField<String>(
                          value: _selectedProjectId,
                          decoration: const InputDecoration(labelText: 'Chantier', prefixIcon: Icon(Icons.construction)),
                          items: [
                             const DropdownMenuItem(value: null, child: Text('Aucun / Général')),
                             ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
                          ],
                          onChanged: (value) {
                             setState(() => _selectedProjectId = value);
                             if (value != null) {
                               final proj = projects.firstWhereOrNull((p) => p.id == value);
                               if (proj?.distanceKm != null) {
                                 _travelDistanceController.text = proj!.distanceKm.toString();
                                 _recalculate();
                               }
                             }
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_,__) => const SizedBox.shrink(),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 2. Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                        child: Text(_date.formatEuropean()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(
                    child: InkWell(
                      onTap: _selectStartTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Début', prefixIcon: Icon(Icons.access_time)),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fin', prefixIcon: Icon(Icons.access_time_filled)),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pauseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pause (min)', suffixText: 'min'),
                      onChanged: (_) => _recalculate(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 3. Travel Expenses
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Déplacements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _travelDistanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Distance',
                              suffixText: 'km',
                              prefixIcon: Icon(Icons.directions_car, size: 20),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _travelRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Taux (par km)',
                              suffixText: '€',
                              prefixIcon: Icon(Icons.euro, size: 20),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final tDist = double.tryParse(_travelDistanceController.text.replaceAll(',', '.')) ?? 0.0;
                      final tRate = double.tryParse(_travelRateController.text.replaceAll(',', '.')) ?? 0.0;
                      return Text(
                        'Frais de déplacement (aller-retour) : ${((tDist * 2) * tRate).toStringAsFixed(2)} €',
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 4. Manual Price Override
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<BillingMode>(
                      value: _billingMode,
                      decoration: const InputDecoration(labelText: 'Mode de facturation'),
                      items: BillingMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                      onChanged: (v) {
                         if (v != null) {
                           setState(() => _billingMode = v);
                           _recalculate();
                         }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durée calculée :', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${(_durationMinutes / 60).toStringAsFixed(2)} h  ($_durationMinutes min)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Main d\'œuvre HT :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                            decoration: const InputDecoration(
                              suffixText: '€',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Requis';
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed == null) return 'Invalide';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final tDist = double.tryParse(_travelDistanceController.text.replaceAll(',', '.')) ?? 0.0;
                      final tRate = double.tryParse(_travelRateController.text.replaceAll(',', '.')) ?? 0.0;
                      final labor = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
                      final total = labor + ((tDist * 2) * tRate);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Prestation HT :', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo)),
                          Text('${total.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo, fontSize: 16)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 5. Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description / Notes', alignLabelWithHint: true),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer la prestation', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
