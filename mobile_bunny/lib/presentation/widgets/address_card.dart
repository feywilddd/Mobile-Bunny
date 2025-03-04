import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/address_provider.dart';
import '../../data/models/address.dart';
import 'address_form_dialog.dart';

class AddressCard extends ConsumerWidget {
  const AddressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressProvider);
    
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
                  onPressed: () => _showAddAddressForm(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // List of addresses
            if (addressState.addresses.isEmpty)
              const Center(
                child: Text(
                  'Aucune adresse enregistrée',
                  style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              )
            else
              Column(
                children: addressState.addresses.map((address) {
                  final isSelected = addressState.selectedAddressId == address.id;
                  
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
                        address.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.street,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${address.postalCode} ${address.city}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      value: address.id,
                      groupValue: addressState.selectedAddressId,
                      activeColor: const Color(0xFFDB816E),
                      onChanged: (value) => _updateSelectedAddress(context, ref, value!),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showEditAddressForm(context, ref, address),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _showDeleteAddressConfirmation(context, ref, address),
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

  void _showAddAddressForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        onSave: (addressData) async {
          Navigator.of(context).pop();
          final success = await ref.read(addressProvider.notifier).addAddress(addressData);
          
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adresse ajoutée avec succès'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de l\'ajout de l\'adresse'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditAddressForm(BuildContext context, WidgetRef ref, Address address) {
    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        address: address,
        onSave: (addressData) async {
          Navigator.of(context).pop();
          final success = await ref.read(addressProvider.notifier).updateAddress(address.id, addressData);
          
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adresse mise à jour avec succès'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de la mise à jour de l\'adresse'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteAddressConfirmation(BuildContext context, WidgetRef ref, Address address) {
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
            'Êtes-vous sûr de vouloir supprimer l\'adresse "${address.label}" ?',
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
                final success = await ref.read(addressProvider.notifier).deleteAddress(address.id);
                
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adresse supprimée avec succès'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression de l\'adresse'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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

  void _updateSelectedAddress(BuildContext context, WidgetRef ref, String addressId) async {
    final success = await ref.read(addressProvider.notifier).setSelectedAddress(addressId);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse de livraison mise à jour'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (context.mounted) {
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