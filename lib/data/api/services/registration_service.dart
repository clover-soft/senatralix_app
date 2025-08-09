// Registration service is responsible for user registration API calls.
// It depends on ApiClient to perform HTTP requests.
// Adapt endpoint paths and ApiClient method names to your backend/client implementation.

import '../api_client.dart';

class RegistrationService {
  final ApiClient _apiClient = ApiClient();

  // Stage 1: submit contact info to receive SMS code
  // params: email, mobilePhone
  Future<void> register_stage1({
    required String email,
    required String mobilePhone,
  }) async {
    final payload = {'email': email, 'mobilePhone': mobilePhone};

    // NOTE: Adjust the endpoint and ApiClient call to your actual API.
    await _apiClient.post('/registration/stage1', data: payload);
  }

  // Stage 2: confirm by smsCode and set password
  // params: smsCode, password
  Future<void> register_stage2({
    required String smsCode,
    required String password,
  }) async {
    final payload = {'smsCode': smsCode, 'password': password};

    // NOTE: Adjust the endpoint and ApiClient call to your actual API.
    await _apiClient.post('/registration/stage2', data: payload);
  }
}
