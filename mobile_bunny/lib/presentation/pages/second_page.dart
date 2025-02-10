import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';
import 'package:uuid/uuid.dart';

class SecondPage extends ConsumerStatefulWidget {
  const SecondPage({super.key});

  @override
  ConsumerState<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends ConsumerState<SecondPage> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final Uuid _uuid = Uuid(); // For generating UUIDs

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Enter Key (UUID)',
                hintText: 'Leave empty to auto-generate UUID',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Enter Value',
                hintText: 'Enter the value to store',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final key = _keyController.text.trim().isEmpty
                    ? _uuid.v4() // Generate a UUID if the field is empty
                    : _keyController.text.trim();
                final value = _valueController.text.trim();

                if (value.isNotEmpty) {
                  writeData(database, key, value);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a value')),
                  );
                }
              },
              child: Text('Save and Go Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}


