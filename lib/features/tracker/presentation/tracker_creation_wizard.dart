import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/models/tracker_models.dart';
import '../domain/services/tracker_analytics_service.dart';
import 'tracker_view_model.dart';

class TrackerCreationWizard extends ConsumerStatefulWidget {
  final TrackerGoal? editGoal;
  const TrackerCreationWizard({super.key, this.editGoal});

  @override
  ConsumerState<TrackerCreationWizard> createState() => _TrackerCreationWizardState();
}

class _TrackerCreationWizardState extends ConsumerState<TrackerCreationWizard> {
  int _currentStep = 0;

  // Selected Data
  TrackerTemplateType? _selectedType;
  DateTime _startDate = DateTime.now();
  DateTime? _deadlineDate;
  bool _isInfinite = false;

  // Controllers
  final _titleController = TextEditingController();
  final _totalGoalController = TextEditingController();
  final _daysController = TextEditingController();
  final _dailyTargetController = TextEditingController();

  final List<String> _predefinedBanis = [
    'Japji Sahib',
    'Jaap Sahib',
    'Tav Prasad Savaiye',
    'Chaupai Sahib',
    'Anand Sahib',
    'Sukhmani Sahib',
    'Rehras Sahib',
    'Sohila'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editGoal != null) {
      final goal = widget.editGoal!;
      _selectedType = goal.templateType;
      _titleController.text = goal.title;
      _totalGoalController.text = goal.totalGoal?.toString() ?? '';
      _dailyTargetController.text = goal.dailyTarget?.toString() ?? '';
      _startDate = goal.startDate;
      _deadlineDate = goal.deadlineDate;
      
      // Determine if it was infinite based on deadline presence
      _isInfinite = goal.deadlineDate == null;
      
      if (!_isInfinite && goal.totalGoal != null && goal.dailyTarget != null && goal.dailyTarget! > 0) {
        final days = (goal.totalGoal! / goal.dailyTarget!).ceil();
        _daysController.text = days.toString();
      }
      _currentStep = 1;
    }
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
      
      // Default titles/units
      if (type == TrackerTemplateType.moolMantar) {
        _titleController.text = 'Mool Mantar Jaap';
        _totalGoalController.text = '125000';
      } else if (type == TrackerTemplateType.waheguruSimran) {
        _titleController.text = 'Waheguru Simran';
        _totalGoalController.text = '125000';
      } else if (type == TrackerTemplateType.sehajPath) {
        _titleController.text = 'Sehaj Path';
        _totalGoalController.text = '1430';
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_deadlineDate ?? DateTime.now().add(const Duration(days: 40))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
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
      appBar: AppBar(
        title: Text(widget.editGoal != null ? 'Edit Nitnem Goal' : 'New Nitnem Goal'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        physics: const BouncingScrollPhysics(),
        currentStep: _currentStep,
        onStepCancel: () {
          if (_currentStep > 0 && widget.editGoal == null) setState(() => _currentStep--);
        },
        onStepContinue: () {
          if (_currentStep == 1) {
            _handleFinalStep();
          }
        },
        controlsBuilder: (context, details) {
          if (_currentStep == 0 && widget.editGoal == null) return const SizedBox.shrink();
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
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Template'),
            isActive: _currentStep >= 0,
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildTemplateSelection(),
              ),
            ),
          ),
          Step(
            title: const Text('Configure'),
            isActive: _currentStep >= 1,
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildConfiguration(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60.0),
      child: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 180,
              child: _TemplateTile(
                icon: Icons.auto_awesome,
                label: 'Mool Mantar',
                color: Colors.orange,
                onTap: () => _onTemplateSelected(TrackerTemplateType.moolMantar),
              ),
            ),
            SizedBox(
              width: 280,
              height: 180,
              child: _TemplateTile(
                icon: Icons.favorite,
                label: 'Simran',
                color: Colors.redAccent,
                onTap: () => _onTemplateSelected(TrackerTemplateType.waheguruSimran),
              ),
            ),
            SizedBox(
              width: 280,
              height: 180,
              child: _TemplateTile(
                icon: Icons.menu_book,
                label: 'Bani Count',
                color: Colors.teal,
                onTap: () => _onTemplateSelected(TrackerTemplateType.baniCount),
              ),
            ),
            SizedBox(
              width: 280,
              height: 180,
              child: _TemplateTile(
                icon: Icons.library_books,
                label: 'Sehaj Path',
                color: Colors.purple,
                onTap: () => _onTemplateSelected(TrackerTemplateType.sehajPath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguration() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedType == TrackerTemplateType.baniCount) ...[
            const Text('Select Bani', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Autocomplete<String>(
            initialValue: TextEditingValue(text: _titleController.text),
            optionsBuilder: (textEditingValue) {
              return _predefinedBanis.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() => _titleController.text = selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search or enter custom name...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          ] else ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 20),
          
          // Starting Date
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
            trailing: const Icon(Icons.calendar_today, color: Colors.teal),
            onTap: () => _selectDate(context, true),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
          ),
          const SizedBox(height: 16),

          if (_selectedType == TrackerTemplateType.moolMantar || 
            _selectedType == TrackerTemplateType.waheguruSimran ||
            _selectedType == TrackerTemplateType.baniCount) 
          _buildSimranConfig(),

          if (_selectedType == TrackerTemplateType.sehajPath)
            _buildSehajPathConfig(),
        ],
      ),
    );
  }

