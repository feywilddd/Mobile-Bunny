import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/user_menu_page.dart';

class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '123 Rue du Resto...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Ouvert jusqu\'à 23 h',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
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