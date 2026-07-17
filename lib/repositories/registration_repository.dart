import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/api/registration_models.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(ref.read(dioProvider));
});

class RegistrationRepository {
  RegistrationRepository(this._dio);

  final Dio _dio;

  Future<void> _persistTokenIfPresent(String? token) async {
    if (token != null && token.isNotEmpty) {
      await TokenStorage.saveToken(token);
    }
  }

  Future<PartnerOtpRequestResult> requestOtp(String email) async {
    try {
      final res = await _dio.post(ApiEndpoints.partnerRequestOtp, data: {
        'email': email.trim(),
      });
      return PartnerOtpRequestResult.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartnerOtpVerifyResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.partnerVerifyOtp, data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'purpose': 'SIGNUP',
      });
      final result = PartnerOtpVerifyResult.fromJson(unwrapObject(res.data));
      await _persistTokenIfPresent(result.accessToken);
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartnerRegisterStepResult> registerStep1(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.partnerRegisterStep1, data: payload);
      final result = PartnerRegisterStepResult.fromJson(unwrapObject(res.data));
      await _persistTokenIfPresent(result.accessToken);
      if (result.restaurantId.isEmpty) {
        throw ApiException('Registration step 1 did not return a restaurant id.');
      }
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartnerRegisterStepResult> registerStep2(
    String restaurantId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.partnerRegisterStep2(restaurantId),
        data: payload,
      );
      final result = PartnerRegisterStepResult.fromJson(unwrapObject(res.data));
      await _persistTokenIfPresent(result.accessToken);
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartnerRegisterStepResult> registerStep3(
    String restaurantId,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Force menu base64 fields to plain strings for Nest `@IsString()`.
      final data = Map<String, dynamic>.from(payload);
      for (final key in ['menuImageBase64', 'imageBase64', 'menuExtractedJson', 'mimeType']) {
        final v = data[key];
        if (v == null) {
          data[key] = '';
        } else if (v is! String) {
          data[key] = '$v';
        }
      }
      final res = await _dio.post(
        ApiEndpoints.partnerRegisterStep3(restaurantId),
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      final result = PartnerRegisterStepResult.fromJson(unwrapObject(res.data));
      await _persistTokenIfPresent(result.accessToken);
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RegistrationPricing> getPricing() async {
    try {
      final res = await _dio.get(ApiEndpoints.registrationPricing);
      return RegistrationPricing.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PanVerifyResult> verifyPan({
    required String pan,
    String? name,
    String? dateOfBirth,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.verifyPan, data: {
        'pan': pan,
        if (name != null && name.isNotEmpty) 'name': name,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
      });
      return PanVerifyResult.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<MenuScanCategory>> scanMenu({
    required String imageBase64,
    required String mimeType,
  }) async {
    final b64 = imageBase64.trim();
    if (b64.isEmpty) {
      throw ApiException('Menu image base64 must be a non-empty string.');
    }
    final mime = mimeType.trim().isEmpty ? 'image/jpeg' : mimeType.trim();
    try {
      final res = await _dio.post(
        ApiEndpoints.menuScan,
        data: <String, String>{
          'imageBase64': b64,
          'mimeType': mime,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = unwrapObject(res.data);
      final categories = (data['categories'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MenuScanCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return categories;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreateRegistrationOrderResponse> createPaymentOrder(String restaurantId) async {
    try {
      final res = await _dio.post(ApiEndpoints.registrationPaymentCreateOrder(restaurantId));
      return CreateRegistrationOrderResponse.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> verifyPayment(
    String restaurantId, {
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.registrationPaymentVerify(restaurantId),
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> uploadRegistrationDocument({
    required String restaurantId,
    required String type,
    required XFile file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
        'type': type,
      });
      await _dio.post(
        ApiEndpoints.registrationDocuments(restaurantId),
        data: formData,
      );
    } on DioException {
      // Non-fatal, same as web.
    }
  }

  Future<void> uploadCoverPhoto({
    required String restaurantId,
    required XFile file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      await _dio.post(
        ApiEndpoints.registrationCoverPhoto(restaurantId),
        data: formData,
      );
    } on DioException {
      // Non-fatal, same as web.
    }
  }
}
