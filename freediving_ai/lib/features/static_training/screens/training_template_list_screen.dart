import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/training_template.dart';
import '../providers/training_template_provider.dart';
import '../providers/static_training_provider.dart';
import '../widgets/template_card.dart';
import 'static_setup_screen.dart';
import 'static_timer_screen.dart';
import '../models/training_table.dart';

class TrainingTemplateListScreen extends ConsumerWidget {
  const TrainingTemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(trainingTemplateProvider);
    final canCreate =
        templates.length < AppConstants.maxTrainingTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Templates'),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaticSetupScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            if (!canCreate)
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.accentYellow.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentYellow,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Template limit reached (${templates.length}/${AppConstants.maxTrainingTemplates})',
                        style: TextStyle(
                          color: AppTheme.accentYellow,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: templates.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: templates.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return TemplateCard(
                          template: template,
                          onStart: () => _startTraining(context, ref, template),
                          onEdit: () => _editTemplate(context, template),
                          onDelete: () => _deleteTemplate(context, ref, template),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80.sp,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No templates yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create your first training template',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StaticSetupScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.textPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  void _startTraining(
      BuildContext context, WidgetRef ref, TrainingTemplate template) {
    // Set the table from template
    final table = TrainingTable.fromTemplate(template);
    ref.read(staticTrainingProvider.notifier).setTable(table);

    // Navigate to timer screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StaticTimerScreen(),
      ),
    );
  }

  void _editTemplate(BuildContext context, TrainingTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaticSetupScreen(template: template),
      ),
    );
  }

  void _deleteTemplate(
      BuildContext context, WidgetRef ref, TrainingTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Delete Template',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${template.name}"?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(trainingTemplateProvider.notifier)
                  .deleteTemplate(template.id);

              if (context.mounted) {
                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template deleted'),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete template'),
                      backgroundColor: AppTheme.accentPink,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.accentPink),
            ),
          ),
        ],
      ),
    );
  }
}
