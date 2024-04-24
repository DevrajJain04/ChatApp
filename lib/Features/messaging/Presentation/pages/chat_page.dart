import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/Features/messaging/data/repository/chat_functions.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  const ChatPage(
      {super.key, required this.receiverEmail, required this.receiverId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatFunctions _chatFunctions = ChatFunctions();

  final AuthFunctions _authFunctions = AuthFunctions();

  final TextEditingController _msgController = TextEditingController();
  // FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String senderId;
  late String senderEmail;
  @override
  void initState() {
    senderId = _authFunctions.getCurrentUser()!.uid;
    senderEmail = _authFunctions.getCurrentUser()!.email!;
    _chatFunctions.listenForNewMessages(
        senderId, widget.receiverId, showNotification, senderEmail);
    super.initState();
  }

  void showNotification() {}

  void sendMessage() async {
    if (_msgController.text.isNotEmpty) {
      await _chatFunctions.sendMessage(widget.receiverId, _msgController.text);

      _msgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: _chatFunctions.getMessages(widget.receiverId, senderId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView(
                    children: snapshot.data!.docs
                        .map((e) => _buildMessage(e))
                        .toList(),
                  );
                }),
          ),
          Row(
            children: [
              Expanded(
                  child: AuthField(
                controller: _msgController,
                hintText: 'message kar mujhe ...',
              )),
              IconButton(
                onPressed: sendMessage,
                icon: Icon(Icons.send),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessage(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser =
        data["senderId"] == _authFunctions.getCurrentUser()!.uid;

    var mq = MediaQuery.of(context).size;
    var alignment =
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    var padding = isCurrentUser
        ? EdgeInsets.fromLTRB(mq.width * 0.2, 0, 0, 0)
        : EdgeInsets.fromLTRB(0, 0, mq.width * 0.2, 0);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(9),
                color: isCurrentUser ? Colors.green : Colors.grey[100]),
            child: Text(
              data["msg"],
              style: TextStyle(color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }
}
