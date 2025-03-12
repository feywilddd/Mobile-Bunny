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

  Future<void> generateRoute(LatLng start, LatLng end) async {
    String apiKey = dotenv.get('MAP_API_KEY');
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: apiKey,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      state = state.copyWith(routePoints: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList());
      await fetchEstimatedTime(start, end);
    }
  }

  Future<void> fetchEstimatedTime(LatLng start, LatLng end) async {
    String apiKey = dotenv.get('MAP_API_KEY');
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&mode=driving';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        int durationInSeconds = data['routes'][0]['legs'][0]['duration']['value'];
        _startTime = DateTime.now().millisecondsSinceEpoch;
        startSimulation(durationInSeconds);
      }
    }
  }

  void startSimulation(int durationInSeconds) {
    int totalSteps = state.routePoints.length - 1;
    double secondsPerStep = durationInSeconds / totalSteps;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (secondsPerStep * 1000).toInt()), (timer) {
      if (state.currentStep < totalSteps) {
        state = state.copyWith(currentStep: state.currentStep + 1);
      } else {
        timer.cancel();
      }
    });
  }

  void restoreState() {
    int elapsedTime = (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
    int totalSteps = state.routePoints.length - 1;
    int estimatedStep = (elapsedTime * totalSteps) ~/ state.duration;
    state = state.copyWith(currentStep: estimatedStep < totalSteps ? estimatedStep : totalSteps);
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
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) => TrackingNotifier());
