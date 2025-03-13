import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../providers/restaurant_provider.dart'; // Add the restaurant provider
import '../providers/profile_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/address_card.dart';
import '../widgets/allergen_filter_card.dart';
import '../widgets/profile_filter_list.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'login_page.dart';
import 'user_menu_page.dart';
import '../widgets/restaurant_selection_card.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    
    try {
      // Make sure we fetch restaurants too
      final restaurantNotifier = ref.read(restaurantProvider.notifier);
      await restaurantNotifier.fetchRestaurants();
      
      // Fetch addresses and profiles
      await ref.read(addressProvider.notifier).fetchUserAddresses();
      await ref.read(profileProvider.notifier).fetchFamilyProfiles();
      
      final profiles = ref.read(profileProvider).profiles;
      final profileIds = profiles.map((profile) => profile.id).toList();
      
      ref.read(profileFilterProvider.notifier).initializeWithProfiles(profileIds);
      
      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      // Handle not logged in state
      return Scaffold(
        appBar: const CustomAppBar(showArrow: true),
        backgroundColor: const Color(0xFF212529),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Veuillez vous connecter pour accéder à vos préférences',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE79686),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(),
      );
    }

    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    final addressState = ref.watch(addressProvider);
    final profileState = ref.watch(profileProvider);
    final restaurantState = ref.watch(restaurantProvider);
    
    final profileFilters = ref.watch(profileFilterProvider);
    
    final refreshCount = ref.watch(allergenRefreshProvider);
    
    final isDataLoading = isLoading || 
                        addressState.isLoading || 
                        profileState.isLoading ||
                        restaurantState.isLoading;
    
    // Combine all possible errors
    final hasError = addressState.error != null || 
                    profileState.error != null ||
                    restaurantState.error != null;
                    
    final errorMessage = addressState.error ?? 
                        profileState.error ??
                        restaurantState.error;
    
    return Scaffold(
      appBar: const CustomAppBar(showArrow: true),
      backgroundColor: const Color(0xFF212529),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDataLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Une erreur est survenue',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializeData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB816E),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _initializeData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adresses de livraison',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Pass key parameters needed for address selection
                          AddressCard(),
                          const SizedBox(height: 30),
                          
                          const Text(
                            'Restaurant sélectionné',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Add Restaurant selection widget
                          RestaurantSelectionCard(
                            restaurants: restaurantState.restaurants,
                            selectedRestaurantId: restaurantState.selectedRestaurantId,
                            onSelectRestaurant: (restaurantId) async {
                              await ref.read(restaurantProvider.notifier).setSelectedRestaurant(restaurantId);
                            },
                          ),
                          const SizedBox(height: 30),
                          
                          const Text(
                            'Préférences de filtrage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                        
                          const AllergenFilterCard(),
                          const SizedBox(height: 24),
                          
                          if (isAllergenFilterEnabled) ...[
                            const Text(
                              'Filtrer pour qui?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Activez les profils dont vous souhaitez prendre en compte les allergènes',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            
                            const ProfileFilterList(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
