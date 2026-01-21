import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../helpers/chat_selection_controller.dart';
import '../helpers/contact_resolver.dart';
import '../helpers/chat_stream_provider.dart';

import '../screens/chat_screen.dart';
import '../screens/users_screen.dart';

import '../widgets/chat_list_view.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_fab.dart';
import '../widgets/home_filter_tabs.dart';
import '../widgets/home_search_bar.dart';

import '../chat/chat_delete_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeFilter _selectedFilter = HomeFilter.all;

  final ChatSelectionController _selection =
      ChatSelectionController();

  bool _isSelectedChatStarred = false;

  @override
  void initState() {
    super.initState();
    ContactResolver.loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllTab =
        _selectedFilter == HomeFilter.all;

    return Scaffold(
      appBar: HomeAppBar(
        hasSelection: _selection.hasSelection,
        selectedCount: _selection.hasSelection ? 1 : 0,
        isStarredSelected: _isSelectedChatStarred,
        showDelete: isAllTab,
        onDeletePressed:
            isAllTab ? _onDeleteSelectedChat : null,
        onStarToggle:
            _selection.hasSelection ? _onToggleStarSelectedChat : null,
      ),
      body: Column(
        children: [
          const HomeSearchBar(),

          HomeFilterTabs(
            selected: _selectedFilter,
            unreadCount: 0,
            groupsCount: 0,
            onChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
                _selection.clear();
                _isSelectedChatStarred = false;
              });
            },
            onAddPressed: () {},
          ),

          const SizedBox(height: 4),

          Expanded(
            child: ChatListView(
              stream: ChatStreamProvider.streamFor(_selectedFilter),
              selectedConversationId: _selection.selectedId,
              onTap: _onOpenChat,
              onLongPress: _onLongPressChat,
            ),
          ),
        ],
      ),
      floatingActionButton: HomeFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UsersScreen(),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // OPEN CHAT
  // ─────────────────────────────────────────────
  void _onOpenChat(String conversationId) {
    if (_selection.hasSelection) {
      _selection.clear();
      _isSelectedChatStarred = false;
      setState(() {});
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LONG PRESS → SELECT
  // ─────────────────────────────────────────────
  Future<void> _onLongPressChat(String conversationId) async {
    _selection.select(conversationId);

    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();

    _isSelectedChatStarred =
        snap.data()?['isStarred'] == true;

    setState(() {});
  }

  // ─────────────────────────────────────────────
  // STAR / UNSTAR
  // ─────────────────────────────────────────────
  Future<void> _onToggleStarSelectedChat() async {
    final id = _selection.selectedId;
    if (id == null) return;

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(id)
        .update({
      'isStarred': !_isSelectedChatStarred,
    });

    _selection.clear();
    _isSelectedChatStarred = false;
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // 🗑 DELETE CHAT (PER USER)
  // ─────────────────────────────────────────────
  Future<void> _onDeleteSelectedChat() async {
    final id = _selection.selectedId;
    if (id == null) return;

    final myUid = FirebaseAuth.instance.currentUser!.uid;

    await ChatDeleteManager.deleteChat(
      conversationId: id,
      myUid: myUid,
    );

    _selection.clear();
    _isSelectedChatStarred = false;
    setState(() {});
  }
}
