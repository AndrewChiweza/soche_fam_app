import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soche_fam/screens/favorites_screen.dart';
import 'package:soche_fam/screens/home_screen.dart';
import 'package:soche_fam/screens/info_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({Key? key}) : super(key: key);

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    HomeScreen(),
    FavoritesScreen(),
    InfoScreen(),
  ];

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use PageView for swipeable pages
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // smooth swipe
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 5,
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: const Color(0xff939393),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: [
          BottomNavigationBarItem(
            label: 'Songs',
            icon: Column(
              children: [
                Container(
                  height: 2,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 4),
                  color: _selectedIndex == 0
                      ? Colors.green.shade900
                      : Colors.transparent,
                ),
                Icon(
                  _selectedIndex == 0
                      ? CupertinoIcons.music_house_fill
                      : CupertinoIcons.music_house,
                ),
              ],
            ),
          ),
          BottomNavigationBarItem(
            label: 'Favorites',
            icon: Column(
              children: [
                Container(
                  height: 2,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 4),
                  color: _selectedIndex == 1
                      ? Colors.green.shade900
                      : Colors.transparent,
                ),
                Icon(
                  _selectedIndex == 1
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                ),
              ],
            ),
          ),
          BottomNavigationBarItem(
            label: 'Info',
            icon: Column(
              children: [
                Container(
                  height: 2,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 4),
                  color: _selectedIndex == 2
                      ? Colors.green.shade900
                      : Colors.transparent,
                ),
                Icon(
                  _selectedIndex == 2
                      ? CupertinoIcons.info_circle_fill
                      : CupertinoIcons.info_circle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
