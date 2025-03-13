import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(TrackingState());

  Timer? _timer;
  int _startTime = 0;
  bool _isActive = false;

  // Check if tracking is currently active
  bool get isTrackingActive => _isActive;

  // Reset tracking state
   void resetTracking() {
    _timer?.cancel();
    state = TrackingState();
    print("Tracking state has been reset");
  }

  Future<void> generateRoute(LatLng start, LatLng end) async {
    _isActive = true;
    String apiKey = dotenv.get('MAP_API_KEY');
    PolylinePoints polylinePoints = PolylinePoints();
    
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey,
        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(end.latitude, end.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        state = state.copyWith(
          routePoints: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList()
        );
        await fetchEstimatedTime(start, end);
      }
    } catch (e) {
      print("Error generating route: $e");
      // Provide fallback route in case of API error
      _generateFallbackRoute(start, end);
    }
  }

  // Generate a simple straight line route in case the API fails
  void _generateFallbackRoute(LatLng start, LatLng end) {
    const int numPoints = 20;
    List<LatLng> points = [];
    
    for (int i = 0; i <= numPoints; i++) {
      double fraction = i / numPoints;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    
    state = state.copyWith(routePoints: points);
    
    // Use a default duration of 10 minutes
    int defaultDuration = 600; // seconds
    state = state.copyWith(duration: defaultDuration);
    
    _startTime = DateTime.now().millisecondsSinceEpoch;
    startSimulation(defaultDuration);
  }

  Future<void> fetchEstimatedTime(LatLng start, LatLng end) async {
    String apiKey = dotenv.get('MAP_API_KEY');
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&mode=driving';
   
    try {
      final response = await http.get(Uri.parse(url));
     
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          int durationInSeconds = data['routes'][0]['legs'][0]['duration']['value'];
          state = state.copyWith(duration: durationInSeconds);
          _startTime = DateTime.now().millisecondsSinceEpoch;
          startSimulation(durationInSeconds);
        } else {
          // If API returns error, use fallback duration
          int defaultDuration = 600; // 10 minutes
          state = state.copyWith(duration: defaultDuration);
          _startTime = DateTime.now().millisecondsSinceEpoch;
          startSimulation(defaultDuration);
        }
      }
    } catch (e) {
      print("Error fetching estimated time: $e");
      // Use fallback duration in case of error
      int defaultDuration = 600; // 10 minutes
      state = state.copyWith(duration: defaultDuration);
      _startTime = DateTime.now().millisecondsSinceEpoch;
      startSimulation(defaultDuration);
    }
  }

  void startSimulation(int durationInSeconds) {
    int totalSteps = state.routePoints.length - 1;
    
    // Ensure we have a valid route with at least 2 points
    if (totalSteps <= 0) {
      return;
    }
    
    // Calculate step duration (minimum 1 second per step for very short routes)
    double secondsPerStep = totalSteps > durationInSeconds 
        ? 1.0 
        : durationInSeconds / totalSteps;
    
    // Cancel any existing timer
    _timer?.cancel();
    
    // Start new simulation timer
    _timer = Timer.periodic(Duration(milliseconds: (secondsPerStep * 1000).toInt()), (timer) {
      if (state.currentStep < totalSteps) {
        state = state.copyWith(currentStep: state.currentStep + 1);
      } else {
        timer.cancel();
        // Tracking is now complete
        _isActive = false;
      }
    });
  }

  void restoreState() {
    int elapsedTime = (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
    int totalSteps = state.routePoints.length - 1;
    
    // Guard against division by zero
    if (state.duration <= 0 || totalSteps <= 0) {
      return;
    }
    
    int estimatedStep = (elapsedTime * totalSteps) ~/ state.duration;
    state = state.copyWith(currentStep: estimatedStep < totalSteps ? estimatedStep : totalSteps);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class TrackingState {
  final List<LatLng> routePoints;
  final int currentStep;
  final int duration;

  TrackingState({
    this.routePoints = const [],
    this.currentStep = 0,
    this.duration = 0,
  });

  TrackingState copyWith({List<LatLng>? routePoints, int? currentStep, int? duration}) {
    return TrackingState(
      routePoints: routePoints ?? this.routePoints,
      currentStep: currentStep ?? this.currentStep,
      duration: duration ?? this.duration,
    );
  }
  
  // Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (routePoints.isEmpty) return 0.0;
    return currentStep / (routePoints.length - 1);
  }
  
  // Check if delivery is complete
  bool get isDeliveryComplete {
    return routePoints.isNotEmpty && currentStep >= routePoints.length - 1;
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) => TrackingNotifier());

// Simple provider to check if tracking is active
final isTrackingActiveProvider = Provider<bool>((ref) {
  return ref.watch(trackingProvider.notifier).isTrackingActive;
});