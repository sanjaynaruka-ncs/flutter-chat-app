import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../models/message_status.dart';
import '../chat/chat_conversation_manager.dart';
import 'chat_search_controller.dart';

class ChatScreenUi extends StatefulWidget {
  final String title;
  final Stream<QuerySnapshot> messagesStream;
  final bool isBlocked;
  final bool forceEmpty;

  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onClearChat;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;
  final VoidCallback? onNewGroup;
  final VoidCallback? onDocumentTap;
  final VoidCallback? onContactTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onGalleryTap;

  /// 💬 TEXT
  final void Function(String) onSend;

  /// 📎 MEDIA
  final VoidCallback onCameraTap;
  final VoidCallback onVideoTap;
  final ValueChanged<String> onAudioSend;

  const ChatScreenUi({
    super.key,
    required this.title,
    required this.messagesStream,
    required this.isBlocked,
    this.forceEmpty = false,
    required this.onBack,
    required this.onSearch,
    required this.onClearChat,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
    required this.onSend,
    required this.onCameraTap,
    required this.onVideoTap,
    required this.onAudioSend,
    this.onContactTap,
    this.onNewGroup,
    this.onDocumentTap,
    this.onLocationTap,
    this.onGalleryTap,
  });

  @override
  State<ChatScreenUi> createState() => ChatScreenUiState();
}

class ChatScreenUiState extends State<ChatScreenUi> {
  final ChatSearchController _searchCtrl = ChatSearchController();

  bool _selectionMode = false;
  final Set<int> _selectedIndexes = {};

  bool _isReplying = false;
  int? _replyMessageIndex;
  String? _replyMessageText;

  final Set<int> _deletedIndexes = {};

  final List<ChatMessageUi> _optimistic = [];

  /// ✅ ADDED: holds latest rendered messages for reply attachment
  List<ChatMessageUi> _lastRenderedMessages = const [];

  StreamSubscription? _firestoreSub;

