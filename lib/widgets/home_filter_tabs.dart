import 'package:flutter/material.dart';

enum HomeFilter {
  all,
  starred,
  groups,
}

class HomeFilterTabs extends StatelessWidget {
  final HomeFilter selected;
  final ValueChanged<HomeFilter> onChanged;
  final VoidCallback onAddPressed;

  // 🔹 Accepted from HomeScreen (UI only, no logic here)
  final int unreadCount;
  final int groupsCount;

  const HomeFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onAddPressed,
    this.unreadCount = 0,
    this.groupsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _expandedChip('All', HomeFilter.all),
          _expandedChip('Starred', HomeFilter.starred),
          _expandedChip('Groups', HomeFilter.groups),
          _addChip(),
        ],
      ),
    );
  }

  Widget _expandedChip(String label, HomeFilter value) {
    final bool isSelected = selected == value;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF25D366)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addChip() {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          size: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}
