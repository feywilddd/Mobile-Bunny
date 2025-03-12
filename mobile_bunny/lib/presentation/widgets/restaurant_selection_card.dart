import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/restaurants_page.dart';  // Make sure to import your restaurant selection page

class RestaurantSelectionCard extends StatelessWidget {
  final List<dynamic> restaurants;
  final String? selectedRestaurantId;
  final Function(String) onSelectRestaurant;

  const RestaurantSelectionCard({
    Key? key,
    required this.restaurants,
    required this.selectedRestaurantId,
    required this.onSelectRestaurant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If we have a selected ID but it's not in the list yet, fetch it directly
    if (selectedRestaurantId != null && (restaurants.isEmpty || 
        !restaurants.any((r) => r.id == selectedRestaurantId))) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Restaurants')
            .doc(selectedRestaurantId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingCard();
          }
          
          if (snapshot.hasError) {
            return _buildErrorCard(snapshot.error.toString());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyCard(context);
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return _buildEmptyCard(context);
          }
          
          return _buildSelectedRestaurantCard(
            context,
            selectedRestaurantId!,
            data['address'] ?? 'Adresse inconnue',
          );
        },
      );
    }

    // If we have no restaurants at all
    if (restaurants.isEmpty) {
      return _buildEmptyCard(context);
    }

    // Find the selected restaurant in our list
    dynamic selectedRestaurant;
    if (selectedRestaurantId != null) {
      for (var restaurant in restaurants) {
        if (restaurant.id == selectedRestaurantId) {
          selectedRestaurant = restaurant;
          break;
        }
      }
    }

    // If we found a selected restaurant, show its details
    if (selectedRestaurant != null) {
      // Try to access address safely, defaulting to "Address unavailable"
      String address = "Adresse non disponible";
      try {
        address = selectedRestaurant.address ?? "Adresse non disponible";
      } catch (e) {
        print("Error accessing restaurant address: $e");
      }
      
      return _buildSelectedRestaurantCard(
        context,
        selectedRestaurantId!,
        address,
      );
    }

    // Otherwise show empty selection
    return _buildEmptyCard(context);
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Erreur: $error',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant_outlined, color: Colors.grey),
            title: const Text(
              'Aucun restaurant sélectionné',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Sélectionnez un restaurant pour commander',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the restaurants page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RestaurantsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB816E),
                minimumSize: const Size.fromHeight(45),
              ),
              child: const Text('Sélectionner un restaurant'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRestaurantCard(BuildContext context, String id, String address) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant, color: Color(0xFFDB816E)),
            title: const Text(
              'Restaurant sélectionné',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold
              ),
            ),
            subtitle: Text(
              address,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RestaurantsPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}