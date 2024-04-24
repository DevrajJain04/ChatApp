import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/chat_page.dart';
// import 'package:yappsters/Features/messaging/data/repository/chat_functions.dart';

import '../../../auth/data/repository/auth_functions.dart';

class AllChatScreen extends StatefulWidget {
  const AllChatScreen({super.key});

  @override
  State<AllChatScreen> createState() => AllChatScreenState();
}

class AllChatScreenState extends State<AllChatScreen> {
  // final ChatFunctions _chatFunctions = ChatFunctions();
  final AuthFunctions _authFunctions = AuthFunctions();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Screen'),
          centerTitle: true,
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
        body: StreamBuilder(
            stream: _firestore.collection("Users").snapshots(),
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
              if (snapshot.connectionState == ConnectionState.none) {
                return const Center(
                  child: Text('connection state is none'),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> userData =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(userData['email'] ?? ''),
                    subtitle: Text(userData['uid'] ?? ''),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ChatPage(
                                receiverEmail: userData['email'],
                                receiverId: userData['uid'],
                              )));
                    },
                  );
                },
              );
            }));
  }
}
