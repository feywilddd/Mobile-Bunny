import 'package:flutter/material.dart';
import '../pages/preferences_page.dart';
import '../pages/restaurants_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class UserMenuPage extends ConsumerStatefulWidget {
  const UserMenuPage({super.key});

  @override
  ConsumerState<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends ConsumerState<UserMenuPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> familyProfiles = [];
  
  final List<String> commonAllergens = [
    'Gluten',
    'Lactose',
    'Arachides',
    'Fruits à coque',
    'Fruits de mer',
    'Soja',
    'Œufs',
    'Poisson',
  ];

  @override
  void initState() {
    super.initState();
    _fetchFamilyProfiles();
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
          setState(() {
            familyProfiles = snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();
            isLoading = false;
          });
        } else {
          // Create a default profile for the user if none exists
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          String displayName = 'Utilisateur';
          if (userDoc.exists) {
            final userData = userDoc.data();
            displayName = userData?['displayName'] ?? user.displayName ?? 'Utilisateur';
          }
          
          final defaultProfile = {
            'name': displayName,
            'isMainUser': true,
            'allergens': [],
            'createdAt': DateTime.now(),
          };
          
          final docRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('familyProfiles')
              .add(defaultProfile);
          
          setState(() {
            familyProfiles = [{
              'id': docRef.id,
              ...defaultProfile,
            }];
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching family profiles: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xFF212529),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMenuItem(context, Icons.settings, 'Préférences', const PreferencesPage()),
            _buildMenuItem(context, Icons.location_on, 'Restaurants', const RestaurantsPage()),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildFamilyProfilesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileForm(context),
        backgroundColor: const Color(0xFFDB816E),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }

  // Build the list of family profiles
  Widget _buildFamilyProfilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profils & Allergènes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: familyProfiles.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun profil trouvé. Créez un nouveau profil.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: familyProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = familyProfiles[index];
                    final List<dynamic> allergensList = profile['allergens'] ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: const Color(0xFF1C1C1C),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (profile['isMainUser'] == true)
                                        const Text(
                                          'Profil principal',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () => _showEditProfileForm(context, profile),
                                ),
                                if (!profile['isMainUser'])
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    onPressed: () => _showDeleteConfirmation(context, profile),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Allergènes:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            allergensList.isEmpty
                                ? const Text(
                                    'Aucun allergène signalé',
                                    style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      allergensList.length,
                                      (index) => Chip(
                                        backgroundColor: const Color(0xFFE4DF96),
                                        label: Text(
                                          allergensList[index],
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showEditProfileForm(context, profile),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDB816E),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Modifier',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
    );
  }

  // Show form to add a new profile
  void _showAddProfileForm(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<String> selectedAllergens = [];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        'Ajouter un profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Nom du profil',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Allergènes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: commonAllergens.map((allergen) {
                          final isSelected = selectedAllergens.contains(allergen);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(allergen),
                            selectedColor: const Color(0xFFE4DF96),
                            checkmarkColor: Colors.black,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedAllergens.add(allergen);
                                } else {
                                  selectedAllergens.remove(allergen);
                                }
                              });
                            },
                          );
                        }).toList(),
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
                                final newProfile = {
                                  'name': nameController.text,
                                  'isMainUser': false,
                                  'allergens': selectedAllergens,
                                  'createdAt': DateTime.now(),
                                };
                                
                                final docRef = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('familyProfiles')
                                    .add(newProfile);
                                
                                // Refresh the list of profiles
                                _fetchFamilyProfiles();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profil ajouté avec succès'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                print('Error adding profile: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur lors de l\'ajout: $e'),
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
      },
    );
  }

  // Show form to edit an existing profile
  void _showEditProfileForm(BuildContext context, Map<String, dynamic> profile) {
    final nameController = TextEditingController(text: profile['name']);
    final formKey = GlobalKey<FormState>();
    
    // Create a copy of profile's current allergens to manipulate
    List<String> selectedAllergens = List<String>.from(profile['allergens'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        'Modifier le profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Nom du profil',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Allergènes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: commonAllergens.map((allergen) {
                          final isSelected = selectedAllergens.contains(allergen);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(allergen),
                            selectedColor: const Color(0xFFE4DF96),
                            checkmarkColor: Colors.black,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedAllergens.add(allergen);
                                } else {
                                  selectedAllergens.remove(allergen);
                                }
                              });
                            },
                          );
                        }).toList(),
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
                                    .collection('familyProfiles')
                                    .doc(profile['id'])
                                    .update({
                                  'name': nameController.text,
                                  'allergens': selectedAllergens,
                                  'updatedAt': DateTime.now(),
                                });
                                
                                // Refresh the list of profiles
                                _fetchFamilyProfiles();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profil mis à jour avec succès'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                print('Error updating profile: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur lors de la mise à jour: $e'),
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
      },
    );
  }

  // Show confirmation dialog before deleting a profile
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Supprimer le profil',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le profil "${profile['name']}" ?',
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
                        .collection('familyProfiles')
                        .doc(profile['id'])
                        .delete();
                    
                    // Refresh the list of profiles
                    _fetchFamilyProfiles();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil supprimé avec succès'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    print('Error deleting profile: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression: $e'),
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

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget page) {
    return Card(
      color: const Color(0xFF1C1C1C),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
      ),
    );
  }
}