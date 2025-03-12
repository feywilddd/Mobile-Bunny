import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/providers/address_provider.dart';
import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';

// Create a separate provider just for address operations to avoid UI rebuilds
final addressOperationsProvider = Provider<AddressOperations>((ref) {
  final repository = ref.watch(addressRepositoryProvider);
  return AddressOperations(repository);
});

// Class to handle address operations without triggering state changes directly
class AddressOperations {
  final AddressRepository _repository;
  
  AddressOperations(this._repository);
  
  Future<String?> addAddress(Map<String, dynamic> addressData) async {
    return _repository.addAddress(addressData);
  }
  
  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    return _repository.updateAddress(addressId, addressData);
  }
  
  Future<bool> deleteAddress(String addressId) async {
    return _repository.deleteAddress(addressId);
  }
  
  Future<bool> setSelectedAddress(String addressId) async {
    return _repository.setSelectedAddress(addressId);
  }
}

class AddressCard extends ConsumerWidget {
  const AddressCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressProvider);
    final addresses = addressState.addresses;
    final selectedAddressId = addressState.selectedAddressId;
    
    if (addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Text(
              'Aucune adresse enregistrée',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showAddAddressDialog(context, ref);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB816E),
                minimumSize: const Size.fromHeight(45),
              ),
            ),
          ],
        ),
      );
    }

    // Find the selected address
    final selectedAddress = selectedAddressId != null
        ? addresses.firstWhere(
            (a) => a.id == selectedAddressId,
            orElse: () => addresses.first,
          )
        : addresses.first;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: Text(
              selectedAddress.label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedAddress.street,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '${selectedAddress.postalCode}, ${selectedAddress.city}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (selectedAddress.additionalInfo.isNotEmpty)
                  Text(
                    selectedAddress.additionalInfo,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            trailing: TextButton(
              onPressed: () {
                _showAddressSelectionDialog(context, ref, addresses, selectedAddressId);
              },
              child: const Text(
                'Changer',
                style: TextStyle(color: Colors.white),
              ),
            ),
            isThreeLine: true,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                _showAddAddressDialog(context, ref);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB816E),
                minimumSize: const Size.fromHeight(45),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddressSelectionDialog(
    BuildContext context, 
    WidgetRef ref,
    List<Address> addresses,
    String? selectedAddressId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212529),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return _AddressSelectionSheet(
          addresses: addresses,
          selectedAddressId: selectedAddressId,
          onSelectAddress: (addressId) async {
            // Direct repository call for better reliability
            final repository = ref.read(addressRepositoryProvider);
            final success = await repository.setSelectedAddress(addressId);
            
            if (success) {
              // Force refresh after successful selection
              await ref.read(addressProvider.notifier).fetchUserAddresses();
            }
            return success;
          },
          onEditAddress: (address) {
            Navigator.pop(context);
            _showEditAddressDialog(context, ref, address);
          },
        );
      },
    );
  }

  void _showAddAddressDialog(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final streetController = TextEditingController();
    final postalCodeController = TextEditingController();
    final cityController = TextEditingController();
    final additionalInfoController = TextEditingController();
    
    // Use a separate stateful widget to manage local state
    showDialog(
      context: context,
      builder: (context) {
        return _AddressFormDialog(
          title: 'Ajouter une adresse',
          labelController: labelController,
          streetController: streetController,
          postalCodeController: postalCodeController,
          cityController: cityController,
          additionalInfoController: additionalInfoController,
          onSave: (addressData) async {
            // Use the operations provider to avoid UI rebuilds
            final operations = ref.read(addressOperationsProvider);
            final addressId = await operations.addAddress(addressData);
            
            // Refresh the provider state after the operation
            if (addressId != null) {
              await ref.read(addressProvider.notifier).fetchUserAddresses();
              return true;
            }
            return false;
          },
        );
      },
    );
  }

  void _showEditAddressDialog(BuildContext context, WidgetRef ref, Address address) {
    final labelController = TextEditingController(text: address.label);
    final streetController = TextEditingController(text: address.street);
    final postalCodeController = TextEditingController(text: address.postalCode);
    final cityController = TextEditingController(text: address.city);
    final additionalInfoController = TextEditingController(text: address.additionalInfo);

    showDialog(
      context: context,
      builder: (context) {
        return _AddressFormDialog(
          title: 'Modifier l\'adresse',
          labelController: labelController,
          streetController: streetController,
          postalCodeController: postalCodeController,
          cityController: cityController,
          additionalInfoController: additionalInfoController,
          onSave: (addressData) async {
            // Use the operations provider to avoid UI rebuilds
            final operations = ref.read(addressOperationsProvider);
            final success = await operations.updateAddress(address.id, addressData);
            
            // Refresh the provider state after the operation
            if (success) {
              await ref.read(addressProvider.notifier).fetchUserAddresses();
              return true;
            }
            return false;
          },
          onDelete: () async {
            final confirm = await _confirmDelete(context);
            if (confirm) {
              // Use the operations provider to avoid UI rebuilds
              final operations = ref.read(addressOperationsProvider);
              final success = await operations.deleteAddress(address.id);
              
              // Refresh the provider state after the operation
              if (success) {
                await ref.read(addressProvider.notifier).fetchUserAddresses();
                return true;
              }
            }
            return false;
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Confirmer la suppression',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette adresse ?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

// Separate widget for address selection to better manage local state
class _AddressSelectionSheet extends StatefulWidget {
  final List<Address> addresses;
  final String? selectedAddressId;
  final Future<bool> Function(String) onSelectAddress;
  final Function(Address) onEditAddress;

  const _AddressSelectionSheet({
    Key? key,
    required this.addresses,
    required this.selectedAddressId,
    required this.onSelectAddress,
    required this.onEditAddress,
  }) : super(key: key);

  @override
  _AddressSelectionSheetState createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<_AddressSelectionSheet> {
  String? processingAddressId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 16),
                  Text(
                    'Choisir une adresse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.addresses.length,
                itemBuilder: (context, index) {
                  final address = widget.addresses[index];
                  final isSelected = address.id == widget.selectedAddressId;
                  final isProcessing = address.id == processingAddressId;
                  
                  return ListTile(
                    leading: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              )
                            : const Icon(Icons.circle_outlined, color: Colors.white70),
                    title: Text(
                      address.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${address.street}, ${address.postalCode} ${address.city}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        widget.onEditAddress(address);
                      },
                    ),
                    onTap: isProcessing || isSelected ? null : () async {
                      setState(() {
                        processingAddressId = address.id;
                      });
                      
                      try {
                        final success = await widget.onSelectAddress(address.id);
                        
                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de la sélection de l\'adresse'),
                            ),
                          );
                          setState(() {
                            processingAddressId = null;
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                            ),
                          );
                          setState(() {
                            processingAddressId = null;
                          });
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Separate stateful widget for the address form to better manage local state
class _AddressFormDialog extends StatefulWidget {
  final String title;
  final TextEditingController labelController;
  final TextEditingController streetController;
  final TextEditingController postalCodeController;
  final TextEditingController cityController;
  final TextEditingController additionalInfoController;
  final Future<bool> Function(Map<String, dynamic>) onSave;
  final Future<bool> Function()? onDelete;

  const _AddressFormDialog({
    Key? key,
    required this.title,
    required this.labelController,
    required this.streetController,
    required this.postalCodeController,
    required this.cityController,
    required this.additionalInfoController,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  _AddressFormDialogState createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  bool isSubmitting = false;
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              widget.labelController,
              'Libellé (ex: Maison, Travail)',
              TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              widget.streetController,
              'Rue et numéro',
              TextInputType.streetAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              widget.postalCodeController,
              'Code postal',
              TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              widget.cityController,
              'Ville',
              TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              widget.additionalInfoController,
              'Informations complémentaires (optionnel)',
              TextInputType.text,
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 24),
              // Delete button
              TextButton(
                onPressed: isSubmitting || isDeleting ? null : () async {
                  setState(() => isDeleting = true);
                  try {
                    final success = await widget.onDelete!();
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      setState(() => isDeleting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors de la suppression de l\'adresse'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => isDeleting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Supprimer cette adresse'),
                      ],
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting || isDeleting ? null : () {
            Navigator.pop(context);
          },
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: isSubmitting || isDeleting ? null : () async {
            if (widget.streetController.text.isEmpty ||
                widget.postalCodeController.text.isEmpty ||
                widget.cityController.text.isEmpty ||
                widget.labelController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Veuillez remplir tous les champs')),
              );
              return;
            }

            setState(() => isSubmitting = true);

            final addressData = {
              'label': widget.labelController.text,
              'street': widget.streetController.text,
              'postalCode': widget.postalCodeController.text,
              'city': widget.cityController.text,
              'additionalInfo': widget.additionalInfoController.text,
            };

            try {
              final success = await widget.onSave(addressData);
              
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                } else {
                  setState(() => isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erreur lors de l\'opération')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                setState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Erreur: ${e.toString()}')),
                );
              }
            }
          },
          child: isSubmitting 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.green),
              ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF3D3D3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
    );
  }
}