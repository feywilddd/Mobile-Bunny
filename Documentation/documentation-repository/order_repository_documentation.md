# Documentation sur les méthodes de `OrderRepository`

## 1. getActiveOrder()

### Description:

Récupère la commande active de l'utilisateur actuellement connecté.

### Parameters:

Aucun

### Returns:

- `models.Order?`: La commande active de l'utilisateur, ou `null` si aucune commande active n'est trouvée.

### Example usage:

```dart
models.Order? activeOrder = await orderRepository.getActiveOrder();
```

## 2. streamActiveOrder()

### Description:

Retourne un flux qui émet la commande active en temps réel chaque fois qu'elle change.

### Parameters:

Aucun

### Returns:

- `Stream<models.Order?>`: Un flux émettant la commande active de l'utilisateur.

### Example usage:

```dart
Stream<models.Order?> activeOrderStream = orderRepository.streamActiveOrder();
```

## 3. createOrder()

### Description:

Crée une nouvelle commande en utilisant le restaurant sélectionné et l'adresse de livraison.

### Parameters:

Aucun

### Returns:

- `models.Order`: L'objet de commande créé.

### Example usage:


``` dart
models.Order newOrder = await orderRepository.createOrder();
```

## 4. updateOrder(models.Order updatedOrder)

### Description:

Met à jour une commande existante avec de nouvelles données.

### Parameters:

- `updatedOrder` (`models.Order`): L'objet de commande mis à jour.

### Returns:

- `models.Order`: L'objet de commande mis à jour.

### Example usage:

```dart
models.Order updatedOrder = await orderRepository.updateOrder(updatedOrder);
```

## 5. addItemToOrder(MenuItem menuItem, {int quantity = 1})

### Description:

Ajoute un article au panier de la commande active. Si aucune commande active n'existe, une nouvelle commande est créée.

### Parameters:

- `menuItem` (`MenuItem`): L'élément du menu à ajouter à la commande.
- `quantity` (`int`, optionnel): La quantité de l'élément à ajouter, par défaut 1.

### Returns:

- `models.Order?`: La commande mise à jour avec l'article ajouté.

### Example usage:


``` dart
models.Order? updatedOrder = await orderRepository.addItemToOrder(menuItem, quantity: 2);
```

## 6. updateItemQuantity(String menuItemId, int quantity)

### Description:

Met à jour la quantité d'un article dans la commande active.

### Parameters:

- `menuItemId` (`String`): L'ID de l'article à mettre à jour.
- `quantity` (`int`): La nouvelle quantité pour l'article.

### Returns:

- `models.Order?`: La commande mise à jour avec la nouvelle quantité.

### Example usage:

``` dart
models.Order? updatedOrder = await orderRepository.updateItemQuantity(menuItemId, 3);
```

## 7. removeItem(String menuItemId)

### Description:

Supprime un article de la commande active.

### Parameters:

- `menuItemId` (`String`): L'ID de l'article à supprimer de la commande.

### Returns:

- `models.Order?`: La commande mise à jour après la suppression de l'article.

### Example usage:

``` dart
`models.Order? updatedOrder = await orderRepository.removeItem(menuItemId);
```

## 8. updateOrderStatus(models.OrderStatus newStatus)

### Description:

Met à jour le statut d'une commande active.

### Parameters:

- `newStatus` (`models.OrderStatus`): Le nouveau statut de la commande (par exemple, "livrée", "annulée", etc.).

### Returns:

- `models.Order?`: La commande mise à jour avec le nouveau statut.

### Example usage:


``` dart 
models.Order? updatedOrder = await orderRepository.updateOrderStatus(models.OrderStatus.delivered);
```

## 9. completeActiveOrder()

### Description:

Complète la commande active, la déplaçant de la catégorie des commandes actives vers l'historique (livrée ou annulée).

### Parameters:

Aucun

### Returns:

- `Future<void>`: La méthode ne retourne rien.

### Example usage:

``` dart
await orderRepository.completeActiveOrder();
```

## 10. cancelActiveOrder()

### Description:

Annule la commande active et la marque comme "annulée" dans le système.

### Parameters:

Aucun

### Returns:

- `Future<void>`: La méthode ne retourne rien.

### Example usage:

``` dart 
await orderRepository.cancelActiveOrder();
```

## 11. getOrderHistory()

### Description:

Récupère l'historique des commandes pour un utilisateur donné, incluant seulement les commandes livrées ou annulées.

### Parameters:

Aucun

### Returns:

- `List<models.Order>`: Une liste des commandes de l'utilisateur avec statut "livré" ou "annulé".

### Example usage:

```dart
List<models.Order> orderHistory = await orderRepository.getOrderHistory();
```

## 12. isRestaurantSelected()

### Description:

Vérifie si un restaurant a été sélectionné par l'utilisateur.

### Parameters:

Aucun

### Returns:

- `bool`: `true` si un restaurant est sélectionné, `false` sinon.

### Example usage:

``` dart
bool isSelected = await orderRepository.isRestaurantSelected();
```
