import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a provider for the counter state
final counterProvider = StateProvider<int>((ref) => 0);