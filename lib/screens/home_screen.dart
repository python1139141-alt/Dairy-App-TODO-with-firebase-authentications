import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/database_helper.dart';
import '../models/entry.dart';
import '../services/sync_service.dart';
import 'add_edit_entry_screen.dart';
import 'entry_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const HomeScreen({Key? key, this.onToggleTheme, this.isDark = false})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SyncService _syncService = SyncService();
  
  List<Entry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _autoSync();
  }

  Future<void> _autoSync() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Firestore sending data
    await _syncService.syncEntries(userId);
    // Firestore latest fetch karna
    await _syncService.fetchEntriesFromFirestore(userId);
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final entries = await DatabaseHelper.instance.getEntries(userId);
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      debugPrint("Error loading entries: $e");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }


  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openAddEditScreen({Entry? entry}) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; //pass uid
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditEntryScreen(entry: entry, userId: userId)),
    );
    if (result == true) await _autoSync();
  }

  Future<void> _openDetailScreen(Entry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
    );
    if (result == true || result == null) await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mindspace Diary"),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: widget.isDark ? "Switch to light" : "Switch to dark",
              icon:
              Icon(widget.isDark ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: widget.onToggleTheme,
            ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const Center(child: Text("No entries yet"))
          : RefreshIndicator(
        onRefresh: _loadEntries,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300,
                            // Colors.red.shade200,
                            Colors.purple.shade200,
                            Colors.yellow.shade300,
                            Colors.green.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          entry.isSynced
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: entry.isSynced
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 30,
                        ),
                        title: Text(
                          entry.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          "${entry.category} • ${entry.date.split('T').first}",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        onTap: () => _openDetailScreen(entry),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.white,
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditEntryScreen(entry: entry),
                                  ),
                                );

                                if (updated == true) {
                                  _loadEntries();
                                }
                              },
                            ),

                            IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                onPressed: () async {
                                  final ok =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Delete"),
                                      content: const Text(
                                          "Delete this entry?"),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, false),
                                            child:
                                            const Text("Cancel")),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, true),
                                            child: const Text(
                                                "Delete")),
                                      ],

                                    ),
                                  );
                                  if (ok == true) {
                                    final userId = FirebaseAuth.instance.currentUser!.uid;

                                    // Local DB  delete
                                    await DatabaseHelper.instance.deleteEntry(entry.id!);


                                    // Firestore delete (If sync entry)
                                    if (entry.isSynced && entry.id != null) {
                                      await _syncService.deleteEntryFromFirestore(userId, entry.id!.toString());
                                    }
                                    await _loadEntries();
                                  }
                                }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () => _openAddEditScreen(),
          icon: const Icon(Icons.add),
          label: const Text("Add More"),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50)),
        ),
      ),
    );
  }
}
