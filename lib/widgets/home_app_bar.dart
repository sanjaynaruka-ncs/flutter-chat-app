import 'package:flutter/material.dart';
import 'package:tokwalker/screens/settings_screen.dart';
import 'package:tokwalker/screens/new_group_screen.dart';
import 'package:tokwalker/screens/broadcast_list_screen.dart';

class HomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool hasSelection;
  final int selectedCount;

  /// ⭐ state of selected chat
  final bool isStarredSelected;

  /// true ONLY for All tab
  final bool showDelete;

  final VoidCallback? onStarToggle;
  final VoidCallback? onDeletePressed;

  const HomeAppBar({
    super.key,
    required this.hasSelection,
    required this.selectedCount,
    required this.isStarredSelected,
    required this.showDelete,
    this.onStarToggle,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    // ⭐ GOLDEN only when:
    // - selection mode
    // - All tab
    // - already starred (filled star)
    final bool useGoldenFilledStar =
        hasSelection && showDelete && isStarredSelected;

    return AppBar(
      elevation: 0.5,
      title: hasSelection
          ? Text(
              selectedCount.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            )
          : const Text(
              'TokWalker',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
      actions: hasSelection
          ? [
              // ⭐ Star action
              IconButton(
                icon: Icon(
                  isStarredSelected
                      ? Icons.star
                      : Icons.star_border,
                  color:
                      useGoldenFilledStar ? Colors.amber : null,
                ),
                tooltip: 'Star',
                onPressed: onStarToggle,
              ),

              // 🗑️ Delete (ONLY in All tab)
              if (showDelete)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: onDeletePressed,
                ),
            ]
          : [
              PopupMenuButton<_HomeMenuAction>(
                onSelected: (action) {
                  switch (action) {
                    case _HomeMenuAction.newGroup:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NewGroupScreen(),
                        ),
                      );
                      break;

                    case _HomeMenuAction.broadcasts:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BroadcastListScreen(),
                        ),
                      );
                      break;

                    case _HomeMenuAction.starred:
                      break;

                    case _HomeMenuAction.settings:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SettingsScreen(),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HomeMenuAction.newGroup,
                    child: Text('New group'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.broadcasts,
                    child: Text('Broadcast lists'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.starred,
                    child: Text('Starred'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _HomeMenuAction.settings,
                    child: Text('Settings'),
                  ),
                ],
              ),
            ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}

enum _HomeMenuAction {
  newGroup,
  broadcasts,
  starred,
  settings,
}
