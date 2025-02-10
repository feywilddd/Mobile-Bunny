import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

final databaseProvider = Provider<DatabaseReference>((ref) {
  return FirebaseDatabase.instance.ref();
});

final dataProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    return data?.cast<String, dynamic>() ?? {};
  });
});

void writeData(DatabaseReference database, String key, String value) {
  database.child(key).set(value).then((_) {
    print('Data written successfully: $key -> $value');
  }).catchError((error) {
    print('Failed to write data: $error');
  });
}
