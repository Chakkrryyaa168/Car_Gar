import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/inventory_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarGarageApp());
}

class CarGarageApp extends StatelessWidget {
  const CarGarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final wsService = WebSocketService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider(apiService: apiService, wsService: wsService),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Car Garage Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppShell(),
      ),
    );
  }
}
