import 'package:flutter/material.dart';
import 'package:rbl_admin/couponService/CouponCeilingTab.dart';
import 'package:rbl_admin/news/PAGE_CreateNews.dart';
import 'package:rbl_admin/reservation/reservationList.dart';

class BottomTabView extends StatefulWidget {
  const BottomTabView({super.key});

  @override
  _BottomTabViewState createState() => _BottomTabViewState();
}

class _BottomTabViewState extends State<BottomTabView> {
  // Index for the selected tab
  int _selectedIndex = 0;

  // List of widgets for each tab
  final List<Widget> _pages = [
    CreateNews(),
    CouponTab(),
    ReservationListView(),
  ];

  // Function to handle tab change
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Show the selected tab
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Current selected tab
        onTap: _onItemTapped, // Update selected tab when tapped
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper, color: Colors.blue,),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.blue,),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_view_day,
              color: Colors.blue,

            ),
            label: 'reservation',
          ),
        ],
      ),
    );
  }
}
