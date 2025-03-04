import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';

// Provider for the Address Repository
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
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
}

// StateNotifier for address management
class AddressNotifier extends StateNotifier<AddressState> {
  final AddressRepository _repository;

  AddressNotifier(this._repository) : super(AddressState());

  // Fetch user addresses
  Future<void> fetchUserAddresses() async {
    // Avoid multiple simultaneous fetches
    if (state.isLoading) return;
    
    // Set loading state but defer state update to avoid widget build conflicts
    await Future.delayed(Duration.zero, () {
      state = state.copyWith(isLoading: true, error: null);
    });
    
    try {
      // Get data from repository
      final addresses = await _repository.fetchAddresses();
      final selectedId = await _repository.getSelectedAddressId();
      
      // If there's no selected address but we have addresses, select the first one
      final effectiveSelectedId = selectedId ?? (addresses.isNotEmpty ? addresses.first.id : null);
      
      // Use another Future.delayed to ensure this happens outside any widget build
      await Future.delayed(Duration.zero, () {
        state = state.copyWith(
          addresses: addresses,
          selectedAddressId: effectiveSelectedId,
          isLoading: false,
        );
        
        print('Loaded ${addresses.length} addresses, selected: $effectiveSelectedId');
      });
    } catch (e) {
      print('Error loading addresses: $e');
      await Future.delayed(Duration.zero, () {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load addresses: $e',
        );
      });
    }
  }
  
  // Helper to compare address lists
  bool _areAddressListsEqual(List<Address> list1, List<Address> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    
    return true;
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