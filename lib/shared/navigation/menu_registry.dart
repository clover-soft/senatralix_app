import 'package:flutter/material.dart';

// comment: Registry of supported menu definitions on the client
class MenuDef {
  final String key;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String defaultLabel;

  const MenuDef({
    required this.key,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.defaultLabel,
  });
}

// comment: extend as needed; keys should match backend context keys
const Map<String, MenuDef> kMenuRegistry = {
  'dashboard': MenuDef(
    key: 'dashboard',
    route: '/',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    defaultLabel: 'Dashboard',
  ),
  'reports': MenuDef(
    key: 'reports',
    route: '/reports',
    icon: Icons.insert_chart_outlined,
    selectedIcon: Icons.insert_chart,
    defaultLabel: 'Reports',
  ),
  'profile': MenuDef(
    key: 'profile',
    route: '/profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    defaultLabel: 'Profile',
  ),
  'assistant': MenuDef(
    key: 'assistant',
    route: '/assistant',
    icon: Icons.smart_toy_outlined,
    selectedIcon: Icons.smart_toy,
    defaultLabel: 'Assistant',
  ),
};
