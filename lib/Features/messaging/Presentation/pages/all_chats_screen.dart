import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/chat_page.dart';
// import 'package:yappsters/Features/messaging/data/repository/chat_functions.dart';

import '../../../auth/data/repository/auth_functions.dart';
import '../../data/repository/friends_service.dart';

class AllChatScreen extends StatefulWidget {
  const AllChatScreen({super.key});

  @override
  State<AllChatScreen> createState() => AllChatScreenState();
}

class AllChatScreenState extends State<AllChatScreen> with SingleTickerProviderStateMixin {
  // final ChatFunctions _chatFunctions = ChatFunctions();
  final AuthFunctions _authFunctions = AuthFunctions();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FriendsService _friends;
  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _friends = FriendsService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          centerTitle: true,
          bottom: TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ]),
        ),
        drawer: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const DrawerHeader(
                      child: Icon(
                    Icons.message,
                    size: 60,
                  )),
                  ListTile(
                    title: const Text('HOME'),
                    leading: const Icon(Icons.home),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Settings'),
                    leading: const Icon(Icons.settings),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              ListTile(
                title: const Text('Log Out'),
                leading: const Icon(Icons.logout_rounded),
                onTap: () {
                  _authFunctions.signOut();
                  Navigator.pushReplacementNamed(context, loginRoute);
                },
              )
            ],
          ),
        ),
        body: TabBarView(controller: _tabController, children: [
          // Friends list
          Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search username to add friend',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: _onSearchAndSendRequest,
                    tooltip: 'Send friend request',
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _friends.friendsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(snapshot.error.toString()));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final friends = snapshot.data!;
                    if (friends.isEmpty) {
                      return const Center(child: Text('No friends yet'));
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final userData = friends[index];
                        return ListTile(
                          title: Text(userData['username'] ?? userData['email'] ?? ''),
                          subtitle: Text(userData['email'] ?? ''),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChatPage(
                                      receiverEmail: userData['email'] ?? '',
                                      receiverId: userData['uid'],
                                    )));
                          },
                        );
                      },
                    );
                  }),
            ),
          ]),
          // Requests tab
          StreamBuilder<List<Map<String, dynamic>>>(
              stream: _friends.incomingRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final req = snapshot.data!;
                if (req.isEmpty) {
                  return const Center(child: Text('No incoming requests'));
                }
                return ListView.builder(
                  itemCount: req.length,
                  itemBuilder: (context, index) {
                    final userData = req[index];
                    return ListTile(
                      title: Text(userData['username'] ?? userData['email'] ?? ''),
                      subtitle: Text(userData['email'] ?? ''),
                      trailing: TextButton(
                        child: const Text('Accept'),
                        onPressed: () async {
                          await _friends.acceptRequest(userData['uid']);
                        },
                      ),
                    );
                  },
                );
              }),
        ]));
  }

  Future<void> _onSearchAndSendRequest() async {
    final uname = _searchController.text.trim();
    if (uname.isEmpty) return;
    try {
      final snap = await _firestore.collection('Usernames').doc(uname).get();
      if (!snap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }
      final toUid = snap.data()!['uid'] as String;
      await _friends.sendRequest(toUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
