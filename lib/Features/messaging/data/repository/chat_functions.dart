import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/Features/messaging/data/model/message.dart';
import 'package:yappsters/Features/messaging/domain/repository/chat_repo.dart';

class ChatFunctions implements ChatRepo {
  AuthFunctions _auth = AuthFunctions();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  FirebaseFirestore getFirestoreInstance() {
    final FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
    return firestoreInstance;
  }

  @override
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final FirebaseFirestore storeInstance = getFirestoreInstance();
    return storeInstance.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Stream<QuerySnapshot> getChatRoomsForUser(String currentUserId) {
    return _firestore
        .collection('ChatRooms')
        .where('', arrayContains: currentUserId)
        .snapshots();
  }

  @override
  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _auth.getCurrentUser()!.uid;
    final String currentUserEmail = _auth.getCurrentUser()!.email!;
    final Timestamp timestamp = Timestamp.now();

    //create message
    Message _message = Message(
      timestamp: timestamp,
      msg: message,
      receiverId: receiverId,
      senderId: currentUserId,
      senderEmail: currentUserEmail,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');
    await _firestore
        .collection("ChatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(_message.toMap());

    //get message
  }

  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    //construct chatroom id for both users
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');
    return _firestore
        .collection("ChatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  void listenForNewMessages(String userId, otherUserId,Function showNotification ,String currentUserEmail) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');
    _firestore
        .collection('ChatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      for (DocumentChange change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> messageData =
              change.doc.data() as Map<String, dynamic>;
          String senderEmail = messageData['senderEmail'];

          if (senderEmail != currentUserEmail) {
            String messageText = messageData['msg'];
            String senderName = senderEmail
                .split('@')[0]; // Assuming email format is name@example.com

            showNotification(senderName, messageText);
          }
        }
      }
    });
  }
}
