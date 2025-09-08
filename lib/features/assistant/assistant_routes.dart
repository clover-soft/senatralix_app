// Маршруты надфичи Assistant
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/screens/assistant_screen.dart';
import 'package:sentralix_app/features/assistant/screens/assistant_home_screen.dart';
import 'package:sentralix_app/features/assistant/features/settings/screens/settings_screen.dart';
import 'package:sentralix_app/features/assistant/features/tools/screens/tools_screen.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/screens/knowledge_screen.dart';
import 'package:sentralix_app/features/assistant/features/connectors/screens/connectors_screen.dart';
import 'package:sentralix_app/features/assistant/features/scripts/screens/scripts_screen.dart';
import 'package:sentralix_app/features/assistant/features/chat/screens/chat_screen.dart';
import 'package:sentralix_app/features/assistant/features/sessions/screens/sessions_screen.dart';

List<RouteBase> assistantRoutes() => [
  GoRoute(
    path: '/assistant',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantScreen()),
  ),
  // По умолчанию показываем настройки выбранного ассистента
  GoRoute(
    path: '/assistant/:assistantId',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantHomeScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/settings',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantSettingsScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/tools',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantToolsScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/knowledge',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantKnowledgeScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/connectors',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantConnectorsScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/scripts',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantScriptsScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/chat',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantChatScreen()),
  ),
  GoRoute(
    path: '/assistant/:assistantId/sessions',
    pageBuilder: (context, state) => const MaterialPage(child: AssistantSessionsScreen()),
  ),
];
