import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/Features/messaging/data/repository/chat_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';

class ConsistentChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;

  const ConsistentChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
  });

  @override
  State<ConsistentChatPage> createState() => _ConsistentChatPageState();
}

class _ConsistentChatPageState extends State<ConsistentChatPage> {
  final ChatFunctions _chatFunctions = ChatFunctions();
  final AuthFunctions _authFunctions = AuthFunctions();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String senderId;
  late String senderEmail;
  String? receiverUsername;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    senderId = _authFunctions.getCurrentUser()!.uid;
    senderEmail = _authFunctions.getCurrentUser()!.email!;
    _chatFunctions.listenForNewMessages(
      senderId,
      widget.receiverId,
      showNotification,
      senderEmail,
    );
    _loadReceiver();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReceiver() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.receiverId)
          .get();
      if (doc.exists) {
        setState(() {
          receiverUsername = doc.data()?["username"] as String?;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void showNotification() {
    // Scroll to bottom when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final messageText = _msgController.text.trim();
    if (messageText.isEmpty) return;

    // Clear the input immediately for better UX
    _msgController.clear();
    setState(() => isTyping = false);

    try {
      await _chatFunctions.sendMessage(widget.receiverId, messageText);

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // Show error and restore message
      _msgController.text = messageText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppPallete.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPallete.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppPallete.gradient1,
            radius: 20,
            child: Text(
              (receiverUsername ?? widget.receiverEmail)
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverUsername ?? widget.receiverEmail,
                  style: const TextStyle(
                    color: AppPallete.whiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: AppPallete.gradient1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppPallete.whiteColor),
          onPressed: () {
            // Add chat options menu
            _showChatOptions();
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder(
      stream: _chatFunctions.getMessages(widget.receiverId, senderId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppPallete.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: const TextStyle(color: AppPallete.errorColor),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppPallete.gradient1),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppPallete.gradient1),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppPallete.greyColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: const TextStyle(
                    color: AppPallete.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: const TextStyle(color: AppPallete.greyColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs.reversed.toList()[index];
            return _buildMessage(doc);
          },
        );
      },
    );
  }

  Widget _buildMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isCurrentUser = data["senderId"] == senderId;
    final messageText = data["msg"] ?? '';
    final timestamp = data["timestamp"] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPallete.gradient2,
              child: Text(
                (receiverUsername ?? widget.receiverEmail)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [AppPallete.gradient1, AppPallete.gradient2],
                      )
                    : null,
                color: isCurrentUser
                    ? null
                    : AppPallete.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                ),
                border: isCurrentUser
                    ? null
                    : Border.all(color: AppPallete.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messageText,
                    style: const TextStyle(
                      color: AppPallete.whiteColor,
                      fontSize: 16,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: isCurrentUser
                            ? AppPallete.whiteColor.withOpacity(0.7)
                            : AppPallete.greyColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPallete.gradient1,
              child: Text(
                _authFunctions
                    .getCurrentUser()!
                    .email!
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: AppPallete.borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppPallete.borderColor),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: AppPallete.whiteColor),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppPallete.greyColor),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    isTyping = value.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) => sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: isTyping
                  ? const LinearGradient(
                      colors: [AppPallete.gradient1, AppPallete.gradient2],
                    )
                  : null,
              color: isTyping ? null : AppPallete.greyColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppPallete.whiteColor),
              onPressed: isTyping ? sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPallete.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.greyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: AppPallete.whiteColor),
                title: const Text('View Profile',
                    style: TextStyle(color: AppPallete.whiteColor)),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to user profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: AppPallete.errorColor),
                title: const Text('Block User',
                    style: TextStyle(color: AppPallete.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  // Block user functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
