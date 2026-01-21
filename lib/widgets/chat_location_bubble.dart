import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_status.dart'; // ✅ NEW (for ticks)

/// 📍 LOCATION MESSAGE BUBBLE
/// - Shows static map preview
/// - Opens Google Maps on tap
/// - Shows WhatsApp-style ticks for sender
class ChatLocationBubble extends StatelessWidget {
  final bool isMe;
  final String mapImageUrl;

  /// ✅ SELECTION STATE
  final bool isSelected;

  /// ✅ MESSAGE STATUS (sent / delivered / read)
  final MessageStatus status;

  const ChatLocationBubble({
    super.key,
    required this.isMe,
    required this.mapImageUrl,
    required this.isSelected,
    required this.status, // ✅ NEW
  });

  /// 📍 Open location in Google Maps (WhatsApp-style)
  Future<void> _openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${_extractLatLng(mapImageUrl)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// 🔍 Extract "lat,lng" from static map URL
  String _extractLatLng(String url) {
    final match =
        RegExp(r'center=([-0-9.]+),([-0-9.]+)').firstMatch(url);
    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }
    return '0,0'; // safe fallback
  }

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
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _openMap,
                    child: Container(
                      width: 240,
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
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          mapImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder:
                              (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              const Center(
                            child: Icon(
                              Icons.location_on,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
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

              // ── STATUS TICK (SENDER ONLY) ───────
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 4),
                  child: _StatusTick(status: status),
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
