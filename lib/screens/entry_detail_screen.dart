import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/entry.dart';

class EntryDetailScreen extends StatelessWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  Future<void> _deleteEntry(BuildContext context) async {
    await DatabaseHelper.instance.deleteEntry(entry.id!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteEntry(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Category: ${entry.category}"),
            const SizedBox(height: 10),
            Text("Date: ${entry.date}"),
            const SizedBox(height: 20),
            Text(entry.description),
          ],
        ),
      ),
    );
  }
}
