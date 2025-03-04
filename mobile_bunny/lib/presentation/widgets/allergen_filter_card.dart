import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_provider.dart';

class AllergenFilterCard extends ConsumerWidget {
  const AllergenFilterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAllergenFilterEnabled = ref.watch(allergenFilterEnabledProvider);
    
    return Card(
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
    );
  }
}