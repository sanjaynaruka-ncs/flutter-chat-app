import 'package:flutter/material.dart';

/// ✅ MUST be top-level (NOT inside class)
enum _MenuAction {
  search,
  clear,
  block,
  unblock,
  report,
  newGroup,
  viewContact,
}

class ChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  final VoidCallback? onSearch;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onClearChat;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final VoidCallback? onReport;
  final VoidCallback? onViewContact;
  final VoidCallback? onNewGroup;

  final bool isBlocked;

  /// ✅ SELECTION MODE SUPPORT
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback? onExitSelection;

  const ChatAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onSearch,
    this.onMuteToggle,
    this.onClearChat,
    this.onBlock,
    this.onUnblock,
    this.onReport,
    this.onViewContact,
    this.onNewGroup,
    this.isBlocked = false,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    this.onExitSelection,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return AppBar(
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onExitSelection,
        ),
        title: Text(
          selectedCount.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: const [
          Icon(Icons.reply),
          SizedBox(width: 16),
          Icon(Icons.star_border),
          SizedBox(width: 16),
          Icon(Icons.delete_outline),
          SizedBox(width: 16),
          Icon(Icons.forward),
          SizedBox(width: 12),
        ],
      );
    }

    final avatarLetter =
        title.isNotEmpty ? title[0].toUpperCase() : '?';

    return AppBar(
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.shade400,
            child: Text(
              avatarLetter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video calling coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice calling coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        /// ✅ CORRECT MENU PATTERN
        PopupMenuButton<_MenuAction>(
          onSelected: (action) {
            switch (action) {
              case _MenuAction.search:
                onSearch?.call();
                break;
              case _MenuAction.clear:
                onClearChat?.call();
                break;
              case _MenuAction.block:
                onBlock?.call();
                break;
              case _MenuAction.unblock:
                onUnblock?.call();
                break;
              case _MenuAction.report:
                onReport?.call();
                break;
              case _MenuAction.newGroup:
                onNewGroup?.call();
                break;
              case _MenuAction.viewContact:
                onViewContact?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _MenuAction.search,
              child: Text('Search'),
            ),
            const PopupMenuItem(
              value: _MenuAction.clear,
              child: Text('Clear chat'),
            ),
            if (!isBlocked)
              const PopupMenuItem(
                value: _MenuAction.block,
                child: Text('Block user'),
              ),
            if (isBlocked)
              const PopupMenuItem(
                value: _MenuAction.unblock,
                child: Text('Unblock user'),
              ),
            const PopupMenuItem(
              value: _MenuAction.report,
              child: Text('Report'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _MenuAction.newGroup,
              child: Text('New group'),
            ),
            const PopupMenuItem(
              value: _MenuAction.viewContact,
              child: Text('View contact'),
            ),
          ],
        ),
      ],
    );
  }
}
