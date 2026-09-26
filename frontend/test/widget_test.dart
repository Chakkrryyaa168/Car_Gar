import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge renders correctly with theme colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'PENDING_CUSTOMER_APPROVAL'),
        ),
      ),
    );

    // Verify badge text
    expect(find.text('Pending Approval'), findsOneWidget);

    // Verify status color mapping
    final color = AppColors.getStatusColor('PENDING_CUSTOMER_APPROVAL');
    expect(color, AppColors.statusPendingApproval);
  });
}
