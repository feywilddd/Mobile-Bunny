import 'package:flutter/material.dart';

class DataList extends StatelessWidget {
  final Map<String, dynamic> data;

  const DataList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key];
        return ListTile(
          title: Text(key),
          subtitle: Text(value.toString()),
        );
      },
    );
  }
}
