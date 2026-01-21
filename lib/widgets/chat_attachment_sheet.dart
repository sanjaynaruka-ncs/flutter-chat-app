import 'package:flutter/material.dart';

/// 📎 ChatAttachmentSheet
///
/// UI-ONLY bottom sheet for chat attachments.
///
/// RESPONSIBILITIES:
/// - Render attachment icons (Gallery, Document, Contact, Location, Audio)
/// - Forward user intent via callbacks
///
/// ❌ DOES NOT:
/// - Pick files
/// - Access device storage
/// - Contain any business logic
///
/// All logic MUST live in:
/// - ChatInputBar
/// - ChatScreen / Services
class ChatAttachmentSheet extends StatelessWidget {
  /// 📷 Gallery (images)
  final VoidCallback? onGalleryTap;

  /// 📄 Document (PDF, ZIP, etc.)
  final VoidCallback? onDocumentTap;

  /// 👤 Contact
  final VoidCallback? onContactTap;

  /// 📍 Location
  final VoidCallback? onLocationTap;

  /// 🔊 Audio (device audio files)
  final VoidCallback? onAudioTap;

  const ChatAttachmentSheet({
    super.key,
    this.onGalleryTap,
    this.onDocumentTap,
    this.onContactTap,
    this.onLocationTap,
    this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── DRAG HANDLE ─────────────────────────
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── ATTACHMENT ICONS ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AttachmentItem(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    onGalleryTap?.call();
                  },
                ),

                _AttachmentItem(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    onDocumentTap?.call();
                  },
                ),

                _AttachmentItem(
                  icon: Icons.person,
                  label: 'Contact',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    onContactTap?.call();
                  },
                ),

                _AttachmentItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    onLocationTap?.call();
                  },
                ),

                /// 🔊 AUDIO — UI ONLY
                _AttachmentItem(
                  icon: Icons.headset,
                  label: 'Audio',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onAudioTap?.call();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 📦 SINGLE ATTACHMENT ITEM (DUMB UI)
// ─────────────────────────────────────────────
class _AttachmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AttachmentItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
