import 'package:flutter/material.dart';
import 'package:sentralix_app/core/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/services/registration_service.dart';

class RegistrationDataProvider with ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();

  Future<void> registerStage1({
    required String email,
    required String mobilePhone,
  }) async {
    try {
      await _registrationService.registerStage1(
        email: email,
        mobilePhone: mobilePhone,
      );
    } catch (e) {
      AppLogger.e(e.toString(), tag: 'RegistrationDataProvider');
    }
  }
}

final registrationDataProvider =
    ChangeNotifierProvider<RegistrationDataProvider>((ref) {
      return RegistrationDataProvider();
    });
