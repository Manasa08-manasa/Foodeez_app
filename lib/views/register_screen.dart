import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../controllers/navigation_controller.dart';
import '../core/network/api_client.dart';
import '../core/utils/menu_scan_utils.dart';
import '../models/api/registration_models.dart';
import '../repositories/registration_repository.dart';
import '../services/razorpay_checkout_service.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import '../widgets/payment_app_selector.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _legalEntityCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _gstExpiryCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();
  final _fssaiExpiryCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountHolderCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _bankAccountConfirmCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _leadSourceCtrl = TextEditingController();
  final _brandDescCtrl = TextEditingController();
  final _cuisineTagsCtrl = TextEditingController();
  final _serviceRadiusCtrl = TextEditingController();
  final _panNameCtrl = TextEditingController();
  final _panDobCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  late final Razorpay _razorpay;

  /// email → otp → form (steps 1–3)
  String _authPhase = 'email';
  String _gstPresent = '';
  String _accountType = '';
  String _step = '1';
  bool _temporaryClosure = false;
  bool _holidayMode = false;
  bool _reviewConfirmed = false;
  String _submitStatus = 'idle';
  String _serverError = '';
  String _successMessage = '';
  String? _panVerifyMessage;
  bool _panVerifying = false;
  String? _panVerifiedName;
  String _panDob = '';
  String _panName = '';
  String _geoStatus = 'idle';
  bool _otpBusy = false;
  bool _step1Done = false;
  bool _step2Done = false;
  RegistrationPricing? _pricing;
  String? _registeredRestaurantId;
  String? _pendingRestaurantId;
  bool _menuScanning = false;
  String _menuScanError = '';
  List<MenuScanCategory>? _menuExtracted;
  XFile? _panFile;
  XFile? _gstFile;
  XFile? _fssaiFile;
  XFile? _bankFile;
  XFile? _coverPhotoFile;
  XFile? _menuFile;
  RegistrationPaymentApp _selectedPaymentApp = RegistrationPaymentApp.phonepe;

  bool get _submitting => _submitStatus == 'loading' || _submitStatus == 'paying' || _otpBusy;

  static const _fieldGap = 12.0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose();
    _legalEntityCtrl.dispose();
    _ownerCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _gstCtrl.dispose();
    _gstExpiryCtrl.dispose();
    _fssaiCtrl.dispose();
    _fssaiExpiryCtrl.dispose();
    _panCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountHolderCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankAccountConfirmCtrl.dispose();
    _ifscCtrl.dispose();
    _leadSourceCtrl.dispose();
    _brandDescCtrl.dispose();
    _cuisineTagsCtrl.dispose();
    _serviceRadiusCtrl.dispose();
    _panNameCtrl.dispose();
    _panDobCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    try {
      final pricing = await ref.read(registrationRepositoryProvider).getPricing();
      if (mounted) setState(() => _pricing = pricing);
    } catch (_) {
      // Best-effort banner; payment is enforced server-side.
    }
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    final emailErr = _emailValidator(email);
    if (emailErr != null) {
      setState(() => _serverError = emailErr);
      return;
    }
    setState(() {
      _otpBusy = true;
      _serverError = '';
      _successMessage = '';
    });
    try {
      await ref.read(registrationRepositoryProvider).requestOtp(email);
      setState(() {
        _authPhase = 'otp';
        _successMessage = 'OTP sent to $email. Enter it below to continue.';
      });
    } on ApiException catch (e) {
      setState(() => _serverError = e.message);
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _otpBusy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _serverError = 'Enter the OTP sent to your email.');
      return;
    }
    setState(() {
      _otpBusy = true;
      _serverError = '';
      _successMessage = '';
    });
    try {
      await ref.read(registrationRepositoryProvider).verifyOtp(email: email, otp: otp);
      setState(() {
        _authPhase = 'form';
        _step = '1';
        _successMessage = 'Email verified. Continue with restaurant registration.';
      });
      _loadPricing();
    } on ApiException catch (e) {
      setState(() => _serverError = e.message);
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _otpBusy = false);
    }
  }

  Future<void> _pickFile(
    Function(XFile?) onPicked, {
    List<String> extensions = const [],
    List<String> mimeTypes = const [],
    String label = 'file',
  }) async {
    // Empty extensions/mimeTypes = no restriction (accept any image/file).
    final typeGroup = XTypeGroup(
      label: label,
      extensions: extensions.isEmpty ? null : extensions,
      mimeTypes: mimeTypes.isEmpty ? null : mimeTypes,
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    onPicked(file);
  }

  Future<void> _pickMenuImage(Function(XFile?) onPicked) async {
    // Accept all PNG/JPEG (and other images) — no extension restriction.
    final typeGroup = const XTypeGroup(
      label: 'Menu image',
      mimeTypes: ['image/*', 'image/png', 'image/jpeg', 'image/jpg'],
    );
    final anyGroup = const XTypeGroup(label: 'Any file');
    final file = await openFile(acceptedTypeGroups: [typeGroup, anyGroup]);
    if (file == null) return;
    onPicked(file);
  }

  Future<void> _captureLocation() async {
    setState(() => _geoStatus = 'loading');
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _geoStatus = 'error');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitudeCtrl.text = pos.latitude.toStringAsFixed(6);
        _longitudeCtrl.text = pos.longitude.toStringAsFixed(6);
        _geoStatus = 'idle';
      });
    } catch (_) {
      setState(() => _geoStatus = 'error');
    }
  }

  Future<void> _verifyPan() async {
    final pan = _panCtrl.text.trim().toUpperCase();
    if (pan.isEmpty || !RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan)) {
      setState(() => _panVerifyMessage = 'Enter a valid PAN to verify.');
      return;
    }
    setState(() {
      _panVerifying = true;
      _panVerifyMessage = null;
      _panVerifiedName = null;
    });
    try {
      final result = await ref.read(registrationRepositoryProvider).verifyPan(
            pan: pan,
            name: _panName.trim().isEmpty ? null : _panName.trim(),
            dateOfBirth: _panDob.isEmpty ? null : _panDob.split('-').reversed.join('/'),
          );
      setState(() {
        _panVerifying = false;
        _panVerifyMessage = result.valid
            ? (result.message ?? 'PAN verified successfully')
            : (result.message ?? 'Unable to verify PAN');
        _panVerifiedName = result.valid ? result.name : null;
      });
    } catch (e) {
      setState(() {
        _panVerifying = false;
        _panVerifyMessage = e is ApiException ? e.message : 'Verification service unavailable.';
      });
    }
  }

  bool _validateStep1() {
    _formKey.currentState?.save();
    final fields = [
      _legalEntityCtrl,
      _nameCtrl,
      _ownerCtrl,
      _emailCtrl,
      _phoneCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _zipCtrl,
    ];
    var valid = true;
    for (final ctrl in fields) {
      final err = _required(ctrl.text);
      if (err != null) valid = false;
    }
    if (_emailValidator(_emailCtrl.text) != null) valid = false;
    if (_phoneValidator(_phoneCtrl.text) != null) valid = false;
    if (_zipValidator(_zipCtrl.text) != null) valid = false;
    if (_ownerValidator(_ownerCtrl.text) != null) valid = false;
    if (!valid) {
      setState(() => _serverError = 'Please fix the highlighted fields before proceeding.');
      _formKey.currentState?.validate();
      return false;
    }
    setState(() => _serverError = '');
    return true;
  }

  bool _validateStep2() {
    _formKey.currentState?.save();
    var valid = true;
    if (_gstPresent == 'yes') {
      if (_gstValidator(_gstCtrl.text) != null) valid = false;
      if (_dateNotPastValidator(_gstExpiryCtrl.text) != null) valid = false;
    }
    if (_fssaiValidator(_fssaiCtrl.text) != null) valid = false;
    if (_dateNotPastValidator(_fssaiExpiryCtrl.text) != null) valid = false;
    if (_panValidator(_panCtrl.text) != null) valid = false;
    if (_required(_bankNameCtrl.text) != null) valid = false;
    if (_required(_bankAccountHolderCtrl.text) != null) valid = false;
    if (_bankAccountValidator(_bankAccountCtrl.text) != null) valid = false;
    if (_confirmBankValidator(_bankAccountConfirmCtrl.text) != null) valid = false;
    if (_accountType.isEmpty) valid = false;
    if (_ifscValidator(_ifscCtrl.text) != null) valid = false;

    if (_gstPresent == 'yes' && _gstFile == null) {
      setState(() => _serverError = 'Please upload the GST document.');
      return false;
    }
    if (_panFile == null) {
      setState(() => _serverError = 'Please upload the PAN document.');
      return false;
    }
    if (_fssaiFile == null) {
      setState(() => _serverError = 'Please upload the FSSAI document.');
      return false;
    }
    if (_bankFile == null) {
      setState(() => _serverError = 'Please upload the bank document.');
      return false;
    }
    if (!valid) {
      setState(() => _serverError = 'Please fix the highlighted fields before proceeding.');
      _formKey.currentState?.validate();
      return false;
    }
    setState(() => _serverError = '');
    return true;
  }

  Future<void> _scanMenu() async {
    if (_menuFile == null) {
      setState(() => _menuScanError = 'Please select a menu image (PNG/JPEG) before scanning.');
      return;
    }
    setState(() {
      _menuScanError = '';
      _menuScanning = true;
    });
    try {
      final encoded = await encodeMenuFile(_menuFile!);
      if (encoded.b64.isEmpty) {
        setState(() => _menuScanError = 'Could not encode menu image as base64 string.');
        return;
      }
      final repo = ref.read(registrationRepositoryProvider);
      try {
        final categories = await repo.scanMenu(
          imageBase64: encoded.b64,
          mimeType: encoded.mime,
        );
        setState(() {
          _menuExtracted = categories.isNotEmpty
              ? categories
              : [
                  const MenuScanCategory(
                    name: 'scanned',
                    displayName: 'Scanned menu',
                    items: [MenuScanItem(name: 'Scanned item', price: '0', currency: 'INR')],
                  ),
                ];
        });
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          setState(() {
            _menuExtracted = const [
              MenuScanCategory(
                name: 'scanned',
                displayName: 'Scanned menu (preview)',
                items: [MenuScanItem(name: 'Scanned item', price: '0', currency: 'INR')],
              ),
            ];
          });
        } else {
          setState(() => _menuScanError = e.message.isNotEmpty ? e.message : 'Failed to extract menu. Please try again.');
        }
      }
    } catch (e) {
      setState(() => _menuScanError = 'Failed to read menu image: $e');
    } finally {
      if (mounted) setState(() => _menuScanning = false);
    }
  }

  /// Removes nulls so Nest `@IsString()` fields never receive `null`.
  Map<String, dynamic> _cleanPayload(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value == null) return;
      out[key] = value;
    });
    return out;
  }

  Map<String, dynamic> _buildStep1Payload() {
    String? optional(String value) => value.trim().isEmpty ? null : value.trim();
    final lat = double.tryParse(_latitudeCtrl.text.trim());
    final lng = double.tryParse(_longitudeCtrl.text.trim());
    return _cleanPayload({
      'name': optional(_nameCtrl.text),
      'legalEntity': optional(_legalEntityCtrl.text),
      'legalEntityName': optional(_legalEntityCtrl.text),
      'ownerName': optional(_ownerCtrl.text),
      'email': optional(_emailCtrl.text),
      'phone': optional(_phoneCtrl.text),
      'address': optional(_addressCtrl.text),
      'city': optional(_cityCtrl.text),
      'state': optional(_stateCtrl.text),
      'zipCode': optional(_zipCtrl.text),
      'latitude': lat ?? 0,
      'longitude': lng ?? 0,
    });
  }

  Map<String, dynamic> _buildStep2Payload() {
    String? optional(String value) => value.trim().isEmpty ? null : value.trim();
    return _cleanPayload({
      'gstPresent': _gstPresent == 'yes',
      'gstNumber': optional(_gstCtrl.text),
      'gstExpiryDate': optional(_gstExpiryCtrl.text),
      'fssaiNumber': optional(_fssaiCtrl.text),
      'fssaiExpiryDate': optional(_fssaiExpiryCtrl.text),
      'panNumber': optional(_panCtrl.text),
      'bankName': optional(_bankNameCtrl.text),
      'bankAccountHolderName': optional(_bankAccountHolderCtrl.text),
      'bankAccountNumber': optional(_bankAccountCtrl.text),
      'bankAccountNumberConfirm': optional(_bankAccountConfirmCtrl.text),
      'accountType': _accountType.isEmpty ? null : _accountType,
      'ifscCode': optional(_ifscCtrl.text),
    });
  }

  /// Menu is optional. Backend `@IsString() menuImageBase64` needs a real string
  /// (empty string when no menu — never null / bytes / object).
  Future<Map<String, dynamic>> _buildStep3Payload() async {
    String? optional(String value) => value.trim().isEmpty ? null : value.trim();
    final radius = double.tryParse(_serviceRadiusCtrl.text.trim());

    // Always a Dart String for Nest validation.
    var menuImageBase64 = '';
    var menuMimeType = '';

    if (_menuFile != null) {
      final encoded = await encodeMenuFile(_menuFile!);
      menuImageBase64 = encoded.b64;
      menuMimeType = encoded.mime;
      if (menuImageBase64.isEmpty) {
        throw ApiException('Menu image could not be encoded as a base64 string.');
      }
    }

    final menuExtractedJson = _menuExtracted == null
        ? ''
        : jsonEncode(_menuExtracted!.map((e) => e.toJson()).toList());

    return _cleanPayload({
      'leadSource': optional(_leadSourceCtrl.text),
      'brandDescription': optional(_brandDescCtrl.text),
      'cuisineTags': _cuisineTagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'serviceRadiusKm': ?radius,
      'temporaryClosure': _temporaryClosure,
      'holidayMode': _holidayMode,
      // Required string fields — empty when menu skipped.
      'menuImageBase64': menuImageBase64,
      'imageBase64': menuImageBase64,
      'mimeType': menuMimeType.isEmpty ? 'image/jpeg' : menuMimeType,
      'menuExtractedJson': menuExtractedJson,
      'status': 'review',
    });
  }

  Future<void> _submitStep1() async {
    if (!_validateStep1()) return;
    setState(() {
      _submitStatus = 'loading';
      _serverError = '';
      _successMessage = '';
    });
    try {
      final repo = ref.read(registrationRepositoryProvider);
      if (!_step1Done || _registeredRestaurantId == null) {
        final result = await repo.registerStep1(_buildStep1Payload());
        _registeredRestaurantId = result.restaurantId;
        _step1Done = true;
      }
      setState(() {
        _submitStatus = 'idle';
        _step = '2';
        _successMessage = 'Step 1 saved. Continue with compliance & banking.';
      });
    } on ApiException catch (e) {
      setState(() {
        _submitStatus = 'error';
        if (e.statusCode == 409) {
          _serverError = 'A restaurant with this email, phone, or address already exists.';
        } else {
          _serverError = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e.toString();
      });
    }
  }

  Future<void> _submitStep2() async {
    if (!_validateStep2()) return;
    final restaurantId = _registeredRestaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      setState(() => _serverError = 'Complete step 1 first.');
      return;
    }
    setState(() {
      _submitStatus = 'loading';
      _serverError = '';
      _successMessage = '';
    });
    try {
      final repo = ref.read(registrationRepositoryProvider);
      if (!_step2Done) {
        await repo.registerStep2(restaurantId, _buildStep2Payload());
        _step2Done = true;
      }
      setState(() {
        _submitStatus = 'idle';
        _step = '3';
        _successMessage = 'Step 2 saved. Add brand details and complete payment.';
      });
    } on ApiException catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e.message;
      });
    } catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e.toString();
      });
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _submitStatus = 'loading';
      _serverError = '';
      _successMessage = '';
    });

    try {
      final repo = ref.read(registrationRepositoryProvider);
      var restaurantId = _registeredRestaurantId;
      if (restaurantId == null || restaurantId.isEmpty) {
        throw ApiException('Complete steps 1 and 2 before submitting.');
      }
      await repo.registerStep3(restaurantId, await _buildStep3Payload());
      await _runRegistrationPayment(restaurantId);
    } on ApiException catch (e) {
      setState(() {
        _submitStatus = 'error';
        if (e.statusCode == 409) {
          _serverError = 'A restaurant with this email, phone, or address already exists.';
        } else {
          _serverError = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e.toString();
      });
    }
  }

  Future<void> _runRegistrationPayment(String restaurantId) async {
    try {
      final order = await ref.read(registrationRepositoryProvider).createPaymentOrder(restaurantId);
      _pendingRestaurantId = restaurantId;
      setState(() => _submitStatus = 'paying');

      final options = RazorpayCheckoutService.buildOptions(
        order: order,
        ownerName: _ownerCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        restaurantId: restaurantId,
        paymentApp: _selectedPaymentApp,
      );
      _razorpay.open(options);
    } on ApiException catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e.message;
      });
    } catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = 'Could not start payment. Please try again.';
      });
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final restaurantId = _pendingRestaurantId ?? _registeredRestaurantId;
    if (restaurantId == null) return;
    setState(() => _submitStatus = 'loading');
    try {
      await ref.read(registrationRepositoryProvider).verifyPayment(
            restaurantId,
            razorpayOrderId: response.orderId ?? '',
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          );
      await _finishRegistration(restaurantId);
    } catch (e) {
      setState(() {
        _submitStatus = 'error';
        _serverError = e is ApiException
            ? e.message
            : 'Payment verification failed. Please contact support before retrying.';
      });
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _submitStatus = 'error';
      final message = response.message?.trim();
      _serverError = message != null && message.isNotEmpty
          ? message
          : 'Payment was cancelled. Tap "Submit for review" again to retry payment — your details are already saved.';
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('Opening external wallet: ${response.walletName}');
  }

  Future<void> _finishRegistration(String restaurantId) async {
    final repo = ref.read(registrationRepositoryProvider);
    for (final entry in [
      ('PAN', _panFile),
      ('GST', _gstFile),
      ('FSSAI', _fssaiFile),
      ('BANK', _bankFile),
    ]) {
      if (entry.$2 == null) continue;
      await repo.uploadRegistrationDocument(
        restaurantId: restaurantId,
        type: entry.$1,
        file: entry.$2!,
      );
    }
    if (_coverPhotoFile != null) {
      await repo.uploadCoverPhoto(restaurantId: restaurantId, file: _coverPhotoFile!);
    }
    setState(() {
      _submitStatus = 'success';
      _successMessage =
          'Restaurant submitted for review. ${_nameCtrl.text.trim().isEmpty ? 'Your restaurant' : _nameCtrl.text.trim()} is now pending admin review.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) ref.read(navigationControllerProvider).tab('login');
  }

  Future<void> _handleSubmit() async {
    setState(() => _serverError = '');
    if (!_formKey.currentState!.validate()) {
      setState(() => _serverError = 'Please fix the highlighted fields before submitting.');
      return;
    }
    if (!_reviewConfirmed) {
      setState(() => _serverError = 'Please confirm that you reviewed all details before submitting.');
      return;
    }
    if (_gstPresent == 'yes' && _gstFile == null) {
      setState(() => _serverError = 'GST document upload is required. Please go back to step 2.');
      return;
    }
    if (_panFile == null || _fssaiFile == null || _bankFile == null) {
      setState(() => _serverError = 'Required documents are missing. Please go back to step 2.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm submission'),
        content: Text(
          'You are about to submit this restaurant registration for super-admin review. '
          'Payment will open in ${_selectedPaymentApp.label}'
          '${_pricing != null ? ' for ₹${_pricing!.effectivePrice.toStringAsFixed(0)}' : ''}'
          ' — once paid, the details, uploaded documents, and optional menu information are sent for approval.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed == true) await _submitRegistration();
  }

  double _fieldWidth(BuildContext context, {int columns = 1}) {
    final maxW = MediaQuery.sizeOf(context).width - 68;
    if (columns <= 1 || maxW < 520) return maxW;
    return (maxW - _fieldGap * (columns - 1)) / columns;
  }

  Widget _fieldSpacer() => const SizedBox(height: _fieldGap);

  Widget _responsiveFields(BuildContext context, List<Widget> fields, {int columns = 2}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) _fieldSpacer(),
            fields[i],
          ],
        ],
      );
    }
    return Wrap(
      spacing: _fieldGap,
      runSpacing: _fieldGap,
      children: fields
          .map((field) => SizedBox(width: _fieldWidth(context, columns: columns), child: field))
          .toList(),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentDeep, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 16))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Restaurant onboarding', style: AppText.body(size: 13.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 2),
                Text(
                  'Create a polished partner profile with compliance, banking, and brand details in one flow.',
                  style: AppText.body(size: 12.5, color: Colors.white.withValues(alpha: 0.86)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
            child: Text(
              _authPhase == 'form' ? 'Step $_step / 3' : (_authPhase == 'otp' ? 'OTP' : 'Email'),
              style: AppText.body(size: 11.5, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBanner() {
    final pricing = _pricing;
    if (pricing == null) return const SizedBox.shrink();
    final hasOffer = pricing.isOfferActive && pricing.offerPrice < pricing.basePrice;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.maroonTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registration fee', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (hasOffer) ...[
                Text(
                  '₹${pricing.basePrice.toStringAsFixed(0)}',
                  style: AppText.body(size: 14, color: AppColors.bodyGrey).copyWith(decoration: TextDecoration.lineThrough),
                ),
                const SizedBox(width: 8),
              ],
              Text('₹${pricing.effectivePrice.toStringAsFixed(0)}', style: AppText.body(size: 22, weight: FontWeight.w800, color: AppColors.accentDeep)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Choose your payment app below. On submit, Razorpay opens ${_selectedPaymentApp.label} to complete the registration fee. Documents upload after payment succeeds.",
            style: AppText.body(size: 12, color: AppColors.bodyGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.maroonTint, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accentDeep)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStepOne() {
    return Builder(
      builder: (context) => _buildSectionCard(
      title: 'Restaurant essentials',
      subtitle: 'Begin with the core business identity and location details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _responsiveFields(context, [
            _field('Legal entity name', controller: _legalEntityCtrl, validator: _requiredMin2, maxLength: 100),
            _field('Restaurant name', controller: _nameCtrl, validator: _requiredMin2, maxLength: 100),
            _field('Owner name', controller: _ownerCtrl, validator: _ownerValidator, maxLength: 100),
          ], columns: 3),
          _fieldSpacer(),
          _responsiveFields(context, [
            _field('Email', controller: _emailCtrl, validator: _emailValidator, keyboardType: TextInputType.emailAddress, readOnly: true),
            _field('Phone', controller: _phoneCtrl, validator: _phoneValidator, keyboardType: TextInputType.phone, maxLength: 10),
          ]),
          if (_serverError.isNotEmpty && _step == '1') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_serverError, style: TextStyle(color: AppColors.red)),
            ),
          ],
          if (_successMessage.isNotEmpty && _step == '1') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_successMessage, style: const TextStyle(color: Colors.green)),
            ),
          ],
          _fieldSpacer(),
          _field('Address', controller: _addressCtrl, validator: _required),
          _fieldSpacer(),
          _responsiveFields(context, [
            _field('City', controller: _cityCtrl, validator: _required),
            _field('State', controller: _stateCtrl, validator: _required),
            _field('PIN code', controller: _zipCtrl, validator: _zipValidator, keyboardType: TextInputType.number, maxLength: 6),
          ], columns: 3),
          _fieldSpacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.inputBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Location coordinates', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep)),
                const SizedBox(height: 8),
                _responsiveFields(context, [
                  _field('Latitude', controller: _latitudeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  _field('Longitude', controller: _longitudeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _geoStatus == 'loading' ? null : _captureLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(_geoStatus == 'loading' ? 'Capturing…' : 'Auto-capture location'),
                  ),
                ),
                if (_geoStatus == 'error') ...[
                  const SizedBox(height: 8),
                  Text('Could not capture location. Enter coordinates manually or try again.', style: TextStyle(color: AppColors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _actionButton(_submitting ? 'Saving…' : 'Proceed to compliance', _submitting ? () {} : _submitStep1),
        ],
      ),
    ),
    );
  }

  Widget _buildStepTwo() {
    return Builder(
      builder: (context) => _buildSectionCard(
      title: 'Compliance & banking',
      subtitle: 'Add compliance details and upload the required documents for review.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'Is GST available?',
            child: DropdownButtonFormField<String>(
              initialValue: _gstPresent.isEmpty ? null : _gstPresent,
              decoration: _inputDecoration('Is GST available?'),
              items: const [
                DropdownMenuItem(value: 'yes', child: Text('Yes')),
                DropdownMenuItem(value: 'no', child: Text('No')),
              ],
              onChanged: (v) => setState(() {
                _gstPresent = v ?? '';
                if (_gstPresent != 'yes') _gstFile = null;
              }),
            ),
          ),
          if (_gstPresent == 'yes') ...[
            _fieldSpacer(),
            _responsiveFields(context, [
              _field('GSTIN', controller: _gstCtrl, validator: _gstValidator, maxLength: 15),
              _field('GST expiry date', controller: _gstExpiryCtrl, validator: _dateNotPastValidator, hint: 'YYYY-MM-DD'),
            ]),
          ],
          _fieldSpacer(),
          _responsiveFields(context, [
            _field('FSSAI number', controller: _fssaiCtrl, validator: _fssaiValidator, keyboardType: TextInputType.number, maxLength: 14),
            _field('FSSAI expiry date', controller: _fssaiExpiryCtrl, validator: _dateNotPastValidator, hint: 'YYYY-MM-DD'),
          ]),
          _fieldSpacer(),
          _field('PAN number', controller: _panCtrl, validator: _panValidator, maxLength: 10),
          _fieldSpacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceWarm, border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PAN verification', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep)),
                const SizedBox(height: 8),
                _field('Name as per PAN', controller: _panNameCtrl, onChanged: (v) => setState(() => _panName = v)),
                _fieldSpacer(),
                _field('Date of birth (as per PAN)', controller: _panDobCtrl, onChanged: (v) => setState(() => _panDob = v), hint: 'YYYY-MM-DD'),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _panVerifying ? null : _verifyPan,
                    icon: const Icon(Icons.verified_user_outlined, size: 18),
                    label: Text(_panVerifying ? 'Verifying…' : 'Verify PAN'),
                  ),
                ),
                if (_panVerifyMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_panVerifyMessage!, style: TextStyle(color: _panVerifiedName != null ? Colors.green : AppColors.red, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          _fieldSpacer(),
          _field('Bank name', controller: _bankNameCtrl, validator: _required),
          _fieldSpacer(),
          _field(
            'Account type',
            child: DropdownButtonFormField<String>(
              initialValue: _accountType.isEmpty ? null : _accountType,
              decoration: _inputDecoration('Account type'),
              items: const [
                DropdownMenuItem(value: 'SAVINGS', child: Text('Savings')),
                DropdownMenuItem(value: 'CURRENT', child: Text('Current')),
              ],
              onChanged: (v) => setState(() => _accountType = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Required.' : null,
            ),
          ),
          _fieldSpacer(),
          _field('Account holder name', controller: _bankAccountHolderCtrl, validator: _required),
          _fieldSpacer(),
          _responsiveFields(context, [
            _field('Account number', controller: _bankAccountCtrl, validator: _bankAccountValidator, keyboardType: TextInputType.number, maxLength: 18),
            _field('Confirm account no.', controller: _bankAccountConfirmCtrl, validator: _confirmBankValidator, keyboardType: TextInputType.number, maxLength: 18),
            _field('IFSC code', controller: _ifscCtrl, validator: _ifscValidator, maxLength: 11),
          ], columns: 3),
          const SizedBox(height: 16),
          _sectionTitle('Document uploads'),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pickFileTile('Upload PAN card', _panFile, (f) => setState(() => _panFile = f)),
              _fieldSpacer(),
              if (_gstPresent == 'yes') ...[
                _pickFileTile('Upload GST document', _gstFile, (f) => setState(() => _gstFile = f), required: true),
                _fieldSpacer(),
              ],
              _pickFileTile('Upload FSSAI document', _fssaiFile, (f) => setState(() => _fssaiFile = f)),
              _fieldSpacer(),
              _pickFileTile('Upload Bank document', _bankFile, (f) => setState(() => _bankFile = f)),
            ],
          ),
          if (_serverError.isNotEmpty && _step == '2') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_serverError, style: TextStyle(color: AppColors.red)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _submitting ? null : () => setState(() => _step = '1'), child: const Text('Back'))),
              const SizedBox(width: 10),
              Expanded(child: _actionButton(_submitting ? 'Saving…' : 'Proceed to review', _submitting ? () {} : _submitStep2)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMenuExtractedPreview() {
    final menu = _menuExtracted;
    if (menu == null || menu.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.inputBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extracted menu', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep)),
          const SizedBox(height: 8),
          for (final cat in menu) ...[
            Text(cat.displayName.isEmpty ? cat.name : cat.displayName, style: AppText.body(size: 13, weight: FontWeight.w700)),
            for (final item in cat.items)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                child: Text('${item.name} — ₹${item.price}', style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return _buildSectionCard(
      title: 'Brand & submission',
      subtitle: 'Add your brand story, choose a payment app, and submit for review.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPricingBanner(),
          PaymentAppSelector(
            selected: _selectedPaymentApp,
            effectivePrice: _pricing?.effectivePrice,
            onChanged: (app) => setState(() => _selectedPaymentApp = app),
          ),
          const SizedBox(height: 16),
          _pickFileTile('Upload cover photo (optional)', _coverPhotoFile, (f) => setState(() => _coverPhotoFile = f), accept: 'image/*'),
          _fieldSpacer(),
          Text(
            'Menu upload is optional — you can skip it and submit.',
            style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
          ),
          const SizedBox(height: 8),
          _pickFileTile(
            'Upload menu image (optional — any PNG/JPEG)',
            _menuFile,
            (f) => setState(() {
              _menuFile = f;
              _menuExtracted = null;
              _menuScanError = '';
            }),
            accept: 'menu-image',
          ),
          if (_menuFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _menuScanning ? null : _scanMenu,
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(_menuScanning ? 'Scanning…' : 'Scan menu (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove menu',
                  onPressed: () => setState(() {
                    _menuFile = null;
                    _menuExtracted = null;
                    _menuScanError = '';
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
          if (_menuScanError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_menuScanError, style: TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          _buildMenuExtractedPreview(),
          _fieldSpacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.inputBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review snapshot', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accentDeep)),
                const SizedBox(height: 8),
                Text('Restaurant: ${_nameCtrl.text.trim().isEmpty ? 'Pending' : _nameCtrl.text.trim()}', style: AppText.body(size: 13, color: AppColors.midGrey)),
                Text('Owner: ${_ownerCtrl.text.trim().isEmpty ? 'Pending' : _ownerCtrl.text.trim()}', style: AppText.body(size: 13, color: AppColors.midGrey)),
                Text('Email: ${_emailCtrl.text.trim().isEmpty ? 'Pending' : _emailCtrl.text.trim()}', style: AppText.body(size: 13, color: AppColors.midGrey)),
                Text('Phone: ${_phoneCtrl.text.trim().isEmpty ? 'Pending' : _phoneCtrl.text.trim()}', style: AppText.body(size: 13, color: AppColors.midGrey)),
                Text('GST: ${_gstPresent == 'yes' ? 'Yes' : 'No'}', style: AppText.body(size: 13, color: AppColors.midGrey)),
                Text('Payment app: ${_selectedPaymentApp.label}', style: AppText.body(size: 13, color: AppColors.midGrey)),
              ],
            ),
          ),
          _fieldSpacer(),
          _field('Referral name', controller: _leadSourceCtrl),
          _fieldSpacer(),
          _field('Brand description', controller: _brandDescCtrl, maxLines: 3, maxLength: 500),
          _fieldSpacer(),
          _field('Cuisine tags', controller: _cuisineTagsCtrl, hint: 'Comma-separated'),
          _fieldSpacer(),
          _field('Service radius (km)', controller: _serviceRadiusCtrl, keyboardType: TextInputType.number, validator: _serviceRadiusValidator),
          _fieldSpacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                SwitchListTile(value: _temporaryClosure, onChanged: (v) => setState(() => _temporaryClosure = v), title: const Text('Temporary closure')),
                SwitchListTile(value: _holidayMode, onChanged: (v) => setState(() => _holidayMode = v), title: const Text('Holiday mode')),
              ],
            ),
          ),
          _fieldSpacer(),
          CheckboxListTile(
            value: _reviewConfirmed,
            onChanged: (v) => setState(() => _reviewConfirmed = v ?? false),
            title: const Text('I have reviewed all fields and confirm this registration is ready for submission.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          if (_serverError.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_serverError, style: TextStyle(color: AppColors.red)),
            ),
            const SizedBox(height: 12),
          ],
          if (_successMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_successMessage, style: const TextStyle(color: Colors.green)),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _submitting ? null : () => setState(() => _step = '2'), child: const Text('Back'))),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  _submitStatus == 'paying'
                      ? 'Opening ${_selectedPaymentApp.label}…'
                      : _submitting
                          ? 'Submitting…'
                          : 'Pay & submit',
                  _submitting ? () {} : _handleSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickFileTile(String label, XFile? currentFile, Function(XFile?) onPicked, {bool required = false, String accept = 'application/pdf,image/*'}) {
    Future<void> openPicker() async {
      if (accept == 'menu-image' || accept == 'image/*') {
        await _pickMenuImage(onPicked);
        return;
      }
      await _pickFile(
        onPicked,
        extensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'csv', 'xlsx', 'xls'],
        mimeTypes: const [
          'image/*',
          'image/png',
          'image/jpeg',
          'application/pdf',
          'text/csv',
        ],
        label: label,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceWarm, border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: openPicker,
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(currentFile == null ? 'Choose file' : 'Replace file'),
            ),
          ),
          if (currentFile != null) ...[
            const SizedBox(height: 8),
            Text(currentFile.name, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
          ] else if (required) ...[
            const SizedBox(height: 8),
            Text('Required for this registration step', style: TextStyle(color: AppColors.red)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accentDeep)),
      );

  Widget _buildStepDot(bool active) {
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(color: active ? AppColors.accent : AppColors.inputBorder, borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.24), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(child: Text(label, style: AppText.body(size: 15.5, weight: FontWeight.w800, color: Colors.white))),
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppText.body(size: 13, color: AppColors.bodyGrey),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.4)),
      );

  Widget _field(
    String label, {
    TextEditingController? controller,
    String? Function(String)? validator,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    String? hint,
    bool readOnly = false,
    Widget? child,
  }) {
    if (child != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      );
    }
    return TextFormField(
      controller: controller,
      validator: validator == null ? null : (v) => validator(v ?? ''),
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      readOnly: readOnly,
      style: AppText.body(size: 13.5, color: AppColors.ink),
      decoration: _inputDecoration(label, hint: hint),
      onChanged: onChanged != null ? (v) => onChanged(v) : null,
    );
  }

  String? _required(String value) => value.trim().isEmpty ? 'Required.' : null;

  String? _requiredMin2(String value) {
    if (value.trim().isEmpty) return 'Required.';
    if (value.trim().length < 2) return 'Minimum 2 characters.';
    return null;
  }

  String? _ownerValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    if (value.trim().length < 2) return 'Minimum 2 characters.';
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(value.trim())) return 'Only letters, spaces, and . \' - allowed.';
    return null;
  }

  String? _emailValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) ? null : 'Invalid email address.';
  }

  String? _phoneValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^[6-9]\d{9}$').hasMatch(value) ? null : 'Must be a valid 10-digit mobile number.';
  }

  String? _zipValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^\d{6}$').hasMatch(value) ? null : 'Must be exactly 6 digits.';
  }

  String? _gstValidator(String value) {
    if (_gstPresent != 'yes') return null;
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(value.toUpperCase()) ? null : 'Invalid GSTIN format.';
  }

  String? _fssaiValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^\d{14}$').hasMatch(value) ? null : 'Must be exactly 14 digits.';
  }

  String? _panValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(value.toUpperCase()) ? null : 'Invalid PAN format.';
  }

  String? _bankAccountValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^\d{9,18}$').hasMatch(value) ? null : 'Must be 9–18 digits.';
  }

  String? _confirmBankValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return value == _bankAccountCtrl.text.trim() ? null : 'Account numbers do not match.';
  }

  String? _ifscValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase()) ? null : 'Format: 4 letters + 0 + 6 alphanumeric.';
  }

  String? _dateNotPastValidator(String value) {
    if (value.trim().isEmpty) return 'Required.';
    final today = DateTime.now();
    final parts = value.trim().split('-');
    if (parts.length != 3) return 'Use YYYY-MM-DD format.';
    final date = DateTime.tryParse(value.trim());
    if (date == null) return 'Invalid date.';
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayDate)) return 'Expiry date cannot be in the past.';
    return null;
  }

  String? _serviceRadiusValidator(String value) {
    if (value.trim().isEmpty) return null;
    final r = double.tryParse(value.trim());
    if (r == null || r <= 0 || r > 500) return 'Must be between 0.1 and 500 km.';
    return null;
  }

  Widget _buildOtpGate() {
    final isOtp = _authPhase == 'otp';
    return _buildSectionCard(
      title: isOtp ? 'Verify email OTP' : 'Verify your email',
      subtitle: isOtp
          ? 'Enter the OTP sent to ${_emailCtrl.text.trim()} to unlock registration.'
          : 'We will send a one-time password to confirm your partner email before registration.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'Email',
            controller: _emailCtrl,
            validator: _emailValidator,
            keyboardType: TextInputType.emailAddress,
            readOnly: isOtp,
          ),
          if (isOtp) ...[
            _fieldSpacer(),
            _field(
              'OTP',
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 8,
              hint: 'Enter OTP',
            ),
          ],
          if (_serverError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_serverError, style: TextStyle(color: AppColors.red)),
            ),
          ],
          if (_successMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text(_successMessage, style: const TextStyle(color: Colors.green)),
            ),
          ],
          const SizedBox(height: 16),
          if (isOtp) ...[
            _actionButton(_otpBusy ? 'Verifying…' : 'Verify OTP', _otpBusy ? () {} : _verifyOtp),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _otpBusy
                  ? null
                  : () => setState(() {
                        _authPhase = 'email';
                        _otpCtrl.clear();
                        _serverError = '';
                        _successMessage = '';
                      }),
              child: const Text('Change email'),
            ),
            TextButton(
              onPressed: _otpBusy ? null : _requestOtp,
              child: const Text('Resend OTP'),
            ),
          ] else
            _actionButton(_otpBusy ? 'Sending OTP…' : 'Send OTP', _otpBusy ? () {} : _requestOtp),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inForm = _authPhase == 'form';
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                      child: ScreenHeader(
                        title: 'Register Restaurant',
                        onBack: () => ref.read(navigationControllerProvider).back(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Text(
                        inForm
                            ? 'Complete restaurant details. Login credentials are sent after approval.'
                            : 'Start with email OTP verification, then complete the registration form.',
                        style: AppText.body(size: 13.5, color: AppColors.bodyGrey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: _buildHeroCard()),
                    if (inForm) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            _buildStepDot(_step == '1' || _step == '2' || _step == '3'),
                            const SizedBox(width: 8),
                            _buildStepDot(_step == '2' || _step == '3'),
                            const SizedBox(width: 8),
                            _buildStepDot(_step == '3'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: !inForm
                          ? _buildOtpGate()
                          : _step == '1'
                              ? _buildStepOne()
                              : _step == '2'
                                  ? _buildStepTwo()
                                  : _buildStepThree(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
