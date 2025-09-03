import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRepo {
  FirebaseFirestore getFirestoreInstance();

  Stream<List<Map<String, dynamic>>> getUsersStream();

  Future<void> sendMessage(String receiverId, message);

  Stream<QuerySnapshot> getMessages(String userId, otherUserId);

  Stream<QuerySnapshot> getChatRoomsForUser(String userEmail);
}
