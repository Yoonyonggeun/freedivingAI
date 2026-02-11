import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'models/user_profile.dart';
import 'models/analysis_result.dart';
import 'models/static_session.dart';
import 'models/training_template.dart';
import 'services/dnf_local_storage.dart';
import 'providers/dnf_storage_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/sample_experience_screen.dart';
import 'features/home/screens/home_passport_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(AnalysisResultAdapter());
  Hive.registerAdapter(StaticSessionAdapter());
  Hive.registerAdapter(TrainingTemplateAdapter());

  // Open Boxes
  await Hive.openBox<UserProfile>('userProfile');
  await Hive.openBox<AnalysisResult>('analysisResults');
  await Hive.openBox<StaticSession>('staticSessions');
  await Hive.openBox<TrainingTemplate>('trainingTemplates');

  // Initialize DNF Local Storage
  final dnfStorage = DNFLocalStorage();
  await dnfStorage.initialize();

  // Run app with storage provider override
  runApp(
    ProviderScope(
      overrides: [
        dnfStorageProvider.overrideWithValue(dnfStorage),
      ],
      child: const FreeDivingApp(),
    ),
  );
}

class FreeDivingApp extends StatelessWidget {
  const FreeDivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ko', ''), // Korean
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 🔧 RESET MODE: Set to true to completely wipe all data
    // This is the NUCLEAR OPTION - use when the reset button doesn't work
    // IMPORTANT: Set back to false after testing!
    const bool forceResetOnStartup = false;

    if (forceResetOnStartup) {
      print('💣💣💣 FORCE RESET MODE ACTIVATED 💣💣💣');

      try {
        // 1. Clear all Hive boxes
        print('📦 Step 1: Clearing all Hive boxes...');
        try {
          await Hive.box<UserProfile>('userProfile').clear();
          print('  ✓ userProfile cleared');
        } catch (e) {
          print('  ⚠️ userProfile: $e');
        }

        try {
          await Hive.box<AnalysisResult>('analysisResults').clear();
          print('  ✓ analysisResults cleared');
        } catch (e) {
          print('  ⚠️ analysisResults: $e');
        }

        try {
          await Hive.box<StaticSession>('staticSessions').clear();
          print('  ✓ staticSessions cleared');
        } catch (e) {
          print('  ⚠️ staticSessions: $e');
        }

        try {
          await Hive.box<TrainingTemplate>('trainingTemplates').clear();
          print('  ✓ trainingTemplates cleared');
        } catch (e) {
          print('  ⚠️ trainingTemplates: $e');
        }

        // Clear DNF boxes
        if (Hive.isBoxOpen('dnf_session_summaries')) {
          await Hive.box<String>('dnf_session_summaries').clear();
          print('  ✓ dnf_session_summaries cleared');
        }
        if (Hive.isBoxOpen('dnf_best_evidence')) {
          await Hive.box<String>('dnf_best_evidence').clear();
          print('  ✓ dnf_best_evidence cleared');
        }
        if (Hive.isBoxOpen('dnf_preferences')) {
          await Hive.box('dnf_preferences').clear();
          print('  ✓ dnf_preferences cleared');
        }

        // 2. Close all boxes
        print('📦 Step 2: Closing all boxes...');
        await Hive.close();
        print('  ✓ All boxes closed');

        // 3. Delete Hive directory from file system
        print('💣 Step 3: Deleting Hive files from disk...');
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final hivePath = '${appDir.path}';
          print('  📁 App directory: $hivePath');

          // List all files in the directory
          final dir = Directory(hivePath);
          final files = dir.listSync();
          print('  📄 Found ${files.length} files/folders');

          // Delete all .hive and .lock files
          int deletedCount = 0;
          for (var file in files) {
            if (file.path.endsWith('.hive') ||
                file.path.endsWith('.lock') ||
                file.path.contains('hive')) {
              try {
                if (file is File) {
                  await file.delete();
                  deletedCount++;
                  print('  🗑️ Deleted: ${file.path.split('/').last}');
                }
              } catch (e) {
                print('  ⚠️ Could not delete ${file.path}: $e');
              }
            }
          }
          print('  ✓ Deleted $deletedCount Hive files');
        } catch (e) {
          print('  ⚠️ File system deletion error: $e');
        }

        // 4. Clear SharedPreferences
        print('📦 Step 4: Clearing SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('  ✓ SharedPreferences cleared');

        print('✅✅✅ FORCE RESET COMPLETE - All data wiped! ✅✅✅');

        // 5. Re-open boxes (adapters already registered)
        print('📦 Step 5: Re-opening boxes...');
        await Hive.openBox<UserProfile>('userProfile');
        await Hive.openBox<AnalysisResult>('analysisResults');
        await Hive.openBox<StaticSession>('staticSessions');
        await Hive.openBox<TrainingTemplate>('trainingTemplates');
        print('  ✓ All boxes reopened');

        // 6. Re-initialize DNF Local Storage
        print('📦 Step 6: Re-initializing DNF storage...');
        final dnfStorage = DNFLocalStorage();
        await dnfStorage.initialize();
        print('  ✓ DNF storage initialized');

        print('✅✅✅ All systems ready! ✅✅✅');
      } catch (e, stackTrace) {
        print('❌❌❌ CRITICAL ERROR during force reset: $e');
        print('Stack trace: $stackTrace');
      }
    }

    // Check if sample has been shown (first-run check)
    final dnfStorage = DNFLocalStorage();
    await dnfStorage.initialize();
    final hasSampleShown = dnfStorage.hasSampleBeenShown;

    if (!hasSampleShown) {
      // First run - show sample experience
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SampleExperienceScreen()),
      );
      return;
    }

    // Check user profile for regular flow
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    if (profile == null) {
      // No profile, show onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      // Profile exists, go to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePassportScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waves,
                size: 100.w,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(height: 24.h),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                'AI-Powered Training Analysis',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
