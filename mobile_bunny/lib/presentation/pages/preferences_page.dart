import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/address_card.dart';
import '../widgets/allergen_filter_card.dart';
import '../widgets/profile_filter_list.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'login_page.dart';
import 'user_menu_page.dart';

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
      print("PreferencesPage._initializeData - Started");
      
      // Fetch data from providers
      await ref.read(addressProvider.notifier).fetchUserAddresses();
      await ref.read(profileProvider.notifier).fetchFamilyProfiles();
      
      // Initialize profile filters with fetched profiles
      final profiles = ref.read(profileProvider).profiles;
      final profileIds = profiles.map((profile) => profile.id).toList();
      
      print("PreferencesPage._initializeData - Initializing with profile IDs: $profileIds");
      ref.read(profileFilterProvider.notifier).initializeWithProfiles(profileIds);
      
      print("PreferencesPage._initializeData - Current filter state: ${ref.read(profileFilterProvider)}");
      
      if (mounted) {
        setState(() => isLoading = false);
        print("PreferencesPage._initializeData - Initialization complete");
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
    print("PreferencesPage.build - Started");
    
    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    final addressState = ref.watch(addressProvider);
    final profileState = ref.watch(profileProvider);
    
    // Also watch profile filter provider for changes
    final profileFilters = ref.watch(profileFilterProvider);
    print("PreferencesPage.build - Current filter state: $profileFilters");
    
    // Watch the refresh counter
    final refreshCount = ref.watch(allergenRefreshProvider);
    print("PreferencesPage.build - Refresh count: $refreshCount");
    
    // Consider additional state indicators beyond just the local isLoading
    final isDataLoading = isLoading || addressState.isLoading || profileState.isLoading;
    
    // Check for errors
    final hasError = addressState.error != null || profileState.error != null;
    final errorMessage = addressState.error ?? profileState.error;
    
    return Scaffold(
      appBar: const CustomAppBar(),
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
                        Text(
                          'Une erreur est survenue',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
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
                          // Title - Addresses
                          const Text(
                            'Adresses de livraison',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Address management card
                          const AddressCard(),
                          const SizedBox(height: 30),
                          
                          // Title - Allergen filtering
                          const Text(
                            'Préférences de filtrage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                        
                          // Allergen filter toggle card
                          const AllergenFilterCard(),
                          const SizedBox(height: 24),
                          
                          // Profile-specific toggles - only visible if main toggle is on
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
                            
                            // Profile filter list
                            const ProfileFilterList(),
                            
                            // Debug button
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                // Dump the current state of all filters to the console
                                final isEnabled = ref.read(allergenFilterEnabledProvider);
                                final filters = ref.read(profileFilterProvider);
                                final profiles = ref.read(profileProvider).profiles;
                                
                                print("=== FILTER DEBUG INFO ===");
                                print("Allergen filter enabled: $isEnabled");
                                print("Profile filters: $filters");
                                print("Available profiles: ${profiles.length}");
                                
                                for (final profile in profiles) {
                                  final isFilterEnabled = filters[profile.id] ?? true;
                                  print("Profile: ${profile.name} (${profile.id})");
                                  print("  Filter enabled: $isFilterEnabled");
                                  print("  Allergens: ${profile.allergens}");
                                }
                                
                                // Force a refresh for testing
                                ref.read(allergenRefreshProvider.notifier).state++;
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Filter debug info printed to console"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text("Debug Filters"),
                            ),
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