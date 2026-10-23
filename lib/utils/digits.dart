import 'package:flutter/services.dart';

const _eastern = '٠١٢٣٤٥٦٧٨٩';
const _persian = '۰۱۲۳۴۵۶۷۸۹';

/// «٣٢٣» / «۳۲۳» → «323». An Arabic keyboard types Eastern digits, which
/// `int.tryParse` and `FilteringTextInputFormatter.digitsOnly` both reject.
String latinDigits(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = _eastern.indexOf(c);
    final j = i >= 0 ? i : _persian.indexOf(c);
    b.write(j >= 0 ? '$j' : c);
  }
  return b.toString();
}

/// A whole number typed with any digit set, or null.
int? parseAnyDigits(String s) {
  final w = latinDigits(s.trim());
  return RegExp(r'^\d+$').hasMatch(w) ? int.parse(w) : null;
}

/// Keeps digits of any set, stored as Latin, so the field and the parser
/// agree whatever keyboard the user has.
class AnyDigitsFormatter extends TextInputFormatter {
  const AnyDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = latinDigits(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (t == newValue.text) return newValue;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
