import 'package:flutter/material.dart';
import '../controllers/chat_contact_action_controller.dart';
import '../models/message_status.dart'; // ✅ NEW (for ticks)

/// 👤 CONTACT MESSAGE BUBBLE
/// - Shows shared contact info
/// - Allows Message / Add Contact actions
/// - Shows WhatsApp-style ticks for sender
class ChatContactBubble extends StatelessWidget {
  final bool isMe;
  final String name;
  final String phone;

  /// ✅ SELECTION STATE
  final bool isSelected;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  /// 🔑 Parent-provided navigation callback
  /// (ChatScreen decides how to open chat)
  final void Function(String userId)? onOpenChat;

  ChatContactBubble({
    super.key,
    required this.isMe,
    required this.name,
    required this.phone,
    required this.isSelected,
    required this.status, // ✅ NEW
    this.onOpenChat,
  });

  final ChatContactActionController _actionCtrl =
      ChatContactActionController();

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isMe ? const Color(0xFFDCF8C6) : Colors.white;

    final align =
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: align,
        children: [
          Stack(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ─────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── ACTION BUTTONS ─────────────────
                    Row(
                      children: [
                        _ActionButton(
                          label: 'Message',
                          icon: Icons.chat,
                          onTap: () async {
                            final userId =
                                await _actionCtrl.findUserByPhone(phone);

                            if (userId != null) {
                              if (onOpenChat != null) {
                                onOpenChat!(userId);
                              }
                              return;
                            }

                            await _actionCtrl
                                .messageOrInvite(phone: phone);
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'Add Contact',
                          icon: Icons.person_add,
                          onTap: () {
                            _actionCtrl.addToContacts(
                              name: name,
                              phone: phone,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ⏱ TIME + ✔✔ STATUS (SENDER ONLY)
                    if (isMe)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _StatusTick(status: status),
                        ],
                      ),
                  ],
                ),
              ),

              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ───────────────── STATUS ICON (✔ / ✔✔ / BLUE ✔✔) ─────────────────
class _StatusTick extends StatelessWidget {
  final MessageStatus status;

  const _StatusTick({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _buildIcon(status),
    );
  }

  Widget _buildIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          key: const ValueKey(MessageStatus.sent),
          size: 20,
          color: const Color(0xFF25D366),
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          key: const ValueKey(MessageStatus.delivered),
          size: 20,
          color: const Color(0xFF25D366),
        );

      case MessageStatus.read:
        return Icon(
          Icons.done_all_rounded,
          key: const ValueKey(MessageStatus.read),
          size: 20,
          color: const Color(0xFF25D366),
        );
    }
  }
}

/// ─────────────────────────────────────────────
/// SMALL ACTION BUTTON
/// ─────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
