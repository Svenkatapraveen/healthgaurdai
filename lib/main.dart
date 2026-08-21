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
              scrollbarTheme: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(false),
                trackVisibility: WidgetStateProperty.all(false),
                thickness: WidgetStateProperty.all(6),
                radius: const Radius.circular(4),
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
              scrollbarTheme: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(false),
                trackVisibility: WidgetStateProperty.all(false),
                thickness: WidgetStateProperty.all(6),
                radius: const Radius.circular(4),
              ),
            ),
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              scrollbars: false,
            ),
            
            // App Navigation Routes
            initialRoute: '/',
            onGenerateRoute: (settings) {
              final rawName = settings.name ?? '/';
              Uri? uri;
              try {
                uri = Uri.parse(rawName);
              } catch (_) {}
              final path = uri?.path ?? rawName;

              final user = _appState.currentUser;
              final bool isAuthenticated = user != null;
              final bool isAdmin = user != null && (user.isAdmin || user.role == 'admin');

              // Public routes
              if (path == '/' ||
                  path == '/welcome' ||
                  path == '/login' ||
                  path == '/auth' ||
                  path == '/register' ||
                  path == '/forgot-password' ||
                  path == '/admin-login' ||
                  path == '/admin-forgot-password') {
                if (path == '/login' || path == '/auth' || path == '/admin-login') {
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                    settings: settings,
                  );
                }
                if (path == '/register') {
                  return MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                    settings: settings,
                  );
                }
                if (path == '/forgot-password' || path == '/admin-forgot-password') {
                  return MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                    settings: settings,
                  );
                }
                if (path == '/welcome') {
                  return MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                    settings: settings,
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                  settings: settings,
                );
              }

              // Protected routes check: Unauthenticated users redirected to Login
              if (!isAuthenticated) {
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                  settings: RouteSettings(name: '/login', arguments: settings.arguments),
                );
              }

              if (path == '/admin-dashboard' || path.startsWith('/admin')) {
                if (!isAdmin) {
                  return MaterialPageRoute(
                    builder: (context) => const MainDashboard(),
                    settings: const RouteSettings(name: '/dashboard'),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                  settings: settings,
                );
              }

              // Role check: Admin trying to access patient home dashboard directly
              if (path == '/dashboard' && isAdmin) {
                return MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                  settings: const RouteSettings(name: '/admin-dashboard'),
                );
              }

              // Protected Patient Routes
              if (path == '/report' || rawName.startsWith('/report')) {
                String? id = uri?.queryParameters['id'];
                if (id == null && rawName.contains('/report/')) {
                  final parts = rawName.split('/report/');
                  if (parts.length > 1 && parts[1].isNotEmpty) {
                    id = parts[1].split('?')[0];
                  }
                }
                return MaterialPageRoute(
                  builder: (context) => PdfReportScreen(reportId: id),
                  settings: settings,
                );
              }

              if (path == '/dashboard') {
                return MaterialPageRoute(
                  builder: (context) => const MainDashboard(),
                  settings: settings,
                );
              }

              if (path == '/assessment') {
                return MaterialPageRoute(
                  builder: (context) => const AssessmentWizard(),
                  settings: settings,
                );
              }

              if (path == '/results') {
                return MaterialPageRoute(
                  builder: (context) => const AnalysisResultsScreen(),
                  settings: settings,
                );
              }

              if (path == '/booking' || path == '/my-appointments' || path == '/recommendations') {
                int tab = 0;
                if (path == '/my-appointments' || uri?.queryParameters['tab'] == '1' || uri?.queryParameters['tab'] == 'my-appointments') {
                  tab = 1;
                }
                return MaterialPageRoute(
                  builder: (context) => BookingWizardScreen(initialTab: tab),
                  settings: settings,
                );
              }

              if (path == '/emergency') {
                return MaterialPageRoute(builder: (context) => const EmergencyAlertScreen(), settings: settings);
              }
              if (path == '/notifications') {
                return MaterialPageRoute(builder: (context) => const NotificationsScreen(), settings: settings);
              }
              if (path == '/reminders') {
                return MaterialPageRoute(builder: (context) => const MedicineReminderScreen(), settings: settings);
              }
              if (path == '/profile') {
                return MaterialPageRoute(builder: (context) => const ProfileScreen(), settings: settings);
              }
              if (path == '/forecast') {
                return MaterialPageRoute(builder: (context) => const FutureRiskForecastScreen(), settings: settings);
              }
              if (path == '/lifestyle') {
                return MaterialPageRoute(builder: (context) => const LifestyleDashboard(), settings: settings);
              }
              if (path == '/trends') {
                return MaterialPageRoute(builder: (context) => const HealthTrendsScreen(), settings: settings);
              }
              if (path == '/history') {
                return MaterialPageRoute(builder: (context) => const HealthHistoryScreen(), settings: settings);
              }

              return MaterialPageRoute(
                builder: (context) => isAdmin ? const AdminDashboardScreen() : const MainDashboard(),
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }
}
