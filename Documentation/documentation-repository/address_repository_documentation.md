
# Documentation sur les méthodes de `AddressRepository` 

## 1. fetchAddresses()
### Description:
Récupère toutes les adresses de l'utilisateur authentifié actuel.

### Parameters:
Aucun

### Returns:
- `List<Address>`: Une liste d'objets d'adresse.

### Example usage:
```dart
List<Address> addresses = await addressRepository.fetchAddresses();
```

## 2. getSelectedAddressId()
### Description:
Obtient l'identifiant de l'adresse actuellement sélectionnée pour l'utilisateur authentifié.

### Parameters:
Aucun

### Returns:
- `String?`:  L'ID de l'adresse sélectionnée, ou `null` si aucune adresse n'est sélectionnée.
### Example usage:
```dart
String? selectedAddressId = await addressRepository.getSelectedAddressId();
```

## 3. addAddress(Map<String, dynamic> addressData)
### Description:
Ajoute une nouvelle adresse pour l'utilisateur authentifié.

### Parameters:
- `addressData` (`Map<String, dynamic>`): Une carte contenant les données d'adresse.

### Returns:
- `String?`: L'ID de l'adresse nouvellement ajoutée, ou `null` si l'opération échoue.

### Example usage:
```dart
String? addressId = await addressRepository.addAddress(addressData);
```

## 4. updateAddress(String addressId, Map<String, dynamic> addressData)
### Description:
Met à jour une adresse existante pour l'utilisateur authentifié.

### Parameters:
- `addressId` (`String`): L'ID de l'adresse à mettre à jour.
- `addressData` (`Map<String, dynamic>`): Une carte contenant les nouvelles données d'adresse.

### Returns:
- `bool`: `true` si l'adresse a été mise à jour avec succès, `false` sinon.

### Example usage:
```dart
bool success = await addressRepository.updateAddress(addressId, addressData);
```

## 5. deleteAddress(String addressId)
### Description:
Supprime une adresse pour l'utilisateur authentifié.

### Parameters:
- `addressId` (`String`): L'ID de l'adresse à supprimer.

### Returns:
- `bool`: `true` si l'adresse a été supprimée avec succès, `false` sinon.

### Example usage:
```dart
bool success = await addressRepository.deleteAddress(addressId);
```

## 6. setSelectedAddress(String addressId)
### Description:
Définit l'adresse sélectionnée pour l'utilisateur authentifié.

### Parameters:
- `addressId` (`String`): L'ID de l'adresse à définir comme sélectionnée.

### Returns:
- `bool`: `true` si l'adresse sélectionnée a été définie avec succès, `false` sinon.

### Example usage:
```dart
bool success = await addressRepository.setSelectedAddress(addressId);
```
