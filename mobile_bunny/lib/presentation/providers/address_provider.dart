import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';

// Provider for the Address Repository
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final user = ref.watch(authProvider);
  
  // User must be logged in to access addresses
  if (user == null) {
    throw Exception('User must be logged in to access addresses');
  }
  
  return AddressRepository();
});

// State class for address data
class AddressState {
  final List<Address> addresses;
  final String? selectedAddressId;
  final bool isLoading;
  final String? error;

  AddressState({
    this.addresses = const [],
    this.selectedAddressId,
    this.isLoading = false,
    this.error,
  });

  AddressState copyWith({
    List<Address>? addresses,
    String? selectedAddressId,
    bool? isLoading,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  // Get the selected address object
  Address? get selectedAddress {
    if (selectedAddressId == null) return null;
    return addresses.firstWhere(
      (address) => address.id == selectedAddressId,
      orElse: () => null as Address, // Will never return null due to firstWhere behavior
    );
  }
}

// StateNotifier for address management
class AddressNotifier extends StateNotifier<AddressState> {
  final AddressRepository _repository;

  AddressNotifier(this._repository) : super(AddressState()) {
    // Initialize by fetching addresses
    fetchUserAddresses();
  }

  // Fetch user addresses
  Future<void> fetchUserAddresses() async {
    // Avoid multiple simultaneous fetches
    if (state.isLoading) return;
    
    // Set loading state but defer state update to avoid widget build conflicts
    await Future.microtask(() {
      state = state.copyWith(isLoading: true, error: null);
    });
    
    try {
      // Get data from repository
      final addresses = await _repository.fetchAddresses();
      final selectedId = await _repository.getSelectedAddressId();
      
      // If there's no selected address but we have addresses, select the first one
      final effectiveSelectedId = selectedId ?? (addresses.isNotEmpty ? addresses.first.id : null);
      
      // If we got a different selected ID than before, update it in Firestore
      if (effectiveSelectedId != null && 
          selectedId == null && 
          addresses.isNotEmpty) {
        await _repository.setSelectedAddress(effectiveSelectedId);
      }
      
      // Use microtask to ensure this happens outside any widget build
      await Future.microtask(() {
        state = state.copyWith(
          addresses: addresses,
          selectedAddressId: effectiveSelectedId,
          isLoading: false,
        );
        
        print('Loaded ${addresses.length} addresses, selected: $effectiveSelectedId');
      });
    } catch (e) {
      print('Error loading addresses: $e');
      await Future.microtask(() {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load addresses: $e',
        );
      });
    }
  }

  // Add a new address
  Future<bool> addAddress(Map<String, dynamic> addressData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final addressId = await _repository.addAddress(addressData);
      
      if (addressId != null) {
        await fetchUserAddresses(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add address',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error adding address: $e',
      );
      return false;
    }
  }

  // Update an existing address
  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _repository.updateAddress(addressId, addressData);
      
      if (success) {
        await fetchUserAddresses(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update address',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating address: $e',
      );
      return false;
    }
  }

  // Delete an address
  Future<bool> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _repository.deleteAddress(addressId);
      
      if (success) {
        await fetchUserAddresses(); // Refresh the list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete address',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error deleting address: $e',
      );
      return false;
    }
  }

  // Set the selected address
  Future<bool> setSelectedAddress(String addressId) async {
    try {
      final success = await _repository.setSelectedAddress(addressId);
      
      if (success) {
        state = state.copyWith(selectedAddressId: addressId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error setting selected address: $e',
      );
      return false;
    }
  }
}

// Provider for the address state
final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  final repository = ref.watch(addressRepositoryProvider);
  return AddressNotifier(repository);
});

// Simpler providers for UI access

// Provider to check if user has addresses
final hasAddressesProvider = Provider<bool>((ref) {
  final addressState = ref.watch(addressProvider);
  return addressState.addresses.isNotEmpty;
});

// Provider to check if a default address is selected
final hasSelectedAddressProvider = Provider<bool>((ref) {
  final addressState = ref.watch(addressProvider);
  return addressState.selectedAddressId != null;
});

// Provider to get the selected address
final selectedAddressProvider = Provider<Address?>((ref) {
  final addressState = ref.watch(addressProvider);
  return addressState.selectedAddress;
});

// Provider to get address error state
final addressErrorProvider = Provider<String?>((ref) {
  final addressState = ref.watch(addressProvider);
  return addressState.error;
});

// Provider to get address loading state
final addressLoadingProvider = Provider<bool>((ref) {
  final addressState = ref.watch(addressProvider);
  return addressState.isLoading;
});