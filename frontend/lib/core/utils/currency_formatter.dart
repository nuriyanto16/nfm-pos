import 'package:intl/intl.dart';

final _rupiahFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Format angka menjadi format Rupiah: Rp 35.000
String formatRupiah(num amount) {
  return _rupiahFormatter.format(amount);
}

/// Format angka menjadi format Rupiah singkat tanpa spasi: Rp35.000
String formatRupiahCompact(num amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(amount);
}
