import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'triage_screen.dart';
// import 'settings_screen.dart'; // We will build this next

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;

  // THE SCREENS
  final List<Widget> _screens = [
    const DashboardScreen(), // Home = Pulse
    const TriageScreen(),    // Work = Allocate
    const Center(child: Text("SYSTEM SETTINGS (Coming Soon)")), // Settings
  ];

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).primaryColor;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: tfeGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'PULSE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'ALLOCATE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_input_component),
            label: 'SYSTEM',
          ),
        ],
      ),
    );
  }
}