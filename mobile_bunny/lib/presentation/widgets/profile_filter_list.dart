import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/filter_provider.dart';
import '../../data/models/profile.dart';

class ProfileFilterList extends ConsumerWidget {
  const ProfileFilterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profileFilters = ref.watch(profileFilterProvider);
    
    if (profileState.profiles.isEmpty) {
      return const Card(
        color: Color(0xFF1C1C1C),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aucun profil trouvé. Ajoutez des profils dans le menu utilisateur.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 300, // Fixed height for the profiles list
      child: ListView.builder(
        itemCount: profileState.profiles.length,
        itemBuilder: (context, index) {
          final profile = profileState.profiles[index];
          final isEnabled = profileFilters[profile.id] ?? true;
          
          return _buildProfileCard(context, ref, profile, isEnabled);
        },
      ),
    );
  }
  
  Widget _buildProfileCard(
    BuildContext context, 
    WidgetRef ref,
    Profile profile,
    bool isEnabled,
  ) {
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
                  child: Text(_getInitials(profile.name)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.isMainUser)
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
                  onChanged: (value) => _updateProfileFilter(context, ref, profile, value),
                ),
              ],
            ),
            if (profile.allergens.isNotEmpty) ...[
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
                children: profile.allergens.map((allergen) => 
                  Chip(
                    backgroundColor: isEnabled 
                        ? const Color(0xFFE4DF96) 
                        : Colors.grey[700],
                    label: Text(
                      allergen,
                      style: TextStyle(
                        color: isEnabled ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ).toList(),
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
  
  void _updateProfileFilter(BuildContext context, WidgetRef ref, Profile profile, bool value) {
    // Update the profile filters map
    ref.read(profileFilterProvider.notifier).toggleProfileFilter(profile.id, value);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Filtrage activé pour ${profile.name}' 
          : 'Filtrage désactivé pour ${profile.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}