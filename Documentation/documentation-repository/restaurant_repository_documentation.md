# Documentation sur les méthodes de RestaurantRepository

## 1. fetchRestaurants()

### Description:

Récupère tous les restaurants disponibles.

### Parameters:

Aucun

### Returns:

- List< Restaurant>: Une liste d'objets restaurant.

### Example usage:

``` dart 
List<Restaurant> restaurants = await restaurantRepository.fetchRestaurants();
```

## 2. fetchRestaurantById(String restaurantId)

### Description:

Récupère un restaurant spécifique en fonction de son ID.

### Parameters:

- restaurantId (String): L'ID du restaurant à récupérer.

### Returns:

- Restaurant?: Un objet Restaurant, ou null si le restaurant n'existe pas.

### Example usage:

``` dart 
Restaurant? restaurant = await restaurantRepository.fetchRestaurantById(restaurantId);
```

## 3. getSelectedRestaurantId()

### Description:

Obtient l'ID du restaurant actuellement sélectionné pour l'utilisateur authentifié.

### Parameters:

Aucun

### Returns:

- String?: L'ID du restaurant sélectionné, ou null si aucun restaurant n'est sélectionné.

### Example usage:

``` dart 
String? selectedRestaurantId = await restaurantRepository.getSelectedRestaurantId();
```

## 4. getSelectedRestaurant()

### Description:

Récupère le restaurant actuellement sélectionné pour l'utilisateur authentifié.

### Parameters:

Aucun

### Returns:

- Restaurant?: Un objet Restaurant, ou null si aucun restaurant n'est sélectionné.

### Example usage:

``` dart
Restaurant? selectedRestaurant = await restaurantRepository.getSelectedRestaurant();
```

## 5. setSelectedRestaurant(String restaurantId)

### Description:

Définit le restaurant sélectionné pour l'utilisateur authentifié.

### Parameters:

- restaurantId (String): L'ID du restaurant à définir comme sélectionné.

### Returns:

- bool: true si le restaurant sélectionné a été défini avec succès, false sinon.

### Example usage:

``` dart
bool success = await restaurantRepository.setSelectedRestaurant(restaurantId);
```

## 6. clearSelectedRestaurant()

### Description:

Supprime le restaurant sélectionné pour l'utilisateur authentifié.

### Parameters:

Aucun

### Returns:

- bool: true si le restaurant sélectionné a été supprimé avec succès, false sinon.

### Example usage:

``` dart
bool success = await restaurantRepository.clearSelectedRestaurant();
```
