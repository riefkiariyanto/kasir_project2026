import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../models/user_role.dart';
import '../routing/app_routes.dart';

class RoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RoleAppBar({super.key, required this.title, required this.role});

  final String title;
  final UserRole role;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _logout(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title),
      actions: <Widget>[
        Center(
          child: Chip(
            avatar: Icon(role.icon, size: 18),
            label: Text(role.label),
            visualDensity: VisualDensity.compact,
          ),
        ),
        IconButton(
          onPressed: () => _logout(context),
          tooltip: AppStrings.logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}
