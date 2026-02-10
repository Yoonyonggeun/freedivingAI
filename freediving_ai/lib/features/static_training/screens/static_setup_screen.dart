import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/training_template.dart';
import '../providers/training_template_provider.dart';
import '../widgets/round_config_input.dart';

class StaticSetupScreen extends ConsumerStatefulWidget {
  final TrainingTemplate? template;

  const StaticSetupScreen({super.key, this.template});

  @override
  ConsumerState<StaticSetupScreen> createState() => _StaticSetupScreenState();
}

class _StaticSetupScreenState extends ConsumerState<StaticSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<TextEditingController> _holdControllers = [];
  final List<TextEditingController> _restControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _loadTemplate(widget.template!);
    } else {
      // Start with 1 round by default
      _addRound();
    }
  }

  void _updateTotalDuration() {
    // Trigger rebuild when any controller value changes
    print('🔄 _updateTotalDuration called');
    if (mounted) {
      setState(() {});
    }
  }

  void _loadTemplate(TrainingTemplate template) {
    _nameController.text = template.name;

    // Debug: Check template data
    print('Loading template: ${template.name}');
    print('Rounds: ${template.rounds}, HoldTimes: ${template.holdTimes.length}, RestTimes: ${template.restTimes.length}');

    // Initialize hold controllers (N rounds = N hold times)
    for (int i = 0; i < template.rounds; i++) {
      final holdController = TextEditingController(
        text: template.holdTimes[i].toString(),
      );
      holdController.addListener(_updateTotalDuration);
      _holdControllers.add(holdController);
    }

    // Rest periods exist BETWEEN rounds only (N rounds = N-1 rest periods)
    for (int i = 0; i < template.rounds - 1; i++) {
      final restController = TextEditingController(
        text: i < template.restTimes.length ? template.restTimes[i].toString() : '60',
      );
      restController.addListener(_updateTotalDuration);
      _restControllers.add(restController);
    }

    // Debug: Verify controller counts
    print('Created ${_holdControllers.length} hold controllers, ${_restControllers.length} rest controllers');
  }

  void _addRound() {
    if (_holdControllers.length >= AppConstants.maxRounds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AppConstants.maxRounds} rounds allowed'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
      return;
    }

    print('➕ Adding round...');
    print('Before: holdControllers=${_holdControllers.length}, restControllers=${_restControllers.length}');

    setState(() {
      final holdController = TextEditingController();
      holdController.addListener(_updateTotalDuration);
      _holdControllers.add(holdController);

      // When adding a new round, the PREVIOUS last round now needs a rest period
      if (_holdControllers.length > 1) {
        final restController = TextEditingController();
        restController.addListener(_updateTotalDuration);
        _restControllers.add(restController);
      }

      print('After: holdControllers=${_holdControllers.length}, restControllers=${_restControllers.length}');
    });
  }

  void _removeRound(int index) {
    if (_holdControllers.length <= AppConstants.minRounds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum ${AppConstants.minRounds} round required'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
      return;
    }

    setState(() {
      // Remove the hold controller
      _holdControllers[index].dispose();
      _holdControllers.removeAt(index);

      // Always remove last rest controller (maintains N-1 invariant)
      if (_restControllers.isNotEmpty) {
        _restControllers.last.dispose();
        _restControllers.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _holdControllers) {
      controller.removeListener(_updateTotalDuration);
      controller.dispose();
    }
    for (var controller in _restControllers) {
      controller.removeListener(_updateTotalDuration);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Create Template' : 'Edit Template'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Template Configuration',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Create a reusable training configuration',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        _buildSectionTitle('Template Name'),
                        SizedBox(height: 12.h),
                        _buildNameInput(),
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Rounds (${_holdControllers.length}/${AppConstants.maxRounds})'),
                            TextButton.icon(
                              onPressed: _addRound,
                              icon: Icon(Icons.add_circle_outline, size: 20.sp),
                              label: Text('Add Round'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ..._buildRoundInputs(),
                        SizedBox(height: 24.h),
                        _buildDurationCard(),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _nameController,
      maxLength: 30,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        hintText: 'Morning Routine',
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        counterStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.accentPink,
            width: 1,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Template name is required';
        }
        return null;
      },
    );
  }

  List<Widget> _buildRoundInputs() {
    final widgets = <Widget>[];

    for (int i = 0; i < _holdControllers.length; i++) {
      widgets.add(
        RoundConfigInput(
          roundNumber: i + 1,
          holdController: _holdControllers[i],
          // Only pass rest controller for non-last rounds
          restController: i < _holdControllers.length - 1 ? _restControllers[i] : null,
          onDelete: _holdControllers.length > 1 ? () => _removeRound(i) : null,
        ),
      );
    }

    return widgets;
  }

  Widget _buildDurationCard() {
    final duration = _calculateTotalDuration();
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final formattedDuration =
        '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Duration',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                formattedDuration,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.timer,
            color: AppTheme.primaryBlue,
            size: 32.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _saveTemplate,
            borderRadius: BorderRadius.circular(28.r),
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Save Template',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateTotalDuration() {
    int total = 0;

    print('=== CALCULATE TOTAL DURATION ===');
    print('Hold controllers: ${_holdControllers.length}');
    print('Rest controllers: ${_restControllers.length}');

    for (int i = 0; i < _holdControllers.length; i++) {
      final text = _holdControllers[i].text;
      final value = int.tryParse(text);
      print('Hold[$i]: text="$text", value=$value');
      if (value != null) {
        total += value;
      }
    }

    for (int i = 0; i < _restControllers.length; i++) {
      final text = _restControllers[i].text;
      final value = int.tryParse(text);
      print('Rest[$i]: text="$text", value=$value');
      if (value != null) {
        total += value;
      }
    }

    print('TOTAL: $total seconds');
    return total;
  }

  Future<void> _saveTemplate() async {
    print('=== SAVE TEMPLATE START ===');
    print('Hold controllers: ${_holdControllers.length}');
    print('Rest controllers: ${_restControllers.length}');

    if (!_formKey.currentState!.validate()) {
      print('ERROR: Form validation failed');
      return;
    }

    // Validate that all rounds have values
    for (int i = 0; i < _holdControllers.length; i++) {
      if (_holdControllers[i].text.isEmpty) {
        print('ERROR: Hold time empty for Round ${i + 1}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in hold time for Round ${i + 1}'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
        return;
      }
    }

    // Invariant check - if this fails, the app needs to be restarted
    if (_restControllers.length != _holdControllers.length - 1) {
      print('ERROR: Invariant check failed!');
      print('Expected ${_holdControllers.length - 1} rest controllers, got ${_restControllers.length}');
      print('THIS MEANS THE APP WAS NOT RESTARTED AFTER CODE CHANGES!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('앱 상태 오류. 앱을 완전히 종료하고 다시 시작해주세요!'),
            backgroundColor: AppTheme.accentPink,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Validate rest times between rounds
    for (int i = 0; i < _restControllers.length; i++) {
      if (_restControllers[i].text.isEmpty) {
        print('ERROR: Rest time empty between Round ${i + 1} and ${i + 2}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in rest time between Round ${i + 1} and ${i + 2}'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      print('Parsing hold times...');
      final holdTimes = <int>[];
      final restTimes = <int>[];

      for (var controller in _holdControllers) {
        final value = int.tryParse(controller.text);
        if (value == null) {
          print('ERROR: Invalid hold time: ${controller.text}');
          throw Exception('Invalid hold time');
        }
        holdTimes.add(value);
      }
      print('Hold times parsed: $holdTimes');

      // Save N-1 rest times (rest periods exist BETWEEN rounds only)
      print('Parsing rest times...');
      for (var controller in _restControllers) {
        final value = int.tryParse(controller.text);
        if (value == null) {
          print('ERROR: Invalid rest time: ${controller.text}');
          throw Exception('Invalid rest time');
        }
        restTimes.add(value);
      }
      print('Rest times parsed: $restTimes');

      final userId = ref.read(currentUserProvider);
      final now = DateTime.now();

      // Debug: Verify data consistency
      print('Creating template: rounds=${_holdControllers.length}, holdTimes=${holdTimes.length}, restTimes=${restTimes.length}');
      print('HoldTimes: $holdTimes');
      print('RestTimes: $restTimes');

      print('Creating TrainingTemplate object...');
      final template = TrainingTemplate(
        id: widget.template?.id ?? const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        rounds: _holdControllers.length,
        holdTimes: holdTimes,
        restTimes: restTimes,
        createdAt: widget.template?.createdAt ?? now,
        updatedAt: now,
      );
      print('Template created successfully');
      print('Template restTimes after migration: ${template.restTimes}');

      bool success;
      if (widget.template == null) {
        print('Creating NEW template...');
        success = await ref
            .read(trainingTemplateProvider.notifier)
            .createTemplate(template);
        print('Create result: $success');
      } else {
        print('UPDATING existing template...');
        success = await ref
            .read(trainingTemplateProvider.notifier)
            .updateTemplate(template);
        print('Update result: $success');
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          print('=== SAVE SUCCESS ===');
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.template == null
                    ? 'Template created'
                    : 'Template updated',
              ),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        } else {
          print('=== SAVE FAILED ===');
          print('Reason: Provider returned false');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.template == null
                    ? 'Failed to create template. Limit reached (${AppConstants.maxTrainingTemplates})'
                    : 'Failed to update template. Check console for details.',
              ),
              backgroundColor: AppTheme.accentPink,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('=== EXCEPTION CAUGHT ===');
      print('Error saving template: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: ${e.toString()}\n콘솔 로그를 확인하세요'),
            backgroundColor: AppTheme.accentPink,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
