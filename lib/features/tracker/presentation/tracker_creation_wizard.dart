import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/tracker_models.dart';
import '../domain/services/tracker_analytics_service.dart';
import 'tracker_view_model.dart';
import 'widgets/template_selection_grid.dart';
import 'widgets/date_selector_tile.dart';
import 'widgets/bani_autocomplete_field.dart';

class TrackerCreationWizard extends ConsumerStatefulWidget {
  final TrackerGoal? editGoal;
  const TrackerCreationWizard({super.key, this.editGoal});

  @override
  ConsumerState<TrackerCreationWizard> createState() => _TrackerCreationWizardState();
}

class _TrackerCreationWizardState extends ConsumerState<TrackerCreationWizard> {
  int _currentStep = 0;

  TrackerTemplateType? _selectedType;
  DateTime _startDate = DateTime.now();
  DateTime? _deadlineDate;
  bool _isInfinite = false;

  final _titleController = TextEditingController();
  final _totalGoalController = TextEditingController();
  final _daysController = TextEditingController();
  final _dailyTargetController = TextEditingController();

  final List<String> _predefinedBanis = [
    'Japji Sahib', 'Chaupai Sahib', 'Sukhmani Sahib', 'Jaap Sahib',
    "Dukh Bhanjani Sahib"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editGoal != null) {
      _initEditMode();
    }
  }

  void _initEditMode() {
    final goal = widget.editGoal!;
    _selectedType = goal.templateType;
    _titleController.text = goal.title;
    _totalGoalController.text = goal.totalGoal?.toString() ?? '';
    _dailyTargetController.text = goal.dailyTarget?.toString() ?? '';
    _startDate = goal.startDate;
    _deadlineDate = goal.deadlineDate;
    _isInfinite = goal.deadlineDate == null;
    
    if (!_isInfinite && goal.totalGoal != null && goal.dailyTarget != null && goal.dailyTarget! > 0) {
      final days = (goal.totalGoal! / goal.dailyTarget!).ceil();
      _daysController.text = days.toString();
    }
    _currentStep = 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalGoalController.dispose();
    _daysController.dispose();
    _dailyTargetController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(TrackerTemplateType type) {
    setState(() {
      _selectedType = type;
      _currentStep = 1;
      _setDefaultValues(type);
    });
  }

  void _setDefaultValues(TrackerTemplateType type) {
    switch (type) {
      case TrackerTemplateType.moolMantar:
        _titleController.text = 'Mool Mantar Jaap';
        _totalGoalController.text = '125000';
        break;
      case TrackerTemplateType.waheguruSimran:
        _titleController.text = 'Waheguru Simran';
        _totalGoalController.text = '125000';
        break;
      case TrackerTemplateType.sehajPath:
        _titleController.text = 'Sehaj Path';
        _totalGoalController.text = '1430';
        break;
      default:
        break;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_deadlineDate ?? DateTime.now().add(const Duration(days: 40))),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _deadlineDate = picked;
          _isInfinite = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editGoal != null ? 'Edit Nitnem Goal' : 'New Nitnem Goal')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepCancel: () {
          if (_currentStep > 0 && widget.editGoal == null) setState(() => _currentStep--);
        },
        onStepContinue: () => _currentStep == 1 ? _handleFinalStep() : null,
        controlsBuilder: (context, details) {
          if (_currentStep == 0 && widget.editGoal == null) return const SizedBox.shrink();
          return _buildStepperControls(details);
        },
        steps: [
          Step(
            title: const Text('Template'),
            isActive: _currentStep >= 0,
            content: TemplateSelectionGrid(onTemplateSelected: _onTemplateSelected),
          ),
          Step(
            title: const Text('Configure'),
            isActive: _currentStep >= 1,
            content: _buildConfiguration(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperControls(ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: Text(widget.editGoal != null ? 'Update Tracker' : 'Create Tracker'),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.editGoal == null)
            TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
        ],
      ),
    );
  }

  Widget _buildConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType == TrackerTemplateType.baniCount) ...[
          const Text('Select Bani', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BaniAutocompleteField(
            controller: _titleController,
            options: _predefinedBanis,
            onSelected: (selection) => setState(() => _titleController.text = selection),
          ),
        ] else ...[
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
        ],
        const SizedBox(height: 20),
        DateSelectorTile(
          label: 'Start Date',
          date: _startDate,
          onTap: () => _selectDate(context, true),
        ),
        const SizedBox(height: 16),
        _buildGoalInputs(),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildGoalInputs() {
    final isBani = _selectedType == TrackerTemplateType.baniCount;
    final isSehajPath = _selectedType == TrackerTemplateType.sehajPath;

    return Column(
      children: [
        if (!isSehajPath)
          TextField(
            controller: _totalGoalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isBani ? 'Total Target (Paths)' : 'Total Target (Units)',
              border: const OutlineInputBorder(),
            ),
          )
        else
          const ListTile(
            title: Text('Total Target'),
            subtitle: Text('1430 Angs (Sri Guru Granth Sahib Ji)'),
            leading: Icon(Icons.auto_stories, color: Colors.teal),
          ),
        const SizedBox(height: 16),
        _buildDurationRow(),
        if (_isInfinite) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _dailyTargetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isSehajPath 
                  ? 'Daily Target (Optional Angs)' 
                  : (isBani ? 'Daily Target (Optional Paths)' : 'Daily Target (Optional Units)'),
              hintText: 'Leave empty for free hand',
              border: const OutlineInputBorder(),
            ),
          ),
        ] else if (isSehajPath) ...[
          const SizedBox(height: 16),
          DateSelectorTile(
            label: 'Deadline Date',
            date: _deadlineDate ?? DateTime.now().add(const Duration(days: 40)),
            onTap: () => _selectDate(context, false),
          ),
        ]
      ],
    );
  }

  Widget _buildDurationRow() {
    final isSehajPath = _selectedType == TrackerTemplateType.sehajPath;
    return Row(
      children: [
        if (!isSehajPath)
          Expanded(
            child: TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              enabled: !_isInfinite,
              decoration: const InputDecoration(labelText: 'Total Days', border: OutlineInputBorder()),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 16),
        if (!isSehajPath) const Text('OR'),
        const SizedBox(width: 16),
        ChoiceChip(
          label: Text(isSehajPath ? 'No End Date' : 'Infinite'),
          selected: _isInfinite,
          onSelected: (val) {
            setState(() {
              _isInfinite = val;
              if (val) {
                _daysController.clear();
                _deadlineDate = null;
              }
            });
          },
        ),
      ],
    );
  }

  void _handleFinalStep() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    String unitName = _getUnitName();
    int? totalGoal = int.tryParse(_totalGoalController.text);
    int? dailyTarget = int.tryParse(_dailyTargetController.text);

    if (_selectedType == TrackerTemplateType.sehajPath) {
      totalGoal = 1430;
    }

    if (!_isInfinite) {
      if (_selectedType == TrackerTemplateType.sehajPath) {
        _deadlineDate ??= DateTime.now().add(const Duration(days: 40));
        if (totalGoal != null) {
          dailyTarget = TrackerAnalyticsService().calculateRequiredDailyTarget(totalGoal, _startDate, _deadlineDate!);
        }
      } else {
        final days = int.tryParse(_daysController.text);
        if (days != null && totalGoal != null) {
          dailyTarget = (totalGoal / days).ceil();
          _deadlineDate = _startDate.add(Duration(days: days - 1));
        }
      }
    } else {
      _deadlineDate = null;
      // dailyTarget already comes from _dailyTargetController
    }

    _saveTracker(title, totalGoal, dailyTarget, unitName);
  }

  String _getUnitName() {
    switch (_selectedType) {
      case TrackerTemplateType.baniCount: return 'Paths';
      case TrackerTemplateType.sehajPath: return 'Angs';
      default: return 'Units';
    }
  }

  void _saveTracker(String title, int? totalGoal, int? dailyTarget, String unitName) {
    if (widget.editGoal != null) {
      final updatedGoal = widget.editGoal!.copyWith(
        templateType: _selectedType!,
        title: title,
        totalGoal: totalGoal,
        dailyTarget: dailyTarget,
        startDate: _startDate,
        deadlineDate: _deadlineDate,
        unitName: unitName,
      );
      ref.read(trackerViewModelProvider.notifier).updateTracker(updatedGoal).then((_) {
        if (mounted) context.pop();
      });
    } else {
      ref.read(trackerViewModelProvider.notifier).createTracker(
        type: _selectedType!,
        title: title,
        totalGoal: totalGoal,
        dailyTarget: dailyTarget,
        startDate: _startDate,
        deadlineDate: _deadlineDate,
        unitName: unitName,
      ).then((_) {
        if (mounted) context.pop();
      });
    }
  }
}
