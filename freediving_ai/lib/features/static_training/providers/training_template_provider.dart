import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/training_template.dart';
import '../../../models/user_profile.dart';
import '../../../core/constants/app_constants.dart';

class TrainingTemplateNotifier extends StateNotifier<List<TrainingTemplate>> {
  final String userId;

  TrainingTemplateNotifier(this.userId) : super([]) {
    _loadTemplates();
  }

  void _loadTemplates() {
    final templates = getTemplatesForUser(userId);
    state = templates;
  }

  List<TrainingTemplate> getTemplatesForUser(String userId) {
    final box = Hive.box<TrainingTemplate>('trainingTemplates');
    return box.values
        .where((template) => template.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<bool> createTemplate(TrainingTemplate template) async {
    print('[Provider] Attempting to create template: ${template.name}');

    // Check max template limit
    final userTemplates = getTemplatesForUser(userId);
    print('[Provider] Current templates: ${userTemplates.length}/${AppConstants.maxTrainingTemplates}');

    if (userTemplates.length >= AppConstants.maxTrainingTemplates) {
      print('[Provider] ❌ Cannot create: max limit reached');
      return false; // Cannot create more templates
    }

    try {
      final box = Hive.box<TrainingTemplate>('trainingTemplates');
      print('[Provider] Adding template to box...');
      await box.add(template);
      print('[Provider] ✅ Template added successfully');
      _loadTemplates();
      return true;
    } catch (e, stackTrace) {
      print('[Provider] ❌ ERROR creating template: $e');
      print('[Provider] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> updateTemplate(TrainingTemplate template) async {
    try {
      print('[Provider] Attempting to update template: ${template.name}');
      print('[Provider] Template data: rounds=${template.rounds}, holdTimes=${template.holdTimes}, restTimes=${template.restTimes}');
      print('[Provider] Is template in box? ${template.isInBox}');

      if (!template.isInBox) {
        print('[Provider] ERROR: Template is not in Hive box! Cannot call save()');
        print('[Provider] This template needs to be added to the box first, not saved');
        // Template is not in the box, we need to update it differently
        final box = Hive.box<TrainingTemplate>('trainingTemplates');
        final existingTemplate = box.values.firstWhere(
          (t) => t.id == template.id,
          orElse: () => throw Exception('Template not found in box'),
        );

        print('[Provider] Found existing template in box, updating...');
        final index = existingTemplate.key;
        await box.put(index, template);
        print('[Provider] Template updated at index $index');
      } else {
        print('[Provider] Template is in box, calling save()...');
        await template.save();
        print('[Provider] Template saved successfully');
      }

      _loadTemplates();
      print('[Provider] Templates reloaded');
      return true;
    } catch (e, stackTrace) {
      print('[Provider] ❌ ERROR updating template: $e');
      print('[Provider] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    try {
      final box = Hive.box<TrainingTemplate>('trainingTemplates');
      final template = box.values.firstWhere((t) => t.id == id);
      await template.delete();
      _loadTemplates();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool canCreateTemplate() {
    return state.length < AppConstants.maxTrainingTemplates;
  }
}

// Provider for current user ID
final currentUserProvider = Provider<String>((ref) {
  final box = Hive.box<UserProfile>('userProfile');
  final profile = box.get('current');
  return profile?.id ?? 'current';
});

// Training template provider
final trainingTemplateProvider =
    StateNotifierProvider<TrainingTemplateNotifier, List<TrainingTemplate>>(
        (ref) {
  final userId = ref.watch(currentUserProvider);
  return TrainingTemplateNotifier(userId);
});
