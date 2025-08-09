import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/providers/registration_data_provider.dart';

class RegistrationProvider with ChangeNotifier {
  final RegistrationDataProvider _registrationDataProvider;

  RegistrationProvider(this._registrationDataProvider);

  Future<void> registerStage1({
    required String email,
    required String mobilePhone,
  }) async {
    try {
      await _registrationDataProvider.registerStage1(
        email: email,
        mobilePhone: mobilePhone,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

final registrationProvider = ChangeNotifierProvider<RegistrationProvider>((
  ref,
) {
  final registrationDataProviderObj = ref.read(registrationDataProvider);
  return RegistrationProvider(registrationDataProviderObj);
});
