import 'package:flutter/material.dart';

enum UserRole {
  admin('Admin', Icons.admin_panel_settings_outlined),
  pegawai('Pegawai', Icons.badge_outlined);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;
}
