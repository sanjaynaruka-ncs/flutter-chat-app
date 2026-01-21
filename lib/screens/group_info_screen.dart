import 'package:flutter/material.dart';
import 'package:tokwalker/controllers/new_group_controller.dart';
import 'package:tokwalker/screens/chat_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final NewGroupController controller;

  const GroupInfoScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New group',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(
                Icons.camera_alt,
                size: 28,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              onChanged: controller.setGroupName,
              decoration: const InputDecoration(
                hintText: 'Group name',
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Provide a group subject and optional group icon',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return FloatingActionButton(
            onPressed: controller.canCreate
                ? () async {
                    final convoId = await controller.createGroup();
                    if (convoId == null) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(conversationId: convoId),
                      ),
                      (route) => route.isFirst,
                    );
                  }
                : null,
            child: const Icon(Icons.check),
          );
        },
      ),
    );
  }
}
