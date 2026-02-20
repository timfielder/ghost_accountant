import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'triage_screen.dart';
import 'settings_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // THE SCREENS
  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const TriageScreen(),    // Index 1
    const SettingsScreen(),  // Index 2
  ];

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tfeGreen = Theme.of(context).primaryColor;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(), // iOS style bounce
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
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