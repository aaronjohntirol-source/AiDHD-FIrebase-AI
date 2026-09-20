import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/history_entry.dart';

class HistoryService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entries(String userId) =>
      _firestore.collection('users').doc(userId).collection('history');

  Future<List<HistoryEntry>> getHistory(String userId) async {
    final snapshot =
        await _entries(userId).orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      return HistoryEntry.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<void> saveHistory(String userId, List<HistoryEntry> entries) async {
    final batch = _firestore.batch();
    final collection = _entries(userId);
    final existing = await collection.get();
    for (final document in existing.docs) {
      batch.delete(document.reference);
    }
    for (final entry in entries) {
      batch.set(collection.doc(entry.id), entry.toJson());
    }
    await batch.commit();
  }

  Future<void> addEntry(String userId, HistoryEntry entry) async {
    await _entries(userId).doc(entry.id).set(entry.toJson());
  }
}
