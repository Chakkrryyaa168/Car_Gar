import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/preferences_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/ticket_provider.dart';
import 'package:frontend/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/splash/splash_screen.dart';
import 'package:frontend/screens/onboarding/onboarding_screen.dart';
import 'package:frontend/screens/auth/auth_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.resetOnboarding();
  });

  group('SplashScreen Tests', () {
    testWidgets('SplashScreen renders brand title, tagline, logo tile and dots', (WidgetTester tester) async {
      final apiService = ApiService();
      final authProvider = AuthProvider(apiService: apiService);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify immediate brand typography and logo presence
      expect(find.text('CAR GARAGE'), findsOneWidget);
      expect(find.text('Repairs, made clear'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_filled), findsOneWidget);

      // Verify pulsing loading dots are present
      expect(find.bySemanticsLabel('Loading application'), findsOneWidget);

      // Advance past 8-second navigation timer and settle into OnboardingScreen
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();

      // On clean launch without previous onboarding, it transitions to OnboardingScreen
      expect(find.text('Add your vehicle'), findsOneWidget);
    });
  });

  group('OnboardingScreen Tests', () {
    testWidgets('OnboardingScreen renders 3 slides, page indicator, skip, next and get started', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final apiService = ApiService();
      final wsService = WebSocketService();
      final authProvider = AuthProvider(apiService: apiService);
      final ticketProvider = TicketProvider(apiService: apiService, wsService: wsService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: ticketProvider),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Slide 1 Initial State
      expect(find.text('Add your vehicle'), findsOneWidget);
      expect(find.text("Register your car once and we'll verify it at your first visit."), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Staff member? Sign in to workshop'), findsOneWidget);

      // Advance to Slide 2 using "Next" button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Review and approve'), findsOneWidget);
      expect(find.text('See exactly what your mechanic found and choose what to fix, item by item.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Advance to Slide 3 using "Next" button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Track and pay'), findsOneWidget);
      expect(find.text('Follow repair progress live and pay when your car is ready.'), findsOneWidget);

      // On Slide 3, button label changes to "Get started"
      expect(find.text('Get started'), findsOneWidget);

      // Tap "Get started" to finish onboarding
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Verify onboarding completion leads to AuthScreen
      expect(find.byType(AuthScreen), findsOneWidget);

      // Verify flag is saved
      final hasSeen = await PreferencesService.hasSeenOnboarding();
      expect(hasSeen, isTrue);
    });

    testWidgets('Tapping Skip on Slide 1 completes onboarding and navigates to AuthScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final apiService = ApiService();
      final wsService = WebSocketService();
      final authProvider = AuthProvider(apiService: apiService);
      final ticketProvider = TicketProvider(apiService: apiService, wsService: wsService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: ticketProvider),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      final hasSeen = await PreferencesService.hasSeenOnboarding();
      expect(hasSeen, isTrue);
    });
  });
}
