import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load the .env file asynchronously
    await dotenv.load(fileName: ".env");
    print("✅ .env file loaded successfully!");

    // Try accessing a variable to confirm it's loaded
    print("API Key: ${dotenv.env['API_KEY']}");
  } catch (e) {
    print("❌ Error loading .env file: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(  // Wrap the entire app with ProviderScope
      child: MaterialApp(
        title: 'Bunny&Co',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(),
      ),
    );
  }
}
