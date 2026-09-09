// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'लाइवरेस्ट्रो सेल्स';

  @override
  String get welcomeMessage => 'लाइवरेस्ट्रो सेल्स में आपका स्वागत है';

  @override
  String get loginTitle => 'कार्यकारी लॉगिन';

  @override
  String get loginSubtitle =>
      'अपने बिक्री पोर्टल तक पहुँचने के लिए अपने क्रेडेंशियल दर्ज करें';

  @override
  String get phonePlaceholder => 'फ़ोन नंबर';

  @override
  String get passwordPlaceholder => 'पासवर्ड';

  @override
  String get submit => 'सबमिट करें';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get otpTitle => 'ओटीपी सत्यापित करें';

  @override
  String get otpSubtitle => 'अपने फ़ोन पर भेजा गया 6-अंकीय कोड दर्ज करें';

  @override
  String get createPinTitle => 'सुरक्षा पिन बनाएं';

  @override
  String get createPinSubtitle => 'त्वरित पहुँच के लिए 4-अंकीय पिन सेट करें';

  @override
  String get dashboardTitle => 'सेल्स डैशबोर्ड';

  @override
  String get recentVisits => 'हाल के रेस्तरां दौरे';

  @override
  String get salesTarget => 'मासिक लक्ष्य';

  @override
  String get ordersCount => 'कुल ऑर्डर';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get language => 'भाषा';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get networkError => 'नेटवर्क त्रुटि, कृपया अपना कनेक्शन जांचें।';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';
}
