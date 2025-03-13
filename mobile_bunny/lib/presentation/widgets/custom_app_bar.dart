import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_bunny/data/models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../pages/login_page.dart';
import '../pages/user_menu_page.dart';

class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final bool showArrow;
  
  const CustomAppBar({super.key, this.showArrow = false});

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  String? mainProfileInitials;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Fetch initials after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileInitials();
    });
  }
  
  // Listen for auth changes and update initials accordingly
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.watch(authProvider);
    
    // When user changes, update initials
    if (user != null && !isLoading) {
      _fetchProfileInitials();
    }
  }
  
  Future<void> _fetchProfileInitials() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => isLoading = true);
    
    try {
      // Try to get user profiles from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('familyProfiles')
          .where('isMainUser', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final mainProfile = snapshot.docs.first.data();
        final initials = _getInitials(mainProfile['name'] ?? '');
        
        if (mounted) {
          setState(() {
            mainProfileInitials = initials;
            isLoading = false;
          });
        }
      } else {
        // Try to get from user document
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        String displayName = user.displayName ?? 'Utilisateur';
        if (userDoc.exists) {
          final userData = userDoc.data();
          displayName = userData?['displayName'] ?? displayName;
        }
        
        if (mounted) {
          setState(() {
            mainProfileInitials = _getInitials(displayName);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching profile initials: $e');
      if (mounted) {
        setState(() {
          // Fallback to Firebase user display name or email
          mainProfileInitials = _getInitials(user.displayName ?? user.email?.split('@')[0] ?? 'U');
          isLoading = false;
        });
      }
    }
  }
  
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
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1C),
      title: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFDE0000)),
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              final restaurantState = ref.watch(restaurantProvider);
              final selectedId = restaurantState.selectedRestaurantId;
              
              if (selectedId == null) {
                return const Text(
                  'Aucun restaurant sélectionné',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }
              
              // Since we know the ID exists but the restaurant isn't in the list,
              // fetch it directly from Firestore every time
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Restaurants')
                    .doc(selectedId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Chargement...',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'Restaurant non disponible',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    );
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) {
                    return const Text(
                      'Données non disponibles',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    );
                  }
                  
                  final String fullAddress = data['address'] ?? 'Adresse inconnue';
                  final String address = fullAddress.length > 25 
                      ? '${fullAddress.substring(0, 22)}...' 
                      : fullAddress;
                  
                  // Get the opening and closing times from Firestore
final openingTimeRaw = data['opening_time'];
final closingTimeRaw = data['closing_time'];

// Format the times and determine if the restaurant is currently open
String openingTime = 'N/A';
String closingTime = 'N/A';
bool isOpen = false;

try {
  if (openingTimeRaw is Timestamp && closingTimeRaw is Timestamp) {
    // Convert Timestamps to DateTime objects
    final opening = openingTimeRaw.toDate();
    final closing = closingTimeRaw.toDate();
    
    // Format times for display
    openingTime = '${opening.hour}:${opening.minute.toString().padLeft(2, '0')}';
    closingTime = '${closing.hour}:${closing.minute.toString().padLeft(2, '0')}';
    
    // Get current time
    final now = DateTime.now();
    final currentTimeOfDay = DateTime(
      opening.year, 
      opening.month, 
      opening.day, 
      now.hour, 
      now.minute
    );
    
    // Determine if restaurant is open (compare only hours and minutes)
    isOpen = currentTimeOfDay.isAfter(opening) && currentTimeOfDay.isBefore(closing);
  }
} catch (e) {
  print('Error determining open status: $e');
}
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        isOpen ? 'Ouvert jusqu\'à $closingTime' : 'Fermé - Ouvre à $openingTime',
                        style: TextStyle(fontSize: 12, color: isOpen ? Colors.green : Colors.red),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      leading: widget.showArrow
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : null,
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserMenuPage()),
            ).then((_) {
              // Refresh initials when returning from UserMenuPage
              _fetchProfileInitials();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE4DF96)),
                )
              : CircleAvatar(
                  backgroundColor: const Color(0xFFE4DF96),
                  child: Text(mainProfileInitials ?? '?'),
                ),
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
    );
  }
}
