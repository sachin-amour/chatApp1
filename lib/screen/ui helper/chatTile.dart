import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/messages.dart';
import '../../model/userProfile.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Message? lastMessage;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.userProfile,
    required this.lastMessage,
    required this.onTap,
  });

  String _getMessagePreview() {
    if (lastMessage == null) {
      return 'No messages yet';
    }

    switch (lastMessage!.messageType) {
      case MessageType.Image:
        return '📷 Photo';
      case MessageType.Video:
        return '🎥 Video';
      case MessageType.Text:
      default:
        return lastMessage!.content ?? 'No messages yet';
    }
  }

  String _getTimeAgo() {
    if (lastMessage?.sentAt == null) {
      return '';
    }

    final DateTime messageTime = lastMessage!.sentAt!.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(messageTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagePreview = _getMessagePreview();
    final timeAgo = _getTimeAgo();

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile Picture with Hero Animation
              Hero(
                tag: 'profile_${userProfile.uid}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: userProfile.pfpURL != null
                      ? NetworkImage(userProfile.pfpURL!)
                      : null,
                  backgroundColor: Colors.teal.shade100,
                  child: userProfile.pfpURL == null
                      ? Icon(Icons.person, color: Colors.teal.shade700)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User Name
                        Expanded(
                          child: Text(
                            userProfile.name ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Time
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Last Message Preview
                    Text(
                      messagePreview,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}