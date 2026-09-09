import '../../../../shared/domain/entities/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  otpVerified,
  totpRequired,
  pinRequired,
  authenticated,
  lockedOut,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? userId;
  final String? phone;
  final String? countryCode;
  final String? errorMessage;
  final int failedPinAttempts;
  final bool isLockedOut;
  final bool rememberDevice;
  final String? lastGeneratedOtp;
  final DateTime? otpSentAt;
  final String? totpSecret;
  final String? totpQrUrl;
  final bool isTotpEnrolled;
  final bool hasPin;
  final bool isPinResetApproved;
  final String? nextStep;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.userId,
    this.phone,
    this.countryCode = '+91',
    this.errorMessage,
    this.failedPinAttempts = 0,
    this.isLockedOut = false,
    this.rememberDevice = true,
    this.lastGeneratedOtp,
    this.otpSentAt,
    this.totpSecret,
    this.totpQrUrl,
    this.isTotpEnrolled = false,
    this.hasPin = false,
    this.isPinResetApproved = false,
    this.nextStep,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? userId,
    String? phone,
    String? countryCode,
    String? errorMessage,
    int? failedPinAttempts,
    bool? isLockedOut,
    bool? rememberDevice,
    String? lastGeneratedOtp,
    DateTime? otpSentAt,
    String? totpSecret,
    String? totpQrUrl,
    bool? isTotpEnrolled,
    bool? hasPin,
    bool? isPinResetApproved,
    String? nextStep,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      errorMessage: errorMessage,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      rememberDevice: rememberDevice ?? this.rememberDevice,
      lastGeneratedOtp: lastGeneratedOtp ?? this.lastGeneratedOtp,
      otpSentAt: otpSentAt ?? this.otpSentAt,
      totpSecret: totpSecret ?? this.totpSecret,
      totpQrUrl: totpQrUrl ?? this.totpQrUrl,
      isTotpEnrolled: isTotpEnrolled ?? this.isTotpEnrolled,
      hasPin: hasPin ?? this.hasPin,
      isPinResetApproved: isPinResetApproved ?? this.isPinResetApproved,
      nextStep: nextStep ?? this.nextStep,
    );
  }
}

