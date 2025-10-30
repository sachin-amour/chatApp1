import 'package:feelings/screen/search_screen.dart';
import 'package:feelings/screen/ui%20helper/chatTile.dart';
import 'package:feelings/screen/ui%20helper/slider_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/navigation_service.dart';
import 'chat_screen.dart';

class homeScreen extends StatefulWidget {
  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen>
    with SingleTickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late Authservice _authservice;
  late FirestoreService _firestoreService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _firestoreService = _getIt.get<FirestoreService>();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ADD THE DRAWER HERE
      drawer: slidler(),

      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        // The leading will automatically show the hamburger menu icon
        // when a drawer is present
        title: const Text(
          "Textra",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Makes hamburger icon white
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(_createRoute(const SearchScreen()));
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          // REMOVED THE MENU BUTTON - drawer handle will show automatically
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(opacity: _fadeAnimation, child: _build()),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(_createRoute(const SearchScreen()));
          },
          backgroundColor: Colors.teal.shade700,
          child: const Icon(Icons.person_search, color: Colors.white),
        ),
      ),
    );
  }

  Widget _build() {
    return SafeArea(child: _chatList());
  }

  Widget _chatList() {
    print('🏠 Building chat list for user: ${_authservice.user!.uid}');

    return StreamBuilder(
      stream: _firestoreService.getUserChats(_authservice.user!.uid),
      builder: (context, snapshot) {
        print('📊 Stream state: ${snapshot.connectionState}');
        print('📊 Has data: ${snapshot.hasData}');
        print('📊 Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          print('❌❌❌ CRITICAL ERROR in stream: ${snapshot.error}');
          print('❌ Error type: ${snapshot.error.runtimeType}');
          print('❌ Stack trace: ${snapshot.stackTrace}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  "Unable to load chats",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "${snapshot.error}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for chat data...');
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('⚠️ No data received from stream');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the search button to find users',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;
        print('✅ Received ${chats.length} chat documents');

        if (chats.isEmpty) {
          print('📭 Chat list is empty');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start chatting by searching for users',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Filter and validate chats
        List<dynamic> validChats = [];
        for (var i = 0; i < chats.length; i++) {
          try {
            final chat = chats[i].data();
            print(
              '📝 Chat $i: ID=${chat.id}, Participants=${chat.participants}, Messages=${chat.messages?.length ?? 0}',
            );

            if (chat.messages != null && chat.messages!.isNotEmpty) {
              validChats.add(chats[i]);
              print('  ✓ Chat $i is valid and has messages');
            } else {
              print('  ⊘ Chat $i has no messages, skipping');
            }
          } catch (e) {
            print('  ❌ Error processing chat $i: $e');
          }
        }

        print('✅ Valid chats with messages: ${validChats.length}');

        if (validChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by searching for users',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: validChats.length,
          itemBuilder: (context, index) {
            try {
              final chatDoc = validChats[index];
              final chat = chatDoc.data();

              print('🔨 Building tile for chat $index');

              if (chat.participants == null || chat.participants!.length < 2) {
                print('  ❌ Invalid participants for chat ${chat.id}');
                return const SizedBox.shrink();
              }

              final otherUserId = chat.participants!.firstWhere(
                    (id) => id != _authservice.user!.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                print('  ❌ Could not find other user in chat ${chat.id}');
                return const SizedBox.shrink();
              }

              print('  👤 Other user ID: $otherUserId');

              return FutureBuilder(
                key: ValueKey('${chat.id}_$index'),
                future: _firestoreService.getUserProfile(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    print(
                      '  ❌ Error loading profile for $otherUserId: ${userSnapshot.error}',
                    );
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                          title: Text('Error loading user'),
                          subtitle: Text('User ID: $otherUserId'),
                        ),
                      ),
                    );
                  }

                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 16,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 14,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    print('  ⚠️ No profile data for $otherUserId');
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.person_off, color: Colors.orange),
                          ),
                          title: Text('User not found'),
                          subtitle: Text('ID: $otherUserId'),
                        ),
                      ),
                    );
                  }

                  final userProfile = userSnapshot.data!;
                  final lastMessage = chat.messages!.last;

                  print('  ✅ Successfully loaded profile: ${userProfile.name}');

                  return ChatTile(
                    key: ValueKey(chat.id),
                    userProfile: userProfile,
                    lastMessage: lastMessage,
                    onTap: () {
                      print('  🔄 Navigating to chat with ${userProfile.name}');
                      Navigator.of(context).push(
                        _createRoute(chatScreen(userProfile: userProfile)),
                      );
                    },
                  );
                },
              );
            } catch (e, stackTrace) {
              print('❌ Exception building chat tile $index: $e');
              print('Stack: $stackTrace');
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: Icon(Icons.error, color: Colors.red),
                    title: Text('Error loading chat'),
                    subtitle: Text('$e'),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}