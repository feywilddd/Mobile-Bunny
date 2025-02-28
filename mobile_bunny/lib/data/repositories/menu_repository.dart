import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MenuItem>> fetchMenu() async {
    final querySnapshot = await _firestore.collection('items').get();
    return querySnapshot.docs
        .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
        .toList();
  }
}