  Widget _buildSimranConfig() {
    String goalLabel = 'Total Target (Units)';
    String dailyLabel = 'Daily Target (Optional Units)';
    if (_selectedType == TrackerTemplateType.baniCount) {
      goalLabel = 'Total Target (Paths)';
      dailyLabel = 'Daily Target (Optional Paths)';
    }

    return Column(
      children: [
        TextField(
          controller: _totalGoalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: goalLabel, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                enabled: !_isInfinite,
                decoration: const InputDecoration(labelText: 'Total Days', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 16),
            const Text('OR'),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('Infinite'),
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
        ),
        if (_isInfinite) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _dailyTargetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: dailyLabel, hintText: 'Leave empty for free hand', border: const OutlineInputBorder()),
          ),
        ]
      ],
    );
  }

  Widget _buildBaniConfig() {
    return TextField(
      controller: _dailyTargetController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Paths per day', border: OutlineInputBorder()),
    );
  }

  Widget _buildSehajPathConfig() {
    return Column(
      children: [
        ListTile(
          title: const Text('Deadline Date'),
          subtitle: Text(_deadlineDate == null ? 'No Deadline' : DateFormat('yyyy-MM-dd').format(_deadlineDate!)),
          trailing: const Icon(Icons.calendar_month, color: Colors.teal),
          onTap: () => _selectDate(context, false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
        ),
        const SizedBox(height: 16),
        if (_deadlineDate == null)
          TextField(
            controller: _dailyTargetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Angs per day', border: OutlineInputBorder()),
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

    String unitName = 'Units';
    if (_selectedType == TrackerTemplateType.baniCount) unitName = 'Paths';
    if (_selectedType == TrackerTemplateType.sehajPath) unitName = 'Angs';

    int? totalGoal = int.tryParse(_totalGoalController.text);
    int? dailyTarget = int.tryParse(_dailyTargetController.text);

    if (!_isInfinite) {
      final days = int.tryParse(_daysController.text);
      if (days != null && totalGoal != null) {
        dailyTarget = (totalGoal / days).ceil();
        _deadlineDate = _startDate.add(Duration(days: days - 1));
      }
    }

    // Sehaj Path fixed goal
    if (_selectedType == TrackerTemplateType.sehajPath) {
      totalGoal = 1430;
      if (_deadlineDate != null) {
        dailyTarget = TrackerAnalyticsService().calculateRequiredDailyTarget(totalGoal, _startDate, _deadlineDate!);
      }
    }

    if (widget.editGoal != null) {
      final updatedGoal = TrackerGoal(
        id: widget.editGoal!.id,
        templateType: _selectedType!,
        title: title,
        totalGoal: totalGoal,
        dailyTarget: dailyTarget,
        startDate: _startDate,
        deadlineDate: _deadlineDate,
        unitName: unitName,
        createdAt: widget.editGoal!.createdAt,
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

class _TemplateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TemplateTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withAlpha(50))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
