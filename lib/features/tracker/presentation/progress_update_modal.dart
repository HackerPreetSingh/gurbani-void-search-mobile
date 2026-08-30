import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/tracker_repository.dart';
import '../domain/models/tracker_models.dart';
import 'tracker_view_model.dart';

class ProgressUpdateModal extends ConsumerStatefulWidget {
  final TrackerGoal goal;
  final TrackerLog? editLog;
  const ProgressUpdateModal({super.key, required this.goal, this.editLog});

  @override
  ConsumerState<ProgressUpdateModal> createState() => _ProgressUpdateModalState();
}

class _ProgressUpdateModalState extends ConsumerState<ProgressUpdateModal> {
  DateTime _logDate = DateTime.now();
  final _maalaController = TextEditingController();
  final _rawController = TextEditingController();
  final _countController = TextEditingController();

  bool get _isSimran => widget.goal.templateType == TrackerTemplateType.moolMantar || 
                        widget.goal.templateType == TrackerTemplateType.waheguruSimran;

  @override
  void initState() {
    super.initState();
    if (widget.editLog != null) {
      _logDate = widget.editLog!.logDate;
      if (_isSimran) {
        _maalaController.text = (widget.editLog!.count ~/ 108).toString();
        _rawController.text = (widget.editLog!.count % 108).toString();
      } else {
        _countController.text = widget.editLog!.count.toString();
      }
    }
  }

  @override
  void dispose() {
    _maalaController.dispose();
    _rawController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: widget.goal.startDate,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _logDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log Daily Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (widget.editLog != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Editing entry from ${DateFormat('HH:mm').format(widget.editLog!.createdAt)}', style: const TextStyle(color: Colors.orange)),
              ),
            const SizedBox(height: 24),
            
            ListTile(
              title: const Text('Log Date'),
              subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_logDate)),
              trailing: const Icon(Icons.calendar_month, color: Colors.teal),
              onTap: () => _selectDate(context),
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            const SizedBox(height: 24),
            
            if (_isSimran) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maalaController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Maala (x108)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.exposure_plus_1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _rawController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Raw Units',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.add_circle_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Note: 1 Maala = 108 Units', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ] else ...[
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount of ${widget.goal.unitName}',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.add_task),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.editLog != null ? 'Update Entry' : 'Save Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _submitLog() {
    int totalUnits = 0;

    if (_isSimran) {
      final maala = int.tryParse(_maalaController.text) ?? 0;
      final raw = int.tryParse(_rawController.text) ?? 0;
      totalUnits = (maala * 108) + raw;
    } else {
      totalUnits = int.tryParse(_countController.text) ?? 0;
    }

    if (totalUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount.')));
      return;
    }

    if (widget.editLog != null) {
      final updatedLog = TrackerLog(
        id: widget.editLog!.id,
        trackerId: widget.goal.id,
        logDate: _logDate,
        count: totalUnits,
        inputMode: _isSimran ? 'mixed' : 'raw',
        createdAt: widget.editLog!.createdAt,
      );
      ref.read(trackerViewModelProvider.notifier).updateLog(updatedLog).then((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      final log = TrackerLog(
        trackerId: widget.goal.id,
        logDate: _logDate,
        count: totalUnits,
        inputMode: _isSimran ? 'mixed' : 'raw',
        createdAt: DateTime.now(),
      );

      ref.read(trackerRepositoryProvider).addLog(log).then((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }
}
