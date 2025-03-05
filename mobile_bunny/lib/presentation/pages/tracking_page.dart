import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/custom_app_bar.dart';

class TrackingPage extends StatefulWidget {
  final LatLng restaurantPosition;
  final LatLng clientPosition;

  TrackingPage({required this.restaurantPosition, required this.clientPosition});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  GoogleMapController? mapController;
  Marker? livreurMarker;
  List<LatLng> routePoints = [];
  Set<Polyline> polylines = {};
  int currentStep = 0;
  Timer? _timer;
  late BitmapDescriptor deliveryPin;

  @override
  void initState() {
    _loadPin();
    super.initState();
    _generateRoute();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPin() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      deliveryPin = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(43, 43)), "assets/delivery-bike.png");
      setState(() {});
    });

  }

  // 📍 Générer le trajet avec Google Directions API
  Future<void> _generateRoute() async {
    PolylinePoints polylinePoints = PolylinePoints();

    String apiKey = dotenv.get('MAP_API_KEY');

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: apiKey,
      request: PolylineRequest(
        origin: PointLatLng(widget.restaurantPosition.latitude, widget.restaurantPosition.longitude),
        destination: PointLatLng(widget.clientPosition.latitude, widget.clientPosition.longitude),
        mode: TravelMode.driving,
    ),
  );


    if (result.points.isNotEmpty) {
      setState(() {
        routePoints = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        polylines = {
          Polyline(
            polylineId: PolylineId("route"),
            points: routePoints,
            color: Colors.blue,
            width: 5,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)], 
          ),
        };
      });

      print("Points de la route: $routePoints");
      _startSimulation();
    } else {
      print("Aucun itinéraire trouvé !");
    }

  }
  
  // 🚛 Simulation du déplacement du livreur
 void _startSimulation() {
  _timer = Timer.periodic(Duration(seconds: 5), (timer) {
    if (currentStep < routePoints.length - 1) {
      setState(() {
        livreurMarker = Marker(
          markerId: MarkerId("livreur"),
          position: routePoints[currentStep],
          icon: deliveryPin,//BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
        currentStep++;
      });

      print("Marqueur livreur déplacé : ${routePoints[currentStep]}");
      mapController?.animateCamera(CameraUpdate.newLatLng(routePoints[currentStep]));
    } else {
      print("Simulation terminée");
      timer.cancel();
    }
  });
}

  @override
  Widget build(BuildContext context) {
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
        initialCameraPosition: CameraPosition(
          target: widget.restaurantPosition,
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          print("Google Maps chargé !");
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId("restaurant"),
            position: widget.restaurantPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
          Marker(
            markerId: MarkerId("client"),
            position: widget.clientPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
          if (livreurMarker != null) livreurMarker!,
        },
       polylines: polylines,
      ),
    );
  }
}
