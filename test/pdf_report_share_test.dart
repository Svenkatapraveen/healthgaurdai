import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:flutter_application_1healthgaurdai/screens/pdf_report_screen.dart';
import 'package:flutter_application_1healthgaurdai/services/db_service.dart';
import 'package:flutter_application_1healthgaurdai/state/app_state.dart';

class _FakeSharePlatform extends SharePlatform {
  List<XFile>? lastFiles;
  String? lastSubject;
  String? lastText;
  List<String>? lastFileNameOverrides;
  Object? errorToThrow;
  int shareXFilesCallCount = 0;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    shareXFilesCallCount++;
    lastFiles = files;
    lastSubject = subject;
    lastText = text;
    lastFileNameOverrides = fileNameOverrides;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return const ShareResult('com.whatsapp', ShareResultStatus.success);
  }
}

AssessmentModel _buildSampleAssessment() {
  return AssessmentModel(
    id: 'TEST-ASSESSMENT-123',
    userId: 'patient-1',
    date: DateTime(2026, 11, 25, 9, 0, 0),
    primarySymptoms: const ['Fever', 'Headache'],
    details: const {
      'severity': 6.0,
      'duration': '2 days',
      'pattern': 'Intermittent',
      'recommendedDoctor': 'General Physician',
    },
    associatedSymptoms: const ['Fatigue'],
    medicalHistory: const ['None'],
    lifestyle: const {
      'smoking': 'Never',
      'alcohol': 'Rarely',
      'exercise': '3 times/week',
      'sleep': 7.0,
      'water': 2.5,
      'stress': 'Low',
    },
    overallRiskScore: 35.0,
    riskCategory: 'Moderate Risk',
    diseaseProbability: const {'Viral Fever': 45.0},
    clinicalSummary: 'Test clinical summary for PDF sharing.',
    possibleCauses: const ['Viral Infection'],
    recommendations: const ['Stay hydrated', 'Consult physician'],
    preventiveActions: const ['Rest well'],
    urgencyLevel: 'Regular',
  );
}

Widget _wrapWithRoute(AppState state, AssessmentModel assessment) {
  return AppStateProvider(
    state: state,
    child: MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: RouteSettings(name: '/report', arguments: assessment),
          builder: (_) => const PdfReportScreen(),
        );
      },
    ),
  );
}

void main() {
  late SharePlatform originalPlatform;

  setUp(() {
    originalPlatform = SharePlatform.instance;
  });

  tearDown(() {
    SharePlatform.instance = originalPlatform;
  });

  testWidgets('Share button shares actual generated PDF file via SharePlatform', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeShare = _FakeSharePlatform();
    SharePlatform.instance = fakeShare;

    final appState = AppState();
    final assessment = _buildSampleAssessment();

    await tester.pumpWidget(_wrapWithRoute(appState, assessment));
    await tester.pumpAndSettle();

    final shareButton = find.widgetWithText(OutlinedButton, 'Share');
    expect(shareButton, findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);

    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(fakeShare.shareXFilesCallCount, 1);
    expect(fakeShare.lastFiles, isNotNull);
    expect(fakeShare.lastFiles!.length, 1);

    final sharedFile = fakeShare.lastFiles!.first;
    expect(sharedFile.mimeType, 'application/pdf');
    expect(
      fakeShare.lastFileNameOverrides,
      ['HealthGuard_AI_Medical_Report_TEST-ASSESSMENT-123.pdf'],
    );

    final bytes = await sharedFile.readAsBytes();
    expect(bytes.isNotEmpty, isTrue);
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });

  testWidgets('Share button shows error SnackBar when sharing fails', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeShare = _FakeSharePlatform()
      ..errorToThrow = Exception('No compatible share target available');
    SharePlatform.instance = fakeShare;

    final appState = AppState();
    final assessment = _buildSampleAssessment();

    await tester.pumpWidget(_wrapWithRoute(appState, assessment));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(fakeShare.shareXFilesCallCount, 1);
    expect(find.textContaining('Failed to share report:'), findsOneWidget);
  });
}
