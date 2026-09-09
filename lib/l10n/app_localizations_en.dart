// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LiveRestro Sales';

  @override
  String get welcomeMessage => 'Welcome to LiveRestro Sales';

  @override
  String get loginTitle => 'Executive Login';

  @override
  String get loginSubtitle =>
      'Enter your credentials to access your sales portal';

  @override
  String get phonePlaceholder => 'Phone Number';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get submit => 'Submit';

  @override
  String get continueButton => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String get otpSubtitle => 'Enter the 6-digit code sent to your phone';

  @override
  String get createPinTitle => 'Create Security PIN';

  @override
  String get createPinSubtitle => 'Set a 4-digit PIN for quick access';

  @override
  String get dashboardTitle => 'Sales Dashboard';

  @override
  String get recentVisits => 'Recent Restaurant Visits';

  @override
  String get salesTarget => 'Monthly Target';

  @override
  String get ordersCount => 'Total Orders';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get retry => 'Retry';

  @override
  String get networkError => 'Network error, please check your connection.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';
}
