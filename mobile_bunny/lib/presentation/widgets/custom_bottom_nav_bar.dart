import 'package:flutter/material.dart';
import 'package:mobile_bunny/presentation/pages/restaurants_page.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 1; // Start with Menu selected (index 1)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Restaurant
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantsPage()),
        );
        break;
      case 1: // Menu
         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuPage()),
        );
        break;
      case 2: // Cart
        // Add cart page navigation when implemented
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.all(8.0),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurant'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Panier'),
        ],
      ),
    );
  }
}
