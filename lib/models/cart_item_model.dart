import '../utils/date_formatter.dart';
import '../constants/app_config.dart';

/// Sepetteki her rezervasyon için detaylı bilgi tutar.
/// Aynı araç farklı tarih/sigorta ile birden fazla kez eklenebilir.
class CartItem {
  final String id; // Benzersiz id: "carId_startDate_insurance"
  final int carId;
  final DateTime startDate;
  final DateTime endDate;
  final int days; // final — değişince copyWithDays() kullanılır
  final int dailyPrice; // Sigorta dahil günlük fiyat
  final bool hasFullInsurance;

  const CartItem({
    required this.id,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.dailyPrice,
    required this.hasFullInsurance,
  });

  /// Toplam fiyat: günlük fiyat × gün sayısı
  int get totalPrice => days * dailyPrice;

  /// Tarih aralığı: "17 May - 20 May"
  String get dateRange => DateFormatter.range(startDate, endDate);

  /// Yeni gün sayısıyla kopyasını oluşturur, bitiş tarihi otomatik güncellenir
  CartItem copyWithDays(int newDays) {
    assert(
      newDays >= AppConfig.minRentalDays && newDays <= AppConfig.maxRentalDays,
      'Gün sayısı ${AppConfig.minRentalDays}-${AppConfig.maxRentalDays} arasında olmalı',
    );
    return CartItem(
      id: id,
      carId: carId,
      startDate: startDate,
      endDate: startDate.add(Duration(days: newDays)),
      days: newDays,
      dailyPrice: dailyPrice,
      hasFullInsurance: hasFullInsurance,
    );
  }
}
