import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/core/constants/enums.dart'; // Added for BillingMode
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart'; // Added for WorkEntry
import 'package:worklog_pro/features/timer/presentation/providers/timer_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_form_page.dart';

class TimerFloatingActionButton extends ConsumerWidget {
  const TimerFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerControllerProvider);
    final durationAsync = ref.watch(timerDurationProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    // Format duration helper
    String formatDuration(int seconds) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    // Navigation to create work entry
    void stopAndCreateEntry(int durationSeconds) async {
       final durationMinutes = (durationSeconds / 60).ceil(); // Round up to nearest minute for entry
       // Assuming start time is roughly now - duration.
       // But better: use the actual start time from state before stopping?
       // The controller.stop() returns duration.
       // But we also need the start time.
       final startTime = timerState.startTime;
       
       if (startTime == null) return;
       
       await controller.stop();
       
       if (context.mounted) {
         // Create a WorkEntry with pre-filled data
         // StartTime: startTime
         // EndTime: Now
         // Duration: durationMinutes
         // Pause: accumulatedPause
         
         final now = DateTime.now();
         final startMinutes = startTime.hour * 60 + startTime.minute;
         final endMinutes = now.hour * 60 + now.minute;
         
         // We can pass this to the form.
         // But WorkEntryFormPage expects a WorkEntry object or uses current time.
         // Let's modify WorkEntryFormPage to accept `initialStartTime` and `initialDuration`?
         // Or just pass a `WorkEntry` object with these values set (and ID null).
         
         Navigator.of(context).push(
           MaterialPageRoute(
             builder: (context) => WorkEntryFormPage(
               workEntry: WorkEntry(
                 id: '', // Empty for new
                 date: DateOnly.fromDateTime(startTime),
                 startTime: startMinutes,
                 endTime: endMinutes,
                 pauseMinutes: timerState.accumulatedPauseDurationSeconds ~/ 60,
                 durationMinutes: durationMinutes,
                 // Other required fields with defaults
                 clientId: '',
                 billingMode: BillingMode.hourly,
                 rateApplied: Money.zero,
                 laborAmountHT: Money.zero,
                 createdAt: DateTime.now(),
                 updatedAt: DateTime.now(),
                 timerUsed: true,
               ),
             ),
           ),
         );
       }
    }

    if (!timerState.isRunning && timerState.startTime == null) {
      // Stopped State
      return FloatingActionButton(
        onPressed: () => controller.start(),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        tooltip: 'Démarrer Timer',
        child: const Icon(Icons.play_arrow),
      );
    }

    // Running or Paused State
    final currentDuration = durationAsync.value ?? 0;

    return FloatingActionButton.extended(
      onPressed: () {
        // Show controls
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(currentDuration),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Resume/Pause
                    if (timerState.isRunning)
                      IconButton.filled(
                        onPressed: () {
                          controller.pause();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.pause),
                        iconSize: 32,
                        tooltip: 'Pause',
                      )
                    else
                      IconButton.filled(
                        onPressed: () {
                          controller.resume();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 32,
                        style: IconButton.styleFrom(backgroundColor: Colors.green),
                        tooltip: 'Reprendre',
                      ),
                      
                    // Stop
                    IconButton.filled(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        stopAndCreateEntry(currentDuration);
                      },
                      icon: const Icon(Icons.stop),
                      iconSize: 32,
                      style: IconButton.styleFrom(backgroundColor: Colors.red),
                      tooltip: 'Arrêter & Enregistrer',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: timerState.isRunning ? Colors.orange : Colors.amber,
      foregroundColor: Colors.white,
      icon: Icon(timerState.isRunning ? Icons.timer : Icons.pause),
      label: Text(formatDuration(currentDuration)),
    );
  }
}
