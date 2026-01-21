import 'package:flutter/material.dart';

class ChatEmojiPicker extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const ChatEmojiPicker({
    super.key,
    required this.onEmojiSelected,
  });

  static const List<String> _emojis = [
    '😀','😁','😂','🤣','😊','😍','😘','😜','🤔','😎',
    '😭','😡','🥳','😴','🤯','👍','👎','🙏','👏','💪',
    '❤️','💔','🔥','⭐','🎉','🎂','🍕','☕','⚽','🚗',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // WhatsApp-like height
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: GridView.builder(
        itemCount: _emojis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return InkWell(
            onTap: () => onEmojiSelected(emoji),
            borderRadius: BorderRadius.circular(6),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}
