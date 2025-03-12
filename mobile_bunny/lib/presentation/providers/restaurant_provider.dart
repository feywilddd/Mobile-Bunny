import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/restaurant_repository.dart';

// Provider for the Restaurant Repository
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final user = ref.watch(authProvider);
  
  // Even without auth, we can still browse restaurants
  return RestaurantRepository();
});

// State class for restaurant data
class RestaurantState {
  final List<Restaurant> restaurants;
  final String? selectedRestaurantId;
  final bool isLoading;
  final String? error;

  RestaurantState({
    this.restaurants = const [],
    this.selectedRestaurantId,
    this.isLoading = false,
    this.error,
  });

  RestaurantState copyWith({
    List<Restaurant>? restaurants,
    String? selectedRestaurantId,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantState(
      restaurants: restaurants ?? this.restaurants,
      selectedRestaurantId: selectedRestaurantId ?? this.selectedRestaurantId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  // Get the selected restaurant object
  Restaurant? get selectedRestaurant {
    if (selectedRestaurantId == null) return null;
    
    try {
      return restaurants.firstWhere(
        (restaurant) => restaurant.id == selectedRestaurantId,
        orElse: () => null as Restaurant, // Will never return null due to firstWhere behavior
      );
    } catch (e) {
      return null;
    }
  }
}

// StateNotifier for restaurant management
class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final RestaurantRepository _repository;

  RestaurantNotifier(this._repository) : super(RestaurantState()) {
    // Initialize by fetching restaurants
    fetchRestaurants();
  }

  // Fetch all restaurants and the selected one
  Future<void> fetchRestaurants() async {
    // Avoid multiple simultaneous fetches
    if (state.isLoading) return;
    
    // Set loading state but defer state update to avoid widget build conflicts
    await Future.microtask(() {
      state = state.copyWith(isLoading: true, error: null);
    });
    
    try {
      // Get data from repository
      final restaurants = await _repository.fetchRestaurants();
      String? selectedId;
      
      try {
        selectedId = await _repository.getSelectedRestaurantId();
      } catch (e) {
        // If getting selected ID fails (e.g., not logged in), ignore
        print('Error getting selected restaurant ID: $e');
      }
      
      // Use microtask to ensure this happens outside any widget build
      await Future.microtask(() {
        state = state.copyWith(
          restaurants: restaurants,
          selectedRestaurantId: selectedId,
          isLoading: false,
        );
        
        print('Loaded ${restaurants.length} restaurants, selected: $selectedId');
      });
    } catch (e) {
      print('Error loading restaurants: $e');
      await Future.microtask(() {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load restaurants: $e',
        );
      });
    }
  }

  // Set the selected restaurant
  Future<bool> setSelectedRestaurant(String restaurantId) async {
    try {
      final success = await _repository.setSelectedRestaurant(restaurantId);
      
      if (success) {
        state = state.copyWith(selectedRestaurantId: restaurantId);
        return true;
      }
      
      state = state.copyWith(
        error: 'Failed to set selected restaurant',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error setting selected restaurant: $e',
      );
      return false;
    }
  }
  
  // Clear the selected restaurant
  Future<bool> clearSelectedRestaurant() async {
    if (state.selectedRestaurantId == null) {
      // Already cleared
      return true;
    }
    
    try {
      final success = await _repository.clearSelectedRestaurant();
      
      if (success) {
        state = state.copyWith(selectedRestaurantId: null);
        return true;
      }
      
      state = state.copyWith(
        error: 'Failed to clear selected restaurant',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error clearing selected restaurant: $e',
      );
      return false;
    }
  }
}

// Provider for the restaurant state
final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  final repository = ref.watch(restaurantRepositoryProvider);
  return RestaurantNotifier(repository);
});

// Simpler providers for UI access

// Provider to check if restaurants are available
final hasRestaurantsProvider = Provider<bool>((ref) {
  final restaurantState = ref.watch(restaurantProvider);
  return restaurantState.restaurants.isNotEmpty;
});

// Provider to check if a restaurant is selected
final hasSelectedRestaurantProvider = Provider<bool>((ref) {
  final restaurantState = ref.watch(restaurantProvider);
  return restaurantState.selectedRestaurantId != null;
});

// Provider to get the selected restaurant
final selectedRestaurantProvider = Provider<Restaurant?>((ref) {
  final restaurantState = ref.watch(restaurantProvider);
  return restaurantState.selectedRestaurant;
});

// Provider to get restaurant error state
final restaurantErrorProvider = Provider<String?>((ref) {
  final restaurantState = ref.watch(restaurantProvider);
  return restaurantState.error;
});

// Provider to get restaurant loading state
final restaurantLoadingProvider = Provider<bool>((ref) {
  final restaurantState = ref.watch(restaurantProvider);
  return restaurantState.isLoading;
});