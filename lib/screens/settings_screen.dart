import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
      ),
      body: ListView(
        children: const [
          _SettingsTile(
            icon: Icons.person,
            title: 'Account',
            subtitle: 'Security, change number',
          ),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Privacy',
            subtitle: 'Block contacts, disappearing messages',
          ),
          _SettingsTile(
            icon: Icons.chat,
            title: 'Chats',
            subtitle: 'Theme, wallpapers, chat history',
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Message, group & call tones',
          ),
          _SettingsTile(
            icon: Icons.storage,
            title: 'Storage & data',
            subtitle: 'Network usage, auto-download',
          ),
          Divider(height: 32),
          _SettingsTile(
            icon: Icons.list,
            title: 'Lists',
            subtitle: 'Manage people and groups',
          ),
          _SettingsTile(
            icon: Icons.campaign,
            title: 'Broadcasts',
            subtitle: 'Manage lists and send broadcasts',
          ),
          Divider(height: 32),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & feedback',
            subtitle: 'Help centre, contact us, privacy policy',
          ),
          _SettingsTile(
            icon: Icons.share,
            title: 'Invite a friend',
            subtitle: 'Share TokWalker with friends',
          ),
          _SettingsTile(
            icon: Icons.system_update,
            title: 'App updates',
            subtitle: 'Check for updates',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {}, // UI-only
    );
  }
}
