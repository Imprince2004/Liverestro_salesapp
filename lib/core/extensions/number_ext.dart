import 'package:intl/intl.dart';

/// Number and Currency formatting extensions.
extension NumberExt on num {
  String toCurrency({String symbol = '₹', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(this);
  }

  String toDistance() {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)} km';
    }
    return '${toStringAsFixed(0)} m';
  }
}
