import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/models/menu_item.dart';

final menuRepositoryProvider = Provider((ref) => MenuRepository());

final menuProvider = FutureProvider<List<MenuItem>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  return repository.fetchMenu();
});
