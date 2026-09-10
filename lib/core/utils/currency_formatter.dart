abstract final class CurrencyFormatter {
  static String rupiah(int amount) {
    final String digits = amount.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final String sign = amount < 0 ? '-' : '';
    return '${sign}Rp$buffer';
  }

  static int parseRupiah(String text) {
    final String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 0;
    }
    return int.parse(digitsOnly);
  }
}
