import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'models/user_profile.dart';
import 'models/analysis_result.dart';
import 'models/static_session.dart';
import 'models/training_template.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';

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

  runApp(const ProviderScope(child: FreeDivingApp()));
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

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
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
