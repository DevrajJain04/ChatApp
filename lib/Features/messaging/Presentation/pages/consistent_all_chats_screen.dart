import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/consistent_chat_page.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/Features/messaging/data/repository/friends_service.dart';

class ConsistentAllChatsScreen extends StatefulWidget {
  const ConsistentAllChatsScreen({super.key});

  @override
  State<ConsistentAllChatsScreen> createState() =>
      _ConsistentAllChatsScreenState();
}

class _ConsistentAllChatsScreenState extends State<ConsistentAllChatsScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.backgroundColor,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: AppPallete.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppPallete.whiteColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPallete.gradient1,
          labelColor: AppPallete.gradient1,
          unselectedLabelColor: AppPallete.greyColor,
          tabs: const [
            Tab(
              text: 'Friends',
              icon: Icon(Icons.people),
            ),
            Tab(
              text: 'Requests',
              icon: Icon(Icons.person_add),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppPallete.backgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppPallete.gradient1, AppPallete.gradient2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppPallete.whiteColor,
                ),
                SizedBox(height: 8),
                Text(
                  'Yappsters',
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              isLogout: true,
              onTap: () {
                _authFunctions.signOut();
                Navigator.pushReplacementNamed(context, loginRoute);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isLogout
            ? AppPallete.errorColor.withOpacity(0.1)
            : AppPallete.transparentColor,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? AppPallete.errorColor : AppPallete.whiteColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? AppPallete.errorColor : AppPallete.whiteColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // Search section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppPallete.borderColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppPallete.whiteColor),
                  decoration: const InputDecoration(
                    hintText: 'Search username to add friend...',
                    hintStyle: TextStyle(color: AppPallete.greyColor),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppPallete.greyColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPallete.gradient1, AppPallete.gradient2],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add_alt_1,
                      color: AppPallete.whiteColor),
                  onPressed: _onSearchAndSendRequest,
                  tooltip: 'Send friend request',
                ),
              ),
            ],
          ),
        ),

        // Friends list
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friends.friendsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return _buildLoadingState();
              }

              final friends = snapshot.data!;
              if (friends.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'No friends yet',
                  subtitle: 'Search for usernames above to add friends',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final userData = friends[index];
                  return _buildFriendCard(userData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friends.incomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_outlined,
            title: 'No incoming requests',
            subtitle: 'Friend requests will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final userData = requests[index];
            return _buildRequestCard(userData);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> userData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.borderColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppPallete.gradient1,
          child: Text(
            (userData['username'] ?? userData['email'] ?? '')
                .substring(0, 1)
                .toUpperCase(),
            style: const TextStyle(
              color: AppPallete.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          userData['username'] ?? userData['email'] ?? '',
          style: const TextStyle(
            color: AppPallete.whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          userData['email'] ?? '',
          style: const TextStyle(color: AppPallete.greyColor),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: AppPallete.whiteColor,
            size: 20,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConsistentChatPage(
                receiverEmail: userData['email'] ?? '',
                receiverId: userData['uid'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> userData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.borderColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppPallete.gradient2,
          child: Text(
            (userData['username'] ?? userData['email'] ?? '')
                .substring(0, 1)
                .toUpperCase(),
            style: const TextStyle(
              color: AppPallete.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          userData['username'] ?? userData['email'] ?? '',
          style: const TextStyle(
            color: AppPallete.whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          userData['email'] ?? '',
          style: const TextStyle(color: AppPallete.greyColor),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: () async {
              await _friends.acceptRequest(userData['uid']);
            },
            child: const Text(
              'Accept',
              style: TextStyle(
                  color: AppPallete.whiteColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppPallete.gradient1),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(color: AppPallete.greyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Error: $error',
            style: const TextStyle(color: AppPallete.errorColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppPallete.greyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppPallete.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppPallete.greyColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchAndSendRequest() async {
    final uname = _searchController.text.trim();
    if (uname.isEmpty) return;

    try {
      final snap = await _firestore.collection('Usernames').doc(uname).get();
      if (!snap.exists) {
        if (!mounted) return;
        _showSnackBar('User not found', isError: true);
        return;
      }

      final toUid = snap.data()!['uid'] as String;
      await _friends.sendRequest(toUid);

      if (!mounted) return;
      _showSnackBar('Friend request sent!');
      _searchController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppPallete.errorColor : AppPallete.gradient1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
