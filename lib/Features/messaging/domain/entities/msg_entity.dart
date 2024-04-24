import 'package:cloud_firestore/cloud_firestore.dart';

class MessageEntity {
  final String senderEmail;
  final String receiverId;
  final String senderId;
  final String msg;
  final Timestamp timestamp;

  MessageEntity({
    required this.senderEmail,
    required this.receiverId,
    required this.senderId,
    required this.msg,
    required this.timestamp,
  });
}
