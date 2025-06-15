import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final bool isVoice;
  final String time;
  final bool isSending;

  ChatMessage({
    this.text = '',
    required this.isMe,
    this.isVoice = false,
    required this.time,
    this.isSending = false,
  });
}

class Chat {
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final int unreadCount;
  final IconData icon;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isOnline = false,
    this.unreadCount = 0,
    this.icon = Icons.local_hospital,
  });
}

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isRecording = false;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello, I'm interested in donating blood. What are the requirements?",
      isMe: true,
      time: "10:30 AM",
    ),
    ChatMessage(
      text: "Hi! Thank you for your interest in donating blood.",
      isMe: false,
      time: "10:31 AM",
    ),
    ChatMessage(
      isMe: false,
      isVoice: true,
      time: "10:32 AM",
      text: "1:30", // Duration of voice message
    ),
    ChatMessage(
      text: "I understand. When can I visit the center?",
      isMe: true,
      time: "10:33 AM",
    ),
    ChatMessage(
      text: "You can visit us anytime between 9 AM to 5 PM, Monday to Saturday.",
      isMe: false,
      time: "10:34 AM",
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildMessage(ChatMessage message) {
    final bodySize = ResponsiveUtils.getBodySize(context);
    final smallTextSize = ResponsiveUtils.getSmallTextSize(context);

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isMe ? 50 : 10,
          right: message.isMe ? 10 : 50,
          top: 5,
          bottom: 5,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isMe
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isVoice)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: message.isMe ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 100,
                    height: 2,
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    message.text, // Duration
                    style: TextStyle(
                      color: message.isMe ? AppTheme.primaryColor : Colors.grey[600],
                      fontSize: smallTextSize,
                    ),
                  ),
                ],
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: message.isMe ? AppTheme.primaryColor : Colors.black87,
                  fontSize: bodySize,
                ),
              ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                if (message.isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic_none,
                color: _isRecording ? Colors.red : Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  setState(() {
                    _messages.add(
                      ChatMessage(
                        text: _messageController.text,
                        isMe: true,
                        time: "${DateTime.now().hour}:${DateTime.now().minute}",
                        isSending: true,
                      ),
                    );
                  });
                  _messageController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                widget.chat.icon,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: ResponsiveUtils.getBodySize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.chat.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: widget.chat.isOnline ? Colors.green : Colors.grey,
                    fontSize: ResponsiveUtils.getSmallTextSize(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: _messages.length,
              reverse: false,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Chat> _chats = [
    Chat(
      name: 'Medicare Center',
      lastMessage: 'You can visit us anytime between 9 AM to 5 PM',
      time: '10:34 AM',
      isOnline: true,
      unreadCount: 2,
    ),
    Chat(
      name: 'City Hospital',
      lastMessage: 'Thank you for your donation',
      time: 'Yesterday',
      isOnline: false,
    ),
    Chat(
      name: 'Blood Bank',
      lastMessage: 'Your blood type is required urgently',
      time: '2 days ago',
      isOnline: true,
      unreadCount: 1,
    ),
  ];

  Widget _buildChatCard(Chat chat) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.lightDividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: chat),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    radius: 24,
                    child: Icon(
                      chat.icon,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  if (chat.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getBodySize(context),
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          chat.time,
                          style: TextStyle(
                            color: chat.unreadCount > 0
                                ? AppTheme.primaryColor
                                : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: TextStyle(
                              color: chat.unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontSize: ResponsiveUtils.getSmallTextSize(context),
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          return _buildChatCard(_chats[index]);
        },
      ),
    );
  }
}
