/// String formatting and manipulation extensions.
extension StringExt on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String maskPhone() {
    if (length < 10) return this;
    return '${substring(0, 2)}******${substring(length - 2)}';
  }
}
