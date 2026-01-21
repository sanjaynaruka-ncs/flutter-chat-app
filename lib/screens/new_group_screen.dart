import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tokwalker/controllers/new_group_controller.dart';
import 'package:tokwalker/helpers/contact_resolver.dart';
import 'package:tokwalker/screens/group_info_screen.dart';

class NewGroupScreen extends StatelessWidget {
  const NewGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NewGroupController();
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New group',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              _SelectedMembersBar(controller: controller),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != myUid)
                        .toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text('No users found'),
                      );
                    }

                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = users[index];
                        final uid = doc.id;
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final phone = data['phone'] ?? '';

                        final displayName =
                            ContactResolver.resolve(phone);

                        final isSelected =
                            controller.selectedUserIds.contains(uid);

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(displayName),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) =>
                                controller.toggleUser(uid),
                          ),
                          onTap: () =>
                              controller.toggleUser(uid),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return FloatingActionButton(
            onPressed: controller.selectedUserIds.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupInfoScreen(controller: controller),
                      ),
                    );
                  }
                : null,
            child: const Icon(Icons.arrow_forward),
          );
        },
      ),
    );
  }
}

class _SelectedMembersBar extends StatelessWidget {
  final NewGroupController controller;

  const _SelectedMembersBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.selectedUserIds.isEmpty) {
      return const SizedBox(height: 72);
    }

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: controller.selectedUserIds.map((uid) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    uid.substring(uid.length - 1).toUpperCase(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uid,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
