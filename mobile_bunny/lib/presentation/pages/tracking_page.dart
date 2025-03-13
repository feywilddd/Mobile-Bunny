import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/tracking_provider.dart';

class TrackingPage extends ConsumerStatefulWidget {
  final LatLng restaurantPosition;
  final LatLng clientPosition;
  
  // Add this callback for when tracking is completed
  final VoidCallback? onDeliveryComplete;

  const TrackingPage({
    Key? key,
    required this.restaurantPosition, 
    required this.clientPosition,
    this.onDeliveryComplete,
  }) : super(key: key);

  @override
  TrackingPageState createState() => TrackingPageState();
}

class TrackingPageState extends ConsumerState<TrackingPage> {
  GoogleMapController? mapController;
  
  // Make these nullable and initialize with default markers
  BitmapDescriptor? deliveryPin;
  BitmapDescriptor? restaurantPin;
  BitmapDescriptor? homePin;
  
  bool _deliveryComplete = false;
  bool _pinsLoaded = false;
  
  @override
  void initState() {
    super.initState();
    ref.read(trackingProvider.notifier).generateRoute(widget.restaurantPosition, widget.clientPosition);
    
    // Set default markers first
    deliveryPin = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    restaurantPin = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    homePin = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    
    // Then try to load custom markers
    _loadCustomPins();
    
    // Add a listener to detect when delivery is complete
    _setupDeliveryCompletionDetection();
  }
  
  void _setupDeliveryCompletionDetection() {
    // Listen for changes in tracking state
    ref.listenManual(trackingProvider, (previous, next) {
      // Check if this is the last step and we haven't already marked as complete
      if (next.routePoints.isNotEmpty && 
          next.currentStep >= next.routePoints.length - 1 && 
          !_deliveryComplete) {
        _deliveryComplete = true;
        _handleDeliveryComplete();
      }
    });
  }
  
  void _handleDeliveryComplete() {
    // Show delivery complete dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Livraison complétée!'),
        content: const Text('Votre commande a été livrée avec succès.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Navigate back to home page
              Navigator.of(context).popUntil((route) => route.isFirst);
              
              // Call the completion callback if provided
              widget.onDeliveryComplete?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCustomPins() async {
    try {
      // This is the correct way to load BitmapDescriptor from assets
      final customDeliveryPin = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(43, 43)), 
        "assets/delivery-bike.png"
      );
      
      final customRestaurantPin = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(43, 43)), 
        "assets/restaurant-map-point.png"
      );
      
      final customHomePin = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(43, 43)), 
        "assets/home-map-point.png"
      );
      
      // Update the state with the custom pins
      if (mounted) {
        setState(() {
          deliveryPin = customDeliveryPin;
          restaurantPin = customRestaurantPin;
          homePin = customHomePin;
          _pinsLoaded = true;
        });
      }
    } catch (e) {
      print("Error loading custom pins: $e");
      // Already have default pins set in initState, so no need to set them again
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);

    // Safety check for currentStep to avoid index out of bounds error
    LatLng livreurPosition = (trackingState.routePoints.isNotEmpty && 
                           trackingState.currentStep < trackingState.routePoints.length)
        ? trackingState.routePoints[trackingState.currentStep]
        : widget.restaurantPosition; // Fallback to restaurant position

    return WillPopScope(
      // Prevent back button if delivery is in progress
      onWillPop: () async {
        if (!_deliveryComplete) {
          // Show confirmation dialog
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Quitter le suivi?'),
              content: const Text('La livraison est en cours. Êtes-vous sûr de vouloir quitter cette page?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Oui'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            "Suivi du livreur",
            style: TextStyle(color: Colors.white)
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              if (_deliveryComplete) {
                // If delivery is complete, go back to home
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onDeliveryComplete?.call();
              } else {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Quitter le suivi?'),
                    content: const Text('La livraison est en cours. Êtes-vous sûr de vouloir quitter cette page?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Non'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back
                        },
                        child: const Text('Oui'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: widget.restaurantPosition, zoom: 14.0),
                onMapCreated: (controller) {
                  mapController = controller;
                  
                  // Adjust camera to show both markers
                  LatLngBounds bounds = LatLngBounds(
                    southwest: LatLng(
                      widget.restaurantPosition.latitude < widget.clientPosition.latitude 
                          ? widget.restaurantPosition.latitude : widget.clientPosition.latitude,
                      widget.restaurantPosition.longitude < widget.clientPosition.longitude 
                          ? widget.restaurantPosition.longitude : widget.clientPosition.longitude,
                    ),
                    northeast: LatLng(
                      widget.restaurantPosition.latitude > widget.clientPosition.latitude 
                          ? widget.restaurantPosition.latitude : widget.clientPosition.latitude,
                      widget.restaurantPosition.longitude > widget.clientPosition.longitude 
                          ? widget.restaurantPosition.longitude : widget.clientPosition.longitude,
                    ),
                  );
                  
                  // Add padding to bounds
                  controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
                },
                markers: {
                  // Now these are safe since pins are initialized with defaults
                  Marker(
                    markerId: const MarkerId("restaurant"), 
                    position: widget.restaurantPosition, 
                    icon: restaurantPin!
                  ),
                  Marker(
                    markerId: const MarkerId("client"), 
                    position: widget.clientPosition, 
                    icon: homePin!
                  ),
                  Marker(
                    markerId: const MarkerId("livreur"), 
                    position: livreurPosition, 
                    icon: deliveryPin!
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: trackingState.routePoints,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
              ),
            ),
            
            // Add delivery status bar
            Container(
              color: const Color(0xFF212529),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut de la livraison',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (trackingState.routePoints.isNotEmpty && trackingState.routePoints.length > 1)
                    LinearProgressIndicator(
                      value: trackingState.currentStep / (trackingState.routePoints.length - 1),
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE79686)),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusText(trackingState),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(TrackingState state) {
    if (state.routePoints.isEmpty) {
      return 'Calcul de l\'itinéraire...';
    }
    
    // Avoid division by zero
    if (state.routePoints.length <= 1) {
      return 'Préparation de la livraison...';
    }
    
    final progress = state.currentStep / (state.routePoints.length - 1);
    
    if (progress < 0.5) {
      return 'Le livreur est en route vers vous...';
    } else if (progress < 0.9) {
      return 'Le livreur s\'approche de votre adresse...';
    } else if (progress >= 1.0) {
      return 'Commande livrée!';
    } else {
      return 'Livraison en cours...';
    }
  }
  
  @override
  void dispose() {
    // Clean up map controller
    mapController?.dispose();
    super.dispose();
  }
}