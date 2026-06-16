import 'package:flutter/material.dart';

import 'core/utils/colors.dart';
import 'features/home/presentation/pages/home_page.dart';

class AppGroundView extends StatefulWidget {
  const AppGroundView({super.key});

  @override
  State<AppGroundView> createState() => _AppGroundViewState();
}

class _AppGroundViewState extends State<AppGroundView> {
  int _bottomNavIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    _PlaceholderPage(label: 'Stock'),
    _PlaceholderPage(label: 'Scan'),
    _PlaceholderPage(label: 'Repair'),
    _PlaceholderPage(label: 'Invoice'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_bottomNavIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Repair'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Invoice'),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }
}
