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

  late String senderId;
  late String senderEmail;
  String? receiverUsername;
  @override
  void initState() {
    senderId = _authFunctions.getCurrentUser()!.uid;
    senderEmail = _authFunctions.getCurrentUser()!.email!;
    _chatFunctions.listenForNewMessages(
        senderId, widget.receiverId, showNotification, senderEmail);
    _loadReceiver();
    super.initState();
  }

  Future<void> _loadReceiver() async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.receiverId)
        .get();
    if (doc.exists) {
      setState(() {
        receiverUsername = doc.data()?["username"] as String?;
      });
    }
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
  title: Text(receiverUsername ?? widget.receiverEmail),
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
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView(
                    reverse: true,
                    children: snapshot.data!.docs.reversed
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
                icon: const Icon(Icons.send),
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
              style: const TextStyle(color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }
}
