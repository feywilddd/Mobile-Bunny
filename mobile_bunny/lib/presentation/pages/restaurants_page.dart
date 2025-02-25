import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart';
import 'dart:math' show asin, cos, sqrt, pi, sin;

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  _RestaurantsPage createState() => _RestaurantsPage();
}

class _RestaurantsPage extends State<RestaurantsPage> {
  final mapController = MapController();
  String? selectedRestaurantName;
  List<Restaurant> restaurants = [];
  Location location = Location();
  latlong2.LatLng? userLocation;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _fetchRestaurants();
  }

  Future<void> _initLocationService() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // Check if location service is enabled
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    _locationData = await location.getLocation();
    setState(() {
      userLocation = latlong2.LatLng(_locationData.latitude!, _locationData.longitude!);
      _isLocationLoading = false;
      // Update distances for all restaurants
      _updateDistances();
    });

    // Listen for location changes
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        userLocation = latlong2.LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateDistances();
      });
    });
  }

  void _updateDistances() {
    if (userLocation != null) {
      for (var restaurant in restaurants) {
        restaurant.updateDistance(userLocation!);
      }
      // Sort restaurants by distance
      restaurants.sort((a, b) => a.distance.compareTo(b.distance));
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _fetchRestaurants() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Fetch documents from the "Restaurants" collection
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Restaurants').get();

    // Map Firestore documents to Restaurant objects
    final List<Restaurant> fetchedRestaurants = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Restaurant(
        name: data['name'] ?? 'Unnamed Restaurant',
        address: data['address'] ?? 'No Address',
        city: 'Joliette', // Assuming city is not stored in Firestore
        location: latlong2.LatLng(
          data['location'].latitude,
          data['location'].longitude,
        ),
        closingTime: _formatTimestamp(data['closing_time']),
      );
    }).toList();

    // Update the state with fetched restaurants
    setState(() {
      restaurants = fetchedRestaurants;
    });

    // Update distances if location is available
    if (userLocation != null) {
      _updateDistances();
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  List<Restaurant> get sortedRestaurants {
    if (selectedRestaurantName == null) return restaurants;

    return [...restaurants]..sort((a, b) {
        if (a.name == selectedRestaurantName) return -1;
        if (b.name == selectedRestaurantName) return 1;
        return a.distance.compareTo(b.distance); // Secondary sort by distance
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
      backgroundColor: Colors.black, // Black background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choisir un restaurant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: userLocation ?? 
                        latlong2.LatLng(46.0235, -73.4391), // Joliette coordinates as fallback
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // User marker
                        if (userLocation != null)
                          Marker(
                            point: userLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        // Restaurant markers
                        ...restaurants.map(
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
                                    ? Colors.amber // Highlight selected marker
                                    : Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLocationLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.amber : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.address,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.city,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _isLocationLoading 
                      ? 'Calcul...' 
                      : '${restaurant.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "Ouvert jusqu'à ${restaurant.closingTime}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle order here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.amber : const Color(0xFFDB816E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isSelected ? 'Sélectionné' : 'Commander ici',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
  double distance = 0.0;
  final String closingTime;
  final latlong2.LatLng location;

  Restaurant({
    required this.name,
    required this.address,
    required this.city,
    required this.location,
    required this.closingTime,
  });

  void updateDistance(latlong2.LatLng userLocation) {
    distance = calculateDistance(
      userLocation.latitude, 
      userLocation.longitude,
      location.latitude, 
      location.longitude
    );
  }

  // Calculate distance in kilometers using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
              
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}