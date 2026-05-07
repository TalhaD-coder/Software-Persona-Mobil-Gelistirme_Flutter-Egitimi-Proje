/// Tarih formatlama yardımcı sınıfı
/// Tüm tarih formatlamaları buradan yapılmalı
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// "17 May 2026" formatı
  static String full(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// "17 May" formatı (yıl olmadan)
  static String short(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  /// "17 May - 20 May" formatı (aralık)
  static String range(DateTime start, DateTime end) {
    return '${short(start)} - ${short(end)}';
  }
}
