import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'theme/colors.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/main_dashboard.dart';
import 'screens/assessment_wizard.dart';
import 'screens/analysis_results_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/lifestyle_dashboard.dart';
import 'screens/trends_screen.dart';
import 'screens/history_screen.dart';
import 'screens/pdf_report_screen.dart';
import 'screens/booking_screens.dart';
import 'screens/emergency_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/doctor_login_screen.dart';
import 'screens/doctor_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: _appState,
      child: AnimatedBuilder(
        animation: _appState,
        builder: (context, child) {
          return MaterialApp(
            title: 'HealthGuard AI',
            debugShowCheckedModeBanner: false,
            themeMode: _appState.themeMode,
            
            // Light Theme Design
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: AppColors.primaryBlue,
              scaffoldBackgroundColor: AppColors.lightBg,
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryBlue,
                secondary: AppColors.primaryTeal,
                surface: AppColors.lightSurface,
                background: AppColors.lightBg,
                error: AppColors.riskCritical,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
                labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Dark Theme Design
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: AppColors.primaryBlue,
              scaffoldBackgroundColor: AppColors.darkBg,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primaryTeal,
                secondary: AppColors.accentCyan,
                surface: AppColors.darkSurface,
                background: AppColors.darkBg,
                error: AppColors.riskCritical,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
                labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            // App Navigation Routes
            initialRoute: '/',
            onGenerateRoute: (settings) {
              if (settings.name != null && settings.name!.startsWith('/report')) {
                String? id;
                try {
                  final uri = Uri.parse(settings.name!);
                  if (uri.queryParameters.containsKey('id')) {
                    id = uri.queryParameters['id'];
                  } else {
                    final parts = settings.name!.split('/report/');
                    if (parts.length > 1 && parts[1].isNotEmpty) {
                      id = parts[1].split('?')[0];
                    }
                  }
                } catch (_) {}
                return MaterialPageRoute(
                  builder: (context) => PdfReportScreen(reportId: id),
                  settings: settings,
                );
              }
              return null;
            },
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/auth': (context) => const LoginScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/admin-login': (context) => const LoginScreen(),
              '/admin-forgot-password': (context) => const ForgotPasswordScreen(),
              '/dashboard': (context) => const MainDashboard(),
              '/assessment': (context) => const AssessmentWizard(),
              '/results': (context) => const AnalysisResultsScreen(),
              '/forecast': (context) => const FutureRiskForecastScreen(),
              '/lifestyle': (context) => const LifestyleDashboard(),
              '/trends': (context) => const HealthTrendsScreen(),
              '/history': (context) => const HealthHistoryScreen(),
              '/report': (context) => const PdfReportScreen(),
              '/booking': (context) => const BookingWizardScreen(),
              '/my-appointments': (context) => const BookingWizardScreen(),
              '/recommendations': (context) => const BookingWizardScreen(),
              '/emergency': (context) => const EmergencyAlertScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/reminders': (context) => const MedicineReminderScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/admin-dashboard': (context) => const AdminDashboardScreen(),
              '/doctor-login': (context) => const DoctorLoginScreen(),
              '/doctor-dashboard': (context) => const DoctorDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
