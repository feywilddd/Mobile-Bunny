import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/user_menu_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider to store the allergen filter state
final allergenFilterEnabledProvider = StateProvider<bool>((ref) => true);
final profileFilterProvider = StateProvider<Map<String, bool>>((ref) => {});

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  List<Map<String, dynamic>> familyProfiles = [];
  bool isLoading = true;

  List<Map<String, dynamic>> userAddresses = [];
  String? selectedAddressId;

  @override
  void initState() {
    super.initState();
    _fetchFamilyProfiles();
    _fetchUserAddresses();
  }

  // Fetch all family profiles for the current user
  Future<void> _fetchFamilyProfiles() async {
    setState(() => isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('familyProfiles')
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          final profiles = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          
          setState(() {
            familyProfiles = profiles;
          });
          
          // Initialize the profile filter provider
          final initialProfileFilters = Map<String, bool>.fromEntries(
            profiles.map((profile) => MapEntry(profile['id'], true))
          );
          ref.read(profileFilterProvider.notifier).state = initialProfileFilters;
        } else {
          setState(() {
            familyProfiles = [];
          });
        }
      } catch (e) {
        print('Error fetching family profiles: $e');
      }
    }
  }
  
  // Fetch user addresses
  Future<void> _fetchUserAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();
            
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        String? currentAddressId;
        if (userDoc.exists) {
          currentAddressId = userDoc.data()?['selectedAddressId'];
        }
        
        if (snapshot.docs.isNotEmpty) {
          final addresses = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          
          setState(() {
            userAddresses = addresses;
            selectedAddressId = currentAddressId ?? addresses[0]['id'];
            isLoading = false;
          });
        } else {
          setState(() {
            userAddresses = [];
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching addresses: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get user initials for avatar display
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final nameParts = name.split(' ');
    
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0];
    } else {
      return '?';
    }
  }
  
  // Build the address management card
  Widget _buildAddressCard() {
    return Card(
      color: const Color(0xFF1C1C1C),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes adresses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, color: Color(0xFFDB816E)),
                  label: const Text(
                    'Ajouter',
                    style: TextStyle(color: Color(0xFFDB816E)),
                  ),
                  onPressed: () => _showAddAddressForm(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // List of addresses
            if (userAddresses.isEmpty)
              const Center(
                child: Text(
                  'Aucune adresse enregistrée',
                  style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              )
            else
              Column(
                children: userAddresses.map((address) {
                  final addressId = address['id'] as String;
                  final isSelected = selectedAddressId == addressId;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? const Color(0xFFDB816E) : Colors.grey[800]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        address['label'] ?? 'Adresse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address['street'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${address['postalCode'] ?? ''} ${address['city'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      value: addressId,
                      groupValue: selectedAddressId,
                      activeColor: const Color(0xFFDB816E),
                      onChanged: (value) => _updateSelectedAddress(value!),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showEditAddressForm(context, address),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _showDeleteAddressConfirmation(context, address),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  // Update the selected address in Firestore
  Future<void> _updateSelectedAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'selectedAddressId': addressId});
        
        setState(() {
          selectedAddressId = addressId;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse de livraison mise à jour'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print('Error updating selected address: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de l\'adresse'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // Show form to add a new address
  void _showAddAddressForm(BuildContext context) {
    final labelController = TextEditingController();
    final streetController = TextEditingController();
    final postalCodeController = TextEditingController();
    final cityController = TextEditingController();
    final additionalInfoController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ajouter une adresse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextFormField(
                    controller: labelController,
                    labelText: 'Étiquette (ex: Maison, Bureau)',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une étiquette';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextFormField(
                    controller: streetController,
                    labelText: 'Adresse',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextFormField(
                          controller: postalCodeController,
                          labelText: 'Code postal',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildTextFormField(
                          controller: cityController,
                          labelText: 'Ville',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextFormField(
                    controller: additionalInfoController,
                    labelText: 'Infos complémentaires (optionnel)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          Navigator.of(context).pop();
                          setState(() => isLoading = true);
                          
                          try {
                            final newAddress = {
                              'label': labelController.text,
                              'street': streetController.text,
                              'postalCode': postalCodeController.text,
                              'city': cityController.text,
                              'additionalInfo': additionalInfoController.text,
                              'createdAt': DateTime.now(),
                            };
                            
                            final docRef = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('addresses')
                                .add(newAddress);
                            
                            // If this is the first address, set it as selected
                            if (userAddresses.isEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'selectedAddressId': docRef.id});
                            }
                            
                            // Refresh the list of addresses
                            _fetchUserAddresses();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Adresse ajoutée avec succès'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            print('Error adding address: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de l\'ajout de l\'adresse'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() => isLoading = false);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB816E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Show form to edit an existing address
  void _showEditAddressForm(BuildContext context, Map<String, dynamic> address) {
    final labelController = TextEditingController(text: address['label']);
    final streetController = TextEditingController(text: address['street']);
    final postalCodeController = TextEditingController(text: address['postalCode']);
    final cityController = TextEditingController(text: address['city']);
    final additionalInfoController = TextEditingController(text: address['additionalInfo'] ?? '');
    
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Modifier l\'adresse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextFormField(
                    controller: labelController,
                    labelText: 'Étiquette (ex: Maison, Bureau)',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une étiquette';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextFormField(
                    controller: streetController,
                    labelText: 'Adresse',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une adresse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextFormField(
                          controller: postalCodeController,
                          labelText: 'Code postal',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildTextFormField(
                          controller: cityController,
                          labelText: 'Ville',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextFormField(
                    controller: additionalInfoController,
                    labelText: 'Infos complémentaires (optionnel)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          Navigator.of(context).pop();
                          setState(() => isLoading = true);
                          
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('addresses')
                                .doc(address['id'])
                                .update({
                              'label': labelController.text,
                              'street': streetController.text,
                              'postalCode': postalCodeController.text,
                              'city': cityController.text,
                              'additionalInfo': additionalInfoController.text,
                              'updatedAt': DateTime.now(),
                            });
                            
                            // Refresh the list of addresses
                            _fetchUserAddresses();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Adresse mise à jour avec succès'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            print('Error updating address: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de la mise à jour de l\'adresse'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() => isLoading = false);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB816E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Show confirmation dialog before deleting an address
  void _showDeleteAddressConfirmation(BuildContext context, Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Supprimer l\'adresse',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'adresse "${address['label']}" ?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  setState(() => isLoading = true);
                  
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('addresses')
                        .doc(address['id'])
                        .delete();
                    
                    // If the deleted address was selected, change selection
                    if (selectedAddressId == address['id'] && userAddresses.length > 1) {
                      final newSelectedId = userAddresses
                          .firstWhere((a) => a['id'] != address['id'])['id'];
                          
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'selectedAddressId': newSelectedId});
                    }
                    
                    // Refresh the list of addresses
                    _fetchUserAddresses();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adresse supprimée avec succès'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    print('Error deleting address: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la suppression de l\'adresse'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() => isLoading = false);
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to build text form fields with consistent styling
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    final profileFilters = ref.watch(profileFilterProvider);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1C1C1C),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color.fromARGB(255, 220, 206, 206)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '123 Rue du Resto...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Ouvert jusqu\'à 23 h',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserMenuPage()),
              );
            },
            child: const CircleAvatar(
              backgroundColor: Color(0xFFE4DF96),
              child: Text('CS'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF212529),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                    _buildAddressCard(),
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
                  
                    // Top-level toggle card
                    Card(
                      color: const Color(0xFF1C1C1C),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtrage des allergènes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Masquer automatiquement les recettes contenant des allergènes',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text(
                                'Activer le filtrage par allergènes',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: isAllergenFilterEnabled,
                              activeColor: const Color(0xFFDB816E),
                              activeTrackColor: const Color(0xFFDB816E).withOpacity(0.5),
                              onChanged: (value) {
                                ref.read(allergenFilterEnabledProvider.notifier).state = value;
                                
                                // Show feedback to user
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value 
                                      ? 'Filtrage des allergènes activé' 
                                      : 'Filtrage des allergènes désactivé'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      
                      // Profile toggle cards
                      if (familyProfiles.isEmpty)
                        const Card(
                          color: Color(0xFF1C1C1C),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Aucun profil trouvé. Ajoutez des profils dans le menu utilisateur.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 300, // Fixed height for the profiles list
                          child: ListView.builder(
                            itemCount: familyProfiles.length,
                            itemBuilder: (context, index) {
                              final profile = familyProfiles[index];
                              final profileId = profile['id'] as String;
                              final isEnabled = profileFilters[profileId] ?? true;
                              final List<dynamic> allergensList = profile['allergens'] ?? [];
                              
                              return Card(
                                color: const Color(0xFF1C1C1C),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(0xFFE4DF96),
                                            child: Text(_getInitials(profile['name'])),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  profile['name'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (profile['isMainUser'] == true)
                                                  const Text(
                                                    'Profil principal',
                                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: isEnabled,
                                            activeColor: const Color(0xFFDB816E),
                                            activeTrackColor: const Color(0xFFDB816E).withOpacity(0.5),
                                            onChanged: (value) {
                                              // Update the profile filters map
                                              final updatedFilters = Map<String, bool>.from(profileFilters);
                                              updatedFilters[profileId] = value;
                                              ref.read(profileFilterProvider.notifier).state = updatedFilters;
                                              
                                              // Show feedback
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(value 
                                                    ? 'Filtrage activé pour ${profile['name']}' 
                                                    : 'Filtrage désactivé pour ${profile['name']}'),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      if (allergensList.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Allergènes:',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                            allergensList.length,
                                            (index) => Chip(
                                              backgroundColor: isEnabled 
                                                  ? const Color(0xFFE4DF96) 
                                                  : Colors.grey[700],
                                              label: Text(
                                                allergensList[index],
                                                style: TextStyle(
                                                  color: isEnabled ? Colors.black : Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else
                                        const Padding(
                                          padding: EdgeInsets.only(top: 12.0),
                                          child: Text(
                                            'Aucun allergène signalé',
                                            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                    ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_location), label: 'Restaurant'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Panier'),
        ],
      ),
    );
  }
}