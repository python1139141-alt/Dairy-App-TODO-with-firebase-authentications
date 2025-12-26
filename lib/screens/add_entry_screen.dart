import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/database_helper.dart';
import '../models/entry.dart';

class AddEditEntryScreen extends StatefulWidget {
  final Entry? entry;
  final String? userId;

  const AddEditEntryScreen({super.key, this.entry, this.userId});

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = "Routine";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? "");
    _descController =
        TextEditingController(text: widget.entry?.description ?? "");
    _selectedCategory = widget.entry?.category ?? "Routine";
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      // Use the provided userId or fallback to current logged-in user
      final userId =
          widget.userId ?? FirebaseAuth.instance.currentUser!.uid;

      final entry = Entry(
        id: widget.entry?.id, // preserve id if editing
        userId: widget.entry?.userId ?? userId, // ensure correct user
        title: _titleController.text,
        description: _descController.text,
        category: _selectedCategory,
        date: DateTime.now().toIso8601String(),
        isSynced: false, // new entries are unsynced by default
      );

      if (widget.entry == null) {
        await DatabaseHelper.instance.insertEntry(entry);
      } else {
        await DatabaseHelper.instance.updateEntry(entry);
      }

      if (!mounted) return;
      Navigator.pop(context, true); // return true to refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? "Add Entry" : "Edit Entry"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ["Routine", "Work", "Exercise", "Schedule"]
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEntry,
                child: Text(widget.entry == null ? "Add" : "Update"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
