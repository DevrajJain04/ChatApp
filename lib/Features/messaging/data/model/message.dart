import 'package:yappsters/Features/messaging/domain/entities/msg_entity.dart';

class Message extends MessageEntity {
  Message({
    required super.senderEmail,
    required super.receiverId,
    required super.senderId,
    required super.msg,
    required super.timestamp,
  });

  Map<String,dynamic> toMap(){
    return {
     'senderEmail': senderEmail,
     'receiverId': receiverId,
     'senderId': senderId,
     'msg': msg,
      'timestamp': timestamp,
    };
  }
}
