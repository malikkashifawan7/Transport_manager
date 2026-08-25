import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dashboard.dart';
import 'dashboard _screen.dart';
import 'vehicle_details_screen.dart';
import 'vendors_reminders_screen.dart';
import 'pdf_export_service.dart';
import 'excel_export_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const TransportEnterpriseApp());
}

class TransportEnterpriseApp extends StatelessWidget {
  const TransportEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Hisab Enterprise Pro Plus',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainEnterpriseNavigation(),
    );
  }
}

class MainEnterpriseNavigation extends StatefulWidget {
  const MainEnterpriseNavigation({super.key});

  @override
  State<MainEnterpriseNavigation> createState() => _MainEnterpriseNavigationState();
}

class _MainEnterpriseNavigationState extends State<MainEnterpriseNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const VendorsRemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.indigo),
            label: 'Enterprise Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.indigo),
            label: 'Vendors & Reminders',
          ),
        ],
      ),
    );
  }
}
