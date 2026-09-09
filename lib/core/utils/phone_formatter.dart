/// Phone formatting and parsing utility.
class PhoneFormatter {
  PhoneFormatter._();

  static String sanitize(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static String formatIndianPhone(String phone) {
    final clean = sanitize(phone);
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return phone;
  }
}
