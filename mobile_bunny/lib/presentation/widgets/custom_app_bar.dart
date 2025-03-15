import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileInitials();
    });
  }
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.watch(authProvider);
    

    if (user != null && !isLoading) {
      _fetchProfileInitials();
    }
  }
  
  Future<void> _fetchProfileInitials() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => isLoading = true);
    
    try {

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
      title: Flexible(
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFDE0000)),
            const SizedBox(width: 8),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final restaurantState = ref.watch(restaurantProvider);
                  final selectedId = restaurantState.selectedRestaurantId;
                  
                  if (selectedId == null) {
                    return const Text(
                      'Aucun restaurant sélectionné',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    );
                  }
             
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
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          'Restaurant non disponible',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null) {
                        return const Text(
                          'Données non disponibles',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      
                      final String fullAddress = data['address'] ?? 'Adresse inconnue';
                      final String address = fullAddress.length > 20 
                          ? '${fullAddress.substring(0, 17)}...' 
                          : fullAddress;
                     
                      final openingTimeRaw = data['opening_time'];
                      final closingTimeRaw = data['closing_time'];

                      String openingTime = 'N/A';
                      String closingTime = 'N/A';
                      bool isOpen = false;

                      try {
                        if (openingTimeRaw is Timestamp && closingTimeRaw is Timestamp) {
                   
                          final opening = openingTimeRaw.toDate();
                          final closing = closingTimeRaw.toDate();
                          
                         
                          openingTime = '${opening.hour}:${opening.minute.toString().padLeft(2, '0')}';
                          closingTime = '${closing.hour}:${closing.minute.toString().padLeft(2, '0')}';
                          
                
                          final now = DateTime.now();
                    
                          final currentHour = now.hour;
                          final currentMinute = now.minute;
                          
                   
                          final isAfterOpening = currentHour > opening.hour || 
                                              (currentHour == opening.hour && currentMinute >= opening.minute);
                          
                          final isBeforeClosing = currentHour < closing.hour || 
                                               (currentHour == closing.hour && currentMinute <= closing.minute);
                          
                        
                          isOpen = isAfterOpening && isBeforeClosing;
                        }
                      } catch (e) {
                        print('Error determining open status: $e');
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            address,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isOpen ? 'Ouvert jusqu\'à $closingTime' : 'Fermé - Ouvre à $openingTime',
                            style: TextStyle(fontSize: 12, color: isOpen ? Colors.green : Colors.red),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      leading: widget.showArrow
          ? IconButton(
              icon: Icon(
                Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                color: Colors.white
              ),
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
              Platform.isIOS
                ? CupertinoPageRoute(builder: (context) => const UserMenuPage())
                : MaterialPageRoute(builder: (context) => const UserMenuPage()),
            ).then((_) {
              
              _fetchProfileInitials();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE4DF96)),
                    strokeWidth: 2.0,
                  ),
                )
              : CircleAvatar(
                  backgroundColor: const Color(0xFFE4DF96),
                  radius: 16,
                  child: Text(
                    mainProfileInitials ?? '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                ),
          ),
        ),
        IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.square_arrow_right : Icons.logout,
            color: Colors.white,
          ),
          onPressed: () async {
            // Show confirmation dialog using appropriate platform style
            bool confirm = await _showLogoutConfirmationDialog(context);
            if (confirm) {
              await ref.read(authProvider.notifier).signOut();
              Navigator.pushReplacement(
                context,
                Platform.isIOS
                  ? CupertinoPageRoute(builder: (context) => const LoginPage())
                  : MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
        ),
      ],
    );
  }
  
  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    if (Platform.isIOS) {
      return await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Déconnecter'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ?? false;
    } else {
      return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ?? false;
    }
  }
}