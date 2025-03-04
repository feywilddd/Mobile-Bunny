import 'package:flutter/material.dart';
import '../../data/models/address.dart';

class AddressFormDialog extends StatefulWidget {
  final Address? address;
  final Function(Map<String, dynamic> addressData) onSave;

  const AddressFormDialog({
    super.key,
    this.address,
    required this.onSave,
  });

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final formKey = GlobalKey<FormState>();
  
  late final TextEditingController labelController;
  late final TextEditingController streetController;
  late final TextEditingController postalCodeController;
  late final TextEditingController cityController;
  late final TextEditingController additionalInfoController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    labelController = TextEditingController(text: widget.address?.label ?? '');
    streetController = TextEditingController(text: widget.address?.street ?? '');
    postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '');
    cityController = TextEditingController(text: widget.address?.city ?? '');
    additionalInfoController = TextEditingController(text: widget.address?.additionalInfo ?? '');
  }

  @override
  void dispose() {
    labelController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    cityController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    
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
              Text(
                isEditing ? 'Modifier l\'adresse' : 'Ajouter une adresse',
                style: const TextStyle(
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
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB816E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Enregistrer' : 'Ajouter',
                  style: const TextStyle(
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
  }

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

  void _submitForm() {
    if (formKey.currentState!.validate()) {
      widget.onSave({
        'label': labelController.text,
        'street': streetController.text,
        'postalCode': postalCodeController.text,
        'city': cityController.text,
        'additionalInfo': additionalInfoController.text,
      });
    }
  }
}