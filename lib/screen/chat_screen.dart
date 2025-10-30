import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart' hide VideoPlayer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:video_player/video_player.dart';

import '../model/chat.dart';
import '../model/messages.dart';
import '../model/userProfile.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../services/media_service.dart';

class chatScreen extends StatefulWidget {
  final UserProfile userProfile;
  const chatScreen({super.key, required this.userProfile});

  @override
  State<chatScreen> createState() => _chatScreenState();
}

class _chatScreenState extends State<chatScreen> {
  final GetIt _getIt = GetIt.instance;
  late Authservice _authservice;
  late FirestoreService _firestore;
  late CloudinaryStorageService _cloudinary;
  late MediaService _mediaService;
  ChatUser? currentUser, otherUser;
  bool _showEmojiPicker = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _firestore = _getIt.get<FirestoreService>();
    _mediaService = _getIt.get<MediaService>();
    _cloudinary = _getIt.get<CloudinaryStorageService>();
    currentUser = ChatUser(
      id: _authservice.user!.uid,
      firstName: _authservice.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.userProfile.uid!,
      firstName: widget.userProfile.name,
      profileImage: widget.userProfile.pfpURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Hero(
              tag: 'profile_${widget.userProfile.uid}',
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.userProfile.pfpURL!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.userProfile.name!,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'delete_chat') {
                _showDeleteChatDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _build(),
    );
  }

  Widget _build() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _firestore.getChatData(currentUser!.id, otherUser!.id),
            builder: (context, snapshot) {
              Chat? chat = snapshot.data?.data();
              List<ChatMessage> messages = [];
              if (chat != null && chat.messages != null) {
                messages = _generateChatMessagesList(chat.messages!);
              }
              return DashChat(
                messageOptions: MessageOptions(
                  showOtherUsersAvatar: true,
                  showTime: true,
                  onLongPressMessage: (message) {
                    _showMessageOptions(message, chat);
                  },
                  onTapMedia: (media) {
                    _showMediaPopup(media);
                  },
                  messagePadding: const EdgeInsets.all(8),
                  messageDecorationBuilder: (message, previousMessage, nextMessage) {
                    return BoxDecoration(
                      color: message.user.id == currentUser!.id
                          ? Colors.teal.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    );
                  },
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    return Text(
                      message.text,
                      style: TextStyle(
                        color: message.user.id == currentUser!.id
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  },
                ),
                inputOptions: InputOptions(
                  alwaysShowSend: true,
                  textController: _textController,
                  trailing: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          // Toggle emoji picker visibility and manage keyboard focus
                          if (_showEmojiPicker) {
                            FocusScope.of(context).unfocus(); // If open, keep keyboard dismissed
                          } else {
                            FocusScope.of(context).unfocus(); // Hide keyboard before showing emoji picker
                          }
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    _mediaAttachmentButton(),
                  ],
                ),
                currentUser: currentUser!,
                onSend: _sendMessage,
                messages: messages,
              );
            },
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child:EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _textController.text += emoji.emoji;
              },
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  backgroundColor: const Color(0xFFF2F2F2),
                  buttonMode: ButtonMode.MATERIAL,
                  recentsLimit: 28,
                  noRecents: const Text(
                    'No Recents',
                    style: TextStyle(fontSize: 20, color: Colors.black26),
                    textAlign: TextAlign.center,
                  ),
                ),
                categoryViewConfig: const CategoryViewConfig(
                  initCategory: Category.RECENT,
                  indicatorColor: Colors.teal,
                  iconColor: Colors.grey,
                  iconColorSelected: Colors.teal,
                  backspaceColor: Colors.teal,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                  categoryIcons: CategoryIcons(),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                ),
                skinToneConfig: const SkinToneConfig(
                  enabled: true,
                  dialogBackgroundColor: Colors.white,
                  indicatorColor: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Media attachment button with popup menu
  Widget _mediaAttachmentButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.attach_file, color: Colors.teal.shade700),
      onSelected: (value) async {
        if (value == 'image_gallery') {
          _pickImageFromGallery();
        } else if (value == 'video_gallery') {
          _pickVideoFromGallery();
        } else if (value == 'image_camera') {
          _pickImageFromCamera();
        } else if (value == 'video_camera') {
          _pickVideoFromCamera();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'image_gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue),
              SizedBox(width: 12),
              Text('Image from Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'video_gallery',
          child: Row(
            children: [
              Icon(Icons.video_library, color: Colors.purple),
              SizedBox(width: 12),
              Text('Video from Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'image_camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green),
              SizedBox(width: 12),
              Text('Take Photo'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'video_camera',
          child: Row(
            children: [
              Icon(Icons.videocam, color: Colors.red),
              SizedBox(width: 12),
              Text('Record Video'),
            ],
          ),
        ),
      ],
    );
  }

  // Show media in popup when tapped
  void _showMediaPopup(ChatMedia media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Media content
            Center(
              child: media.type == MediaType.image
                  ? InteractiveViewer(
                child: Image.network(
                  media.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
                  : _VideoPlayerWidget(videoUrl: media.url),
            ),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),

            // Action buttons
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: Icons.download,
                    label: 'Download',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    File? file = await _mediaService.getImageFormGallery();
    if (file != null) {
      await _uploadAndSendMedia(file, MediaType.image);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    File? file = await _mediaService.getVideoFromGallery();
    if (file != null) {
      await _checkAndUploadVideo(file);
    }
  }

  Future<void> _pickImageFromCamera() async {
    File? file = await _mediaService.getImageFromCamera();
    if (file != null) {
      await _uploadAndSendMedia(file, MediaType.image);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    File? file = await _mediaService.getVideoFromCamera();
    if (file != null) {
      await _checkAndUploadVideo(file);
    }
  }

  // UPDATED: Added explicit check for controller initialization success
  Future<void> _checkAndUploadVideo(File file) async {
    VideoPlayerController controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();

      if (!controller.value.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not initialize video player for duration check.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        controller.dispose();
        return;
      }

      Duration duration = controller.value.duration;
      controller.dispose();

      if (duration.inSeconds > 60) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video must be 60 seconds or less'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _uploadAndSendMedia(file, MediaType.video);
    } catch (e) {
      controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking video duration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSendMedia(File file, MediaType type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    String chatID = _firestore.generateChatId(
      uid1: currentUser!.id,
      uid2: otherUser!.id,
    );

    String? downloadURL;
    if (type == MediaType.image) {
      downloadURL = await _cloudinary.uploadImageToChat(
        file: file,
        chatId: chatID,
      );
    } else {
      downloadURL = await _cloudinary.uploadVideo(
        file: file,
        folder: 'chats/$chatID',
      );
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
    }

    if (downloadURL != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser!,
        text: '',
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: downloadURL,
            fileName: type == MediaType.image ? "image.jpg" : "video.mp4",
            type: type,
          ),
        ],
      );
      _sendMessage(chatMessage);
    }
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      _showEmojiPicker = false;
    });

    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        Message message = Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _firestore.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      } else if (chatMessage.medias!.first.type == MediaType.video) {
        Message message = Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Video,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _firestore.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      Message message = Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );
      await _firestore.sendChatMessage(currentUser!.id, otherUser!.id, message);
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(url: m.content!, fileName: "", type: MediaType.image),
          ],
        );
      } else if (m.messageType == MessageType.Video) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(url: m.content!, fileName: "", type: MediaType.video),
          ],
        );
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();
    chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chatMessages;
  }

  void _showMessageOptions(ChatMessage message, Chat? chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied')),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardDialog(message);
                },
              ),
              if (message.user.id == currentUser!.id)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, chat);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteMessage(ChatMessage message, Chat? chat) async {
    if (chat == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Find the original Message object from the chat's messages list
              final messageToDelete = chat.messages?.firstWhere(
                    (m) => m.content == message.text || (message.medias != null && message.medias!.isNotEmpty && m.content == message.medias!.first.url),
                orElse: () => Message(senderID: '', content: '', messageType: MessageType.Text, sentAt: null), // Fallback if not found
              );

              // Only proceed if a valid message was found
              if (messageToDelete != null && messageToDelete.senderID!.isNotEmpty) {
                await _firestore.deleteMessage(
                  currentUser!.id,
                  otherUser!.id,
                  messageToDelete,
                );
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Message'),
        content: StreamBuilder<QuerySnapshot<UserProfile>>(
          stream: _firestore.getUserProfiles(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs.map((doc) => doc.data()).toList();
            // Filter out the current user and the person you are chatting with
            final forwardableUsers = users.where(
                    (user) => user.uid != currentUser!.id && user.uid != otherUser!.id
            ).toList();

            if (forwardableUsers.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text('No other users to forward to.'),
                ),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: forwardableUsers.length,
                itemBuilder: (context, index) {
                  final user = forwardableUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.pfpURL!),
                    ),
                    title: Text(user.name!),
                    onTap: () async {
                      Navigator.pop(context);

                      // Check/Create chat is a good idea but might be heavy. For simplicity, we just send.
                      // The sendChatMessage logic should handle creating the chat if it doesn't exist
                      // on the first message, if your FirestoreService is configured that way.

                      String? content;
                      MessageType messageType;

                      if (message.text.isNotEmpty) {
                        content = message.text;
                        messageType = MessageType.Text;
                      } else if (message.medias?.isNotEmpty ?? false) {
                        content = message.medias!.first.url;
                        messageType = message.medias!.first.type == MediaType.image
                            ? MessageType.Image
                            : MessageType.Video;
                      } else {
                        return; // Cannot forward an empty message
                      }

                      Message forwardedMessage = Message(
                        senderID: currentUser!.id,
                        content: content,
                        messageType: messageType,
                        sentAt: Timestamp.now(),
                      );

                      await _firestore.sendChatMessage(
                        currentUser!.id,
                        user.uid!,
                        forwardedMessage,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Forwarded to ${user.name}')),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(ChatMessage message) {
    final reactions = ['❤️', '😂', '😮', '😢', '😡', '👍', '👎'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('React to message'),
        content: Wrap(
          spacing: 10,
          children: reactions.map((reaction) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                // In a real app, you would send this reaction to Firestore
                // and update the corresponding message document.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reacted with $reaction (Feature to be implemented)')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 30)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this entire chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.deleteChat(currentUser!.id, otherUser!.id);
              if (mounted) {
                // Pop the chat screen after successful deletion
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// Video Player Widget for popup
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true); // Loops the video
          _controller.play();
        }
      }).catchError((error) {
        print('Error initializing video: $error');
        if(mounted) {
          setState(() {
            // Set to true so the error UI is displayed instead of endless loading
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_controller.value.hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Error loading video. The URL might be invalid or the video format unsupported.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          // Play/Pause button
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
          // Video progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.teal.shade700,
                bufferedColor: Colors.white70,
                backgroundColor: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}