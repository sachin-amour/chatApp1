import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../model/chat.dart';
import '../model/messages.dart';
import '../model/userProfile.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetIt _getIt = GetIt.instance;
  late Authservice _auth;
  CollectionReference<UserProfile>? _usersCollection;
  CollectionReference<Chat>? _chatsCollection;

  FirestoreService() {
    _auth = _getIt.get<Authservice>();
    _setup();
  }

  void _setup() {
    _usersCollection = _firestore
        .collection("users")
        .withConverter<UserProfile>(
      fromFirestore: (snapshot, _) =>
          UserProfile.fromJson(snapshot.data()!),
      toFirestore: (userProfile, _) => userProfile.toJson(),
    );
    _chatsCollection = _firestore
        .collection("chats")
        .withConverter<Chat>(
      fromFirestore: (snapshot, _) => Chat.fromJson(snapshot.data()!),
      toFirestore: (chat, _) => chat.toJson(),
    );
  }

  Future<void> creatUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Stream<QuerySnapshot<UserProfile>>? getUserProfiles() {
    return _usersCollection
        ?.where("uid", isNotEqualTo: _auth.user!.uid)
        .snapshots();
  }

  // FIXED: Removed orderBy that was causing issues
  Stream<QuerySnapshot<Chat>> getUserChats(String userId) {
    print('🔍 Firestore: Fetching chats for user: $userId');

    try {
      final stream = _chatsCollection!
          .where("participants", arrayContains: userId)
          .snapshots();

      print('✅ Firestore: Stream created successfully');
      return stream;
    } catch (e) {
      print('❌ Firestore: Error creating stream: $e');
      rethrow;
    }
  }

  // Search user by email
  Future<UserProfile?> searchUserByEmail(String email) async {
    try {
      print('🔍 Searching for email: $email');
      print('🔍 Current user UID: ${_auth.user!.uid}');

      final searchEmail = email.toLowerCase().trim();

      final testQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: searchEmail)
          .limit(1)
          .get();

      print('🔍 Test query found ${testQuery.docs.length} users');

      if (testQuery.docs.isEmpty) {
        print('❌ No user found with email: $searchEmail');
        return null;
      }

      final userData = testQuery.docs.first.data();
      final foundUid = userData['uid'];

      print('✅ Found user: ${userData['name']}, UID: $foundUid');

      if (foundUid == _auth.user!.uid) {
        print('⚠️ User found but it\'s the current user, returning null');
        return null;
      }

      return UserProfile.fromJson(userData);

    } catch (e) {
      print('❌ Error searching user: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<UserProfile?> getUserProfileByUid(String uid) async {
    try {
      final doc = await _usersCollection?.doc(uid).get();
      if (doc != null && doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile by UID: $e');
      return null;
    }
  }

  Future<List<UserProfile>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection
          ?.where("uid", isNotEqualTo: _auth.user!.uid)
          .get();

      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get a single user profile with enhanced debugging
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      print('👤 Fetching profile for UID: $uid');
      final doc = await _usersCollection?.doc(uid).get();

      if (doc == null) {
        print('❌ Document is null for UID: $uid');
        return null;
      }

      if (!doc.exists) {
        print('❌ Document does not exist for UID: $uid');
        return null;
      }

      final profile = doc.data();
      if (profile != null) {
        print('✅ Profile loaded: ${profile.name}');
      } else {
        print('⚠️ Profile data is null for UID: $uid');
      }

      return profile;
    } catch (e) {
      print('❌ Error getting user profile for $uid: $e');
      return null;
    }
  }

  Future<bool> CheckChatExists(String uid1, String uid2) async {
    if (_chatsCollection == null) {
      print("Error: _chatsCollection is null, cannot check chat existence.");
      return false;
    }
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final result = await _chatsCollection!.doc(chatID).get();
    return result.exists;
  }

  Future<void> createChat(String uid1, String uid2) async {
    try {
      String chatID = generateChatId(uid1: uid1, uid2: uid2);
      print('💬 Creating chat with ID: $chatID');

      final docref = _chatsCollection!.doc(chatID);
      final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);

      await docref.set(chat);
      print('✅ Chat created successfully');
    } catch (e) {
      print('❌ Error creating chat: $e');
      rethrow;
    }
  }

  Future<void> sendChatMessage(
      String uid1,
      String uid2,
      Message message,
      ) async {
    try {
      String chatID = generateChatId(uid1: uid1, uid2: uid2);
      print('📤 Sending message to chat: $chatID');

      final docref = _chatsCollection!.doc(chatID);
      await docref.update({
        "messages": FieldValue.arrayUnion([message.toJson()]),
      });

      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(
      String uid1,
      String uid2,
      Message message,
      ) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    final docref = _chatsCollection!.doc(chatID);
    await docref.update({
      "messages": FieldValue.arrayRemove([message.toJson()]),
    });
  }

  Future<void> deleteChat(String uid1, String uid2) async {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    await _chatsCollection!.doc(chatID).delete();
  }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatId(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
    as Stream<DocumentSnapshot<Chat>>;
  }

  String generateChatId({required String uid1, required String uid2}) {
    List uids = [uid1, uid2];
    uids.sort();
    String chatId = uids.fold("", (id, uid) => "$id$uid");
    return chatId;
  }
}