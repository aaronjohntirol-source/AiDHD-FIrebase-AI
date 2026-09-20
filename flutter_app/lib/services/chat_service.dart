import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageRecord {
  final String id;
  final bool isUser;
  final String text;
  final String time;

  const ChatMessageRecord({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
  });
}

class ChatService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String userId) =>
      _firestore.collection('users').doc(userId).collection('chat_messages');

  Future<List<ChatMessageRecord>> getMessages(String userId) async {
    final snapshot = await _messages(userId)
        .orderBy('createdAt', descending: false)
        .limitToLast(50)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return ChatMessageRecord(
            id: doc.id,
            isUser: data['role'] == 'user',
            text: data['text'] as String? ?? '',
            time: data['time'] as String? ?? '',
          );
        })
        .where((message) => message.text.isNotEmpty)
        .toList();
  }

  Future<void> saveMessage({
    required String userId,
    required String id,
    required bool isUser,
    required String text,
    required String time,
  }) async {
    await _messages(userId).doc(id).set({
      'role': isUser ? 'user' : 'model',
      'text': text,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
