import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedMood = "😊";
  DateTime _selectedDate = DateTime.now();

  final List<String> _moods = ["😊", "😢", "😡", "😴", "🤩", "😎"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? "");
    _descController =
        TextEditingController(text: widget.entry?.description ?? "");
    _selectedCategory = widget.entry?.category ?? "Routine";
    _selectedMood = widget.entry?.mood ?? "😊"; // mood load kare edit mode mein
    _selectedDate = widget.entry != null
        ? DateTime.tryParse(widget.entry!.date) ?? DateTime.now()
        : DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in!")),
        );
        return;
      }

      final entry = Entry(
        id: widget.entry?.id,
        userId: widget.entry?.userId ?? userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate.toIso8601String(), // ✅ selected date save
        mood: _selectedMood, // ✅ mood save
        isSynced: false,
      );

      if (widget.entry == null) {
        // 👉 Insert
        int id = await DatabaseHelper.instance.insertEntry(entry);
        print("Inserted Entry ID: $id");
      } else {
        // 👉 Update
        int count = await DatabaseHelper.instance.updateEntry(entry);
        print("Updated Entry Count: $count");
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving entry: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry == null ? "Add Entry" : "Edit Entry",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 16),

              /// Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              /// Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ["Routine", "Work", "Exercise", "Schedule"]
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              /// Date Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Pick"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Mood Picker
              Text("Mood", style: GoogleFonts.poppins(fontSize: 16)),
              Wrap(
                spacing: 8,
                children: _moods
                    .map(
                      (mood) => ChoiceChip(
                    label: Text(mood, style: const TextStyle(fontSize: 20)),
                    selected: _selectedMood == mood,
                    onSelected: (_) =>
                        setState(() => _selectedMood = mood),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 24),

              /// Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    widget.entry == null ? "Add Entry" : "Update Entry",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
