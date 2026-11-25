import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user, required this.onLogout});

  final UserModel user;
  final Future<void> Function() onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your account and financial records will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await onLogout();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not log out: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const AppLogo(size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text('@${user.username}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Private by design'),
              subtitle: const Text(
                'Your financial records stay on this device.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFB3261E),
              ),
              title: const Text('Log out'),
              subtitle: const Text('End your current session'),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
