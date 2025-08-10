// comment: Shell layout providers (e.g., left menu expanded/collapsed)
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the left NavigationRail is expanded (with labels) or collapsed (icons only)
final shellRailExpandedProvider = StateProvider<bool>((ref) => true);
