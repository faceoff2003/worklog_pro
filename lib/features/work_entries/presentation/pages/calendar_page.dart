import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';
import 'package:worklog_pro/core/constants/enums.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Returns all work entries for a specific day
  List<WorkEntry> _getEventsForDay(List<WorkEntry> allEntries, DateTime day) {
    if (allEntries.isEmpty) return [];
    
    return allEntries.where((entry) {
      return entry.date.year == day.year &&
             entry.date.month == day.month &&
             entry.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsyncValue = ref.watch(workEntriesStreamProvider);
    final clientsAsyncValue = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
      ),
      body: entriesAsyncValue.when(
        data: (entries) {
          final selectedDayEntries = _selectedDay != null 
              ? _getEventsForDay(entries, _selectedDay!) 
              : <WorkEntry>[];

          return Column(
            children: [
              TableCalendar<WorkEntry>(
                locale: 'fr_FR',
                startingDayOfWeek: StartingDayOfWeek.monday,
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(entries, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedDayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = selectedDayEntries[index];
                    final startHour = (entry.startTime ~/ 60).toString().padLeft(2, '0');
                    final startMinute = (entry.startTime % 60).toString().padLeft(2, '0');
                    final endHour = (entry.endTime ~/ 60).toString().padLeft(2, '0');
                    final endMinute = (entry.endTime % 60).toString().padLeft(2, '0');
                    
                    
                    final clients = clientsAsyncValue.value ?? [];
                    final clientObj = clients.firstWhereOrNull(
                      (c) => c.id == entry.clientId,
                    );
                    final clientName = clientObj?.name ?? '';

                    // Fallback to ID if client somehow isn't found despite the collection
                    final displayClient = clientName.isEmpty ? 'Client: ${entry.clientId}' : clientName;
                    
                    final durationHours = (entry.durationMinutes / 60).toStringAsFixed(1);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: const Icon(Icons.work),
                        title: Text(displayClient, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$startHour:$startMinute - $endHour:$endMinute (${durationHours}h)'),
                        trailing: Icon(
                          entry.billingMode == BillingMode.hourly 
                              ? Icons.timer 
                              : Icons.monetization_on
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
