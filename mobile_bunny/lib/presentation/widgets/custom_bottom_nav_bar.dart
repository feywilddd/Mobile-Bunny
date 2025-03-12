import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/pages/restaurants_page.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';
import 'package:mobile_bunny/presentation/pages/basket_page.dart';
import 'package:mobile_bunny/presentation/providers/order_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_bunny/presentation/pages/restaurants_page.dart';
import 'package:mobile_bunny/presentation/pages/tracking_page.dart';

class CustomBottomNavigationBar extends ConsumerStatefulWidget {
  const CustomBottomNavigationBar({super.key});
  
  @override
  ConsumerState<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends ConsumerState<CustomBottomNavigationBar> {
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
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingPage(
            restaurantPosition: LatLng(46.03115353128858, -73.44116406758411),
            clientPosition: LatLng(46.02358, -73.43292),
          ),
      ),
    );
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get cart item count from Riverpod
    final cartItemCount = ref.watch(cartItemCountProvider);
    
    return Container(
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.all(8.0),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurant'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Panier',
          ),
        ],
      ),
    );
  }
}