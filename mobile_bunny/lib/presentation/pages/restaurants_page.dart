import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show asin, cos, sqrt, pi, sin;
import '../providers/restaurant_provider.dart';
import '../providers/auth_provider.dart';

// Simple restaurant model to use directly in this page
class RestaurantItem {
  final String id;
  final String address;
  final String city;
  final latlong2.LatLng location;
  final DateTime closingTime;
  double distance = 0.0;

  RestaurantItem({
    required this.id,
    required this.address,
    required this.city,
    required this.location,
    required this.closingTime,
  });

  static RestaurantItem fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantItem(
      id: doc.id,
      address: data['address'] ?? 'No Address',
      city: 'Joliette', // Default city
      location: latlong2.LatLng(
        data['location'].latitude,
        data['location'].longitude,
      ),
      closingTime: (data['closing_time'] as Timestamp).toDate(),
    );
  }
}

class RestaurantsPage extends ConsumerStatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends ConsumerState<RestaurantsPage> {
  final mapController = MapController();
  Location location = Location();
  latlong2.LatLng? userLocation;
  bool _isLocationLoading = true;
  List<RestaurantItem> restaurants = [];
  String? selectedRestaurantId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _fetchRestaurants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the current selected restaurant ID from the provider
    final restaurantState = ref.read(restaurantProvider);
    setState(() {
      selectedRestaurantId = restaurantState.selectedRestaurantId;
    });
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
        setState(() => _isLocationLoading = false);
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() => _isLocationLoading = false);
        return;
      }
    }

    // Get current location
    _locationData = await location.getLocation();
    setState(() {
      userLocation = latlong2.LatLng(_locationData.latitude!, _locationData.longitude!);
      _isLocationLoading = false;
    });

    // Update distances
    _updateDistances();

    // Listen for location changes
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        userLocation = latlong2.LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateDistances();
      });
    });
  }

  void _updateDistances() {
    if (userLocation != null && restaurants.isNotEmpty) {
      setState(() {
        for (var restaurant in restaurants) {
          restaurant.distance = _calculateDistance(
            userLocation!.latitude,
            userLocation!.longitude,
            restaurant.location.latitude,
            restaurant.location.longitude,
          );
        }
        // Sort by distance
        restaurants.sort((a, b) => a.distance.compareTo(b.distance));
      });
    }
  }

  // Calculate distance in kilometers using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  Future<void> _fetchRestaurants() async {
    setState(() => _isLoading = true);
    
    try {

      // Fetch documents from the "Restaurants" collection
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Restaurants').get();

      // Check if there are documents
      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = "Aucun restaurant trouvé";
        });
        return;
      }

      // Map Firestore documents to Restaurant objects
      final List<RestaurantItem> fetchedRestaurants = snapshot.docs
          .map((doc) => RestaurantItem.fromFirestore(doc))
          .toList();

      // Update the state with fetched restaurants
      setState(() {
        restaurants = fetchedRestaurants;
        _isLoading = false;
      });

      // Update distances if location is available
      if (userLocation != null) {
        _updateDistances();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Erreur lors du chargement des restaurants: $e";
      });
      print("Error fetching restaurants: $e");
    }
  }

  List<RestaurantItem> get sortedRestaurants {
    if (selectedRestaurantId == null) return restaurants;

    return [...restaurants]..sort((a, b) {
        if (a.id == selectedRestaurantId) return -1;
        if (b.id == selectedRestaurantId) return 1;
        return a.distance.compareTo(b.distance); // Secondary sort by distance
      });
  }

  @override
  Widget build(BuildContext context) {
    // Get authentication state
    final user = ref.watch(authProvider);
    final isAuthenticated = user != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF212529), // Dark background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choisir un restaurant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
      ),
      body: _isLoading || _isLocationLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $_error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchRestaurants,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB816E),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : restaurants.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun restaurant disponible',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: userLocation ??
                                  latlong2.LatLng(46.0235, -73.4391), // Joliette coordinates as fallback
                              initialZoom: 13,
                              onTap: (_, __) {
                                // Close any open info windows
                                setState(() {});
                              },
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
                                    (restaurant) {
                                      final isSelected = restaurant.id == selectedRestaurantId;
                                      
                                      return Marker(
                                        point: restaurant.location,
                                        width: 40,
                                        height: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            // Center the map on the selected restaurant
                                            mapController.move(
                                              restaurant.location,
                                              mapController.camera.zoom,
                                            );
                                            
                                            // If authenticated, select this restaurant
                                            if (isAuthenticated) {
                                              _selectRestaurant(restaurant.id);
                                            } else {
                                              _showLoginPrompt(context);
                                            }
                                          },
                                          child: Icon(
                                            Icons.location_pin,
                                            color: isSelected ? Colors.amber : const Color(0xFFDB816E),
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: ListView.builder(
                            itemCount: sortedRestaurants.length,
                            itemBuilder: (context, index) {
                              return _buildRestaurantCard(
                                sortedRestaurants[index],
                                isAuthenticated,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _selectRestaurant(String restaurantId) async {
    // First update the local state for immediate feedback
    setState(() {
      selectedRestaurantId = restaurantId;
    });
    
    // Then update the restaurant provider
    final restaurantNotifier = ref.read(restaurantProvider.notifier);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection du restaurant...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final success = await restaurantNotifier.setSelectedRestaurant(restaurantId);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant sélectionné avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back after selection
        Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection du restaurant'),
            duration: Duration(seconds: 3),
          ),
        );
        // Reset the local state if the provider update failed
        setState(() {
          selectedRestaurantId = ref.read(restaurantProvider).selectedRestaurantId;
        });
      }
    } catch (e) {
      print("Error selecting restaurant: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset the local state if there was an error
        setState(() {
          selectedRestaurantId = ref.read(restaurantProvider).selectedRestaurantId;
        });
      }
    }
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212529),
        title: const Text(
          'Connexion requise',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Vous devez être connecté pour sélectionner un restaurant.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB816E),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login page
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(
    RestaurantItem restaurant,
    bool isAuthenticated,
  ) {
    final isSelected = restaurant.id == selectedRestaurantId;

    return GestureDetector(
      onTap: () {
        // Center the map on the selected restaurant
        mapController.move(
          restaurant.location,
          mapController.camera.zoom,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
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
                restaurant.address,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${restaurant.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Ouvert jusqu'à ${_formatTime(restaurant.closingTime)}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isAuthenticated
                    ? () => _selectRestaurant(restaurant.id)
                    : () => _showLoginPrompt(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.amber : const Color(0xFFDB816E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isSelected ? 'Sélectionné' : 'Sélectionner',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}