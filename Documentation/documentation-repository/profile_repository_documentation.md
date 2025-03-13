# Documentation sur les méthodes de `ProfileRepository`

## 1. fetchProfiles()

### Description:

Récupère tous les profils associés à l'utilisateur authentifié actuel.

### Parameters:

Aucun

### Returns:

- `List<Profile>`: Une liste d'objets `Profile` représentant les profils de l'utilisateur.

### Exemple d'utilisation:

``` dart
List<Profile> profiles = await profileRepository.fetchProfiles();
```

## 2. addProfile(Map<String, dynamic> profileData)

### Description:

Ajoute un nouveau profil pour l'utilisateur authentifié.

### Parameters:

- `profileData` (`Map<String, dynamic>`): Une carte contenant les données du profil à ajouter.

### Returns:

- `String?`: L'ID du profil nouvellement ajouté, ou `null` si l'opération échoue.

### Exemple d'utilisation:

``` dart
String? profileId = await profileRepository.addProfile(profileData);
```

## 3. updateProfile(String profileId, Map<String, dynamic> profileData)

### Description:

Met à jour un profil existant pour l'utilisateur authentifié.

### Parameters:

- `profileId` (`String`): L'ID du profil à mettre à jour.
- `profileData` (`Map<String, dynamic>`): Une carte contenant les nouvelles données du profil.

### Returns:

- `bool`: `true` si le profil a été mis à jour avec succès, `false` sinon.

### Exemple d'utilisation:

``` dart
bool success = await profileRepository.updateProfile(profileId, profileData);
```

## 4. deleteProfile(String profileId)

### Description:

Supprime un profil pour l'utilisateur authentifié.

### Parameters:

- `profileId` (`String`): L'ID du profil à supprimer.

### Returns:

- `bool`: `true` si le profil a été supprimé avec succès, `false` sinon.

### Exemple d'utilisation:

```dart
bool success = await profileRepository.deleteProfile(profileId);
```

## 5. addAllergens(String profileId, List< String > allergens)

### Description:

Ajoute des allergènes à un profil existant pour l'utilisateur authentifié. Les allergènes sont ajoutés sans doublons.

### Parameters:

- `profileId` (`String`): L'ID du profil à mettre à jour.
- `allergens` (`List<String>`): Une liste d'allergènes à ajouter.

### Returns:

- `bool`: `true` si les allergènes ont été ajoutés avec succès, `false` sinon.

### Exemple d'utilisation:

``` dart
bool success = await profileRepository.addAllergens(profileId, allergens);
```

## 6. removeAllergens(String profileId, List< String> allergens)

### Description:

Supprime des allergènes d'un profil existant pour l'utilisateur authentifié.

### Parameters:

- `profileId` (`String`): L'ID du profil à mettre à jour.
- `allergens` (`List<String>`): Une liste d'allergènes à supprimer.

### Returns:

- `bool`: `true` si les allergènes ont été supprimés avec succès, `false` sinon.

### Exemple d'utilisation:

``` dart
bool success = await profileRepository.removeAllergens(profileId, allergens);
```
