import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/services/registration_service.dart';

class RegistrationDataProvider with ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();

  Future<void> registerStage1({
    required String email,
    required String mobilePhone,
  }) async {
    try {
      await _registrationService.register_stage1(
        email: email,
        mobilePhone: mobilePhone,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

final registrationDataProvider =
    ChangeNotifierProvider<RegistrationDataProvider>((ref) {
      return RegistrationDataProvider();
    });
