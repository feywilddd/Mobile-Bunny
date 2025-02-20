import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  _RestaurantsPage createState() => _RestaurantsPage();
}

class _RestaurantsPage extends State<RestaurantsPage> {
  final mapController = MapController();
  String? selectedRestaurantName;

  List<Restaurant> restaurants = [
    Restaurant(
      name: "Restaurant 1",
      address: "Adresse du restaurant",
      city: "Ville",
      distance: 1.5,
      closingTime: "23h",
      location: latlong2.LatLng(46.0235, -73.4391),
    ),
    Restaurant(
      name: "Restaurant 2",
      address: "Adresse du restaurant",
      city: "Ville",
      distance: 1.5,
      closingTime: "23h",
      location: latlong2.LatLng(46.0335, -73.4291),
    ),
    Restaurant(
      name: "Restaurant 3",
      address: "Adresse du restaurant",
      city: "Ville",
      distance: 1.5,
      closingTime: "23h",
      location: latlong2.LatLng(46.0435, -73.4191),
    ),
  ];

  List<Restaurant> get sortedRestaurants {
    if (selectedRestaurantName == null) return restaurants;

    return [...restaurants]..sort((a, b) {
        if (a.name == selectedRestaurantName) return -1;
        if (b.name == selectedRestaurantName) return 1;
        return 0;
      });
  }

  void selectRestaurant(String name) {
    setState(() {
      selectedRestaurantName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choisir un restaurant'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:
                    latlong2.LatLng(46.0235, -73.4391), // Joliette coordinates
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: restaurants
                      .map(
                        (restaurant) => Marker(
                          point: restaurant.location,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              selectRestaurant(restaurant.name);
                              // Optional: Animate to center on the selected marker
                              mapController.move(restaurant.location,
                                  mapController.camera.zoom);
                            },
                            child: Icon(
                              Icons.location_pin,
                              color: restaurant.name == selectedRestaurantName
                                  ? Colors.blue // Highlight selected marker
                                  : Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: sortedRestaurants.length,
              itemBuilder: (context, index) {
                return _buildRestaurantCard(sortedRestaurants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final isSelected = restaurant.name == selectedRestaurantName;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        color: isSelected
            ? Colors.amber.withOpacity(0.2)
            : null, // Highlight selected restaurant
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name, // Added restaurant name display
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.amber[800] : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.address,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(restaurant.city),
            Text('${restaurant.distance} km'),
            Text("Ouvert jusqu'à ${restaurant.closingTime}"),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? Colors.green : const Color(0xFFE5927C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                // Handle order here
              },
              child: Text(isSelected ? 'Sélectionné' : 'Commander ici'),
            ),
          ],
        ),
      ),
    );
  }
}

class Restaurant {
  final String name;
  final String address;
  final String city;
  final double distance;
  final String closingTime;
  final latlong2.LatLng location;

  Restaurant({
    required this.name,
    required this.address,
    required this.city,
    required this.distance,
    required this.closingTime,
    required this.location,
  });
}