  @override
  void initState() {
    super.initState();

    _firestoreSub = widget.messagesStream.listen((snapshot) {
      if (_optimistic.isEmpty) return;

      ChatConversationManager.reconcileOptimisticMessages(
        optimistic: _optimistic,
        firestoreDocs: snapshot.docs,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }

  void _handleSend(String text) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final ChatMessageUi? replyTarget =
        (_isReplying && _replyMessageIndex != null &&
                _replyMessageIndex! < _lastRenderedMessages.length)
            ? _lastRenderedMessages[_replyMessageIndex!]
            : null;

    setState(() {
      _optimistic.add(
        ChatBubbleUi(
          text: text,
          isMe: true,
          time: '',
          status: MessageStatus.sent,
          replyTo: replyTarget,
        ),
      );

      _isReplying = false;
      _replyMessageIndex = null;
      _replyMessageText = null;
    });

    widget.onSend(text);
  }

  void _onMessageLongPress(int index) {
    setState(() {
      _selectionMode = true;
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
        if (_selectedIndexes.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  void _triggerReply(List<ChatMessageUi> messages) {
    if (_selectedIndexes.length != 1) return;

    final index = _selectedIndexes.first;
    final msg = messages[index];

    setState(() {
      _isReplying = true;
      _replyMessageIndex = index;
      if (msg is ChatBubbleUi) {
        _replyMessageText = msg.text;
      } else {
        _replyMessageText = '';
      }
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyMessageIndex = null;
      _replyMessageText = null;
    });
  }

  void _deleteSelected() {
    if (_selectedIndexes.isEmpty) return;

    setState(() {
      _deletedIndexes.addAll(_selectedIndexes);
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  void _forwardSelected() {
    if (_selectedIndexes.isEmpty) return;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    List<ChatMessageUi> currentMessages = const [];

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIndexes.length}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () => _triggerReply(currentMessages),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star_border),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelected,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward),
                  onPressed: _forwardSelected,
                ),
                const SizedBox(width: 12),
              ],
            )
          : _searchCtrl.isSearchMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _searchCtrl.exit();
                      });
                    },
                  ),
                  title: TextField(
                    controller: _searchCtrl.controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search…',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                )
              : ChatAppBar(
                  title: widget.title,
                  onBack: widget.onBack,
                  onSearch: () {
                    setState(() {
                      _searchCtrl.enter();
                    });
                  },
                  onClearChat: widget.onClearChat,
                  onBlock: widget.isBlocked ? null : widget.onBlock,
                  onUnblock: widget.isBlocked ? widget.onUnblock : null,
                  onReport: widget.onReport,
                  onNewGroup: widget.onNewGroup,
                  isBlocked: widget.isBlocked,
                ),
      body: Column(
        children: [
          Expanded(
            child: widget.forceEmpty
                ? ChatMessageList(
                    messages: const [],
                    selectedIndexes: _selectedIndexes,
                    onMessageLongPress: _onMessageLongPress,
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: widget.messagesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final List<ChatMessageUi> firestoreMessages = [];

                      for (final doc in docs) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final text = data['text'] ?? '';

                        if (!_searchCtrl.matchesQuery(text)) continue;

                        final type = data['type'];
                        final isMe =
                            data['senderId'] == myUid;

                        final rawStatus =
                            data['status'] ?? 'sent';

                        final MessageStatus messageStatus =
                            switch (rawStatus) {
                          'delivered' =>
                              MessageStatus.delivered,
                          'read' => MessageStatus.read,
                          _ => MessageStatus.sent,
                        };

                        if (type == 'location') {
                          final mapUrl = data['mapImageUrl'];
                          if (mapUrl is String &&
                              mapUrl.isNotEmpty) {
                            firestoreMessages.add(
                              ChatLocationUi(
                                isMe: isMe,
                                mapImageUrl: mapUrl,
                                status: messageStatus,
                              ),
                            );
                          }
                          continue;
                        }

                        if (type == 'image') {
                          firestoreMessages.add(
                            ChatImageUi(
                              imagePath: data['path'],
                              isMe: isMe,
                              status: messageStatus,
                            ),
                          );
                          continue;
                        }

                        if (type == 'video') {
                          firestoreMessages.add(
                            ChatVideoUi(
                              videoPath: data['path'],
                              isMe: isMe,
                              status: messageStatus,
                              clientId: data['clientId'],
                            ),
                          );
                          continue;
                        }

                        if (type == 'audio') {
                          firestoreMessages.add(
                            ChatAudioUi(
                              isMe: isMe,
                              status: messageStatus,
                              audioPath: data['path'],
                              durationMs:
                                  (data['durationMs'] ?? 0)
                                      as int,
                              clientId: data['clientId'],
                            ),
                          );
                          continue;
                        }

                        if (type == 'contact') {
                          firestoreMessages.add(
                            ChatContactUi(
                              isMe: isMe,
                              status: messageStatus,
                              name: data['name'] ?? '',
                              phone: data['phone'] ?? '',
                            ),
                          );
                          continue;
                        }

                        if (type == 'document') {
                          firestoreMessages.add(
                            ChatDocumentUi(
                              isMe: isMe,
                              status: messageStatus,
                              documentUrl: data['path'],
                              fileName:
                                  data['fileName'] ??
                                      'Document',
                              fileSizeBytes:
                                  data['fileSize'] ?? 0,
                            ),
                          );
                          continue;
                        }

                        firestoreMessages.add(
                          ChatBubbleUi(
                            text: data['text'] ?? '',
                            isMe: isMe,
                            time: '',
                            status: messageStatus,
                          ),
                        );
                      }

                      final combined = [
                        ...firestoreMessages,
                        ..._optimistic,
                      ];

                      currentMessages = [
                        for (int i = 0; i < combined.length; i++)
                          if (!_deletedIndexes.contains(i))
                            combined[i],
                      ];

                      _lastRenderedMessages = currentMessages;

                      return ChatMessageList(
                        messages: currentMessages,
                        selectedIndexes: _selectedIndexes,
                        onMessageLongPress: _onMessageLongPress,
                      );
                    },
                  ),
          ),
          if (_isReplying && _replyMessageText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _replyMessageText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          if (widget.isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.grey.shade200,
              child: GestureDetector(
                onTap: widget.onUnblock,
                child: Text(
                  'You blocked this user. Tap to unblock.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (!widget.isBlocked && !_searchCtrl.isSearchMode)
            ChatInputBar(
              onSend: _handleSend,
              onCameraTap: widget.onCameraTap,
              onVideoTap: widget.onVideoTap,
              onAudioSend: widget.onAudioSend,
              onDocumentTap: widget.onDocumentTap,
              onContactTap: widget.onContactTap,
              onLocationTap: widget.onLocationTap,
              onGalleryTap: widget.onGalleryTap,
            ),
        ],
      ),
    );
  }
}
