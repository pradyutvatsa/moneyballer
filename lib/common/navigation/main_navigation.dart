import 'package:material_ui/material_ui.dart';
import 'package:moneyballer/features/scheduling/dashboard_screen.dart';
import 'package:moneyballer/features/teams/roster_management_screen.dart';
import 'package:moneyballer/features/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _refreshCounter = 0; // <-- 1. Add this state variable here[cite: 1]

  // Premium Color Palette[cite: 1]
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  Widget build(BuildContext context) {
    // 2. Define _screens inside build() so DashboardScreen receives the updated ValueKey[cite: 1, 3]
    final List<Widget> screens = [
      DashboardScreen(key: ValueKey(_refreshCounter)),
      const RosterManagementScreen(),
      const Center(
        child: Text(
          'Chats Screen Coming Soon',
          style: TextStyle(color: _deepBlack, fontSize: 18),
        ),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: _crispWhite,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              // 3. Increment _refreshCounter whenever the user taps HOME[cite: 1]
              if (index == 0) {
                _refreshCounter++;
              }
            });
          },
          backgroundColor: _crispWhite,
          selectedItemColor: _champagneGold,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.calendar_today_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.calendar_today, size: 22),
              ),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.group_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.group, size: 24),
              ),
              label: 'My Squads',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.chat_bubble_outline, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.chat_bubble, size: 22),
              ),
              label: 'CHATS',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.person_outline, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.person, size: 24),
              ),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
