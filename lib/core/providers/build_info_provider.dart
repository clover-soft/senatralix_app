import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String _defaultVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.2',
);
const String _defaultBuildNumber = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '3',
);

/// Fallback-информация о сборке, если `PackageInfo.fromPlatform()` недоступен
Future<PackageInfo> _fallbackPackageInfo() async {
  return PackageInfo(
    appName: 'Sentralix App',
    packageName: 'sentralix_app',
    version: _defaultVersion,
    buildNumber: _defaultBuildNumber,
    buildSignature: '',
    installerStore: null,
  );
}

/// Асинхронный провайдер сведений о сборке приложения
final buildInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isEmpty && info.buildNumber.isEmpty) {
      return await _fallbackPackageInfo();
    }
    return info;
  } catch (_) {
    return await _fallbackPackageInfo();
  }
});
