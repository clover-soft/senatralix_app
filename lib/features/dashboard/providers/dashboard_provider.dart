import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

/// Dashboard feature controller
/// comment: exposes logout that delegates to AuthDataProvider
class DashboardController {
  DashboardController(this.ref);
  final Ref ref;

  Future<void> logout() async {
    await ref.read(authDataProvider).logout();
  }
}

/// Riverpod provider for DashboardController
final dashboardControllerProvider = Provider<DashboardController>((ref) {
  return DashboardController(ref);
});
