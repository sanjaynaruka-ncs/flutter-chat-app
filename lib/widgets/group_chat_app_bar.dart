import 'package:flutter/material.dart';

class GroupChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const GroupChatAppBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        PopupMenuButton<_GroupMenuAction>(
          onSelected: (_) {}, // UI-only
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _GroupMenuAction.addMembers,
              child: Text('Add members'),
            ),
            PopupMenuItem(
              value: _GroupMenuAction.groupInfo,
              child: Text('Group info'),
            ),
            PopupMenuItem(
              value: _GroupMenuAction.search,
              child: Text('Search'),
            ),
            PopupMenuItem(
              value: _GroupMenuAction.mute,
              child: Text('Mute notifications'),
            ),
            PopupMenuItem(
              value: _GroupMenuAction.clear,
              child: Text('Clear chat'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: _GroupMenuAction.exit,
              child: Text(
                'Exit group',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

enum _GroupMenuAction {
  addMembers,
  groupInfo,
  search,
  mute,
  clear,
  exit,
}
