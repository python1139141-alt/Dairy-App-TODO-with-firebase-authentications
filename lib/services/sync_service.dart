import 'package:cloud_firestore/cloud_firestore.dart';
import '../db/database_helper.dart';
import '../models/entry.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteEntryFromFirestore(String userId , String entryId) async {
    try{
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("entries")
          .doc(entryId)
          .delete();
    }catch(e){
      print("Error deleting entry from Firestore: $e");

    }
  }
  Future<void> syncEntries(String userId) async {
    try {
      final localEntries = await DatabaseHelper.instance.getEntries(userId);

      for (var entry in localEntries) {
        if (!entry.isSynced) {
          await _firestore
              .collection("users")
              .doc(userId)
              .collection("entries")
              .doc(entry.id.toString())
              .set({
            "id": entry.id,
            "userId": entry.userId,
            "title": entry.title,
            "description": entry.description,
            "category": entry.category,
            "date": entry.date,
            "imagePath": entry.imagePath,
          });

          await DatabaseHelper.instance.updateEntry(
            entry.copyWith(isSynced: true),
          );
        }
      }
    } catch (e) {
      print("Error syncing entries: $e");
    }
  }
    Future<void> fetchEntriesFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .doc(userId)
          .collection("entries")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final entry = Entry(
          id: int.tryParse(doc.id),
          title: data["title"] ?? "",
          description: data["description"] ?? "",
          date: data["date"] ?? "",
          category: data["category"] ?? "",
          isSynced: true,
          userId: userId,
        );

        await DatabaseHelper.instance.insertOrUpdateEntry(entry);
      }
    } catch (e) {
      print("Error fetching Firestore entries: $e");
    }
  }
}
