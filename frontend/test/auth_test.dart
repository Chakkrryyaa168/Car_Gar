import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/websocket_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/ticket_provider.dart';
import 'package:frontend/screens/auth/auth_screen.dart';

void main() {
  testWidgets('AuthScreen renders Login and fills credentials without 1-click login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
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
          home: AuthScreen(),
        ),
      ),
    );

    // Initial Login View
    expect(find.text('CAR GARAGE'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In to Garage'), findsOneWidget);
    expect(find.text('TEST ROLE CREDENTIALS (CLICK TO FILL & VIEW)'), findsOneWidget);
    expect(find.text('chak@gmail.com'), findsNWidgets(2)); // initial textfield & customer chip

    // Click on Mechanic role button to fill and display credentials
    await tester.ensureVisible(find.text('Mechanic'));
    await tester.tap(find.text('Mechanic'));
    await tester.pumpAndSettle();

    // Verify it didn't auto-login, but instead populated the fields and showed status
    expect(find.text('mechanic@cargarage.com'), findsNWidgets(2)); // in chip & in textfield
    expect(find.text('Sign In to Garage'), findsOneWidget);

    // Verify Google Sign-In button on Login
    expect(find.text('Continue with Google'), findsOneWidget);

    // Tap 'Create Account' tab
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify Register View Elements
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Customer Account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
