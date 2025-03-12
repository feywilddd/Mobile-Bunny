import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/tracking_provider.dart';

class TrackingPage extends ConsumerStatefulWidget {
  final LatLng restaurantPosition;
  final LatLng clientPosition;

  TrackingPage({required this.restaurantPosition, required this.clientPosition});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  GoogleMapController? mapController;
  late BitmapDescriptor deliveryPin;
  late BitmapDescriptor restaurantPin;
  late BitmapDescriptor homePin;

  @override
  void initState() {
    super.initState();
    ref.read(trackingProvider.notifier).generateRoute(widget.restaurantPosition, widget.clientPosition);
    _loadPin();
  }

  Future<void> _loadPin() async {
   WidgetsBinding.instance.addPostFrameCallback((_) async {
      deliveryPin = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(43, 43)), "assets/delivery-bike.png");
      restaurantPin = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(43, 43)), "assets/restaurant-map-point.png");
      homePin = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(43, 43)), "assets/home-map-point.png");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    LatLng livreurPosition = trackingState.routePoints.isNotEmpty
        ? trackingState.routePoints[trackingState.currentStep]
        : widget.restaurantPosition;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(
              "Suivi du livreur",
              style: TextStyle( color: Colors.white)
              ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back, 
            color: Colors.white, 
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.restaurantPosition, zoom: 14.0),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: {
          Marker(markerId: MarkerId("restaurant"), position: widget.restaurantPosition, icon: restaurantPin),
          Marker(markerId: MarkerId("client"), position: widget.clientPosition, icon: homePin),
          Marker(markerId: MarkerId("livreur"), position: livreurPosition, icon: deliveryPin),
        },
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: trackingState.routePoints,
            color: Colors.blue,
            width: 5,
          ),
        },
      ),
    );
  }
}
