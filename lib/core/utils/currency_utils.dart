import 'package:intl/intl.dart';

/// Enterprise Currency & Monetary Utilities.
class CurrencyUtils {
  CurrencyUtils._();

  static String formatINR(num amount, {bool showSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: showSymbol ? '₹' : '',
      decimalDigits: amount is int || amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount).trim();
  }

  static String formatCompact(num amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: symbol,
    );
    return formatter.format(amount);
  }
}
