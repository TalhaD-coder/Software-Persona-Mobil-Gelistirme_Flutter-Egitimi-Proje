/// Uygulama genelinde kullanılan sabit değerler
class AppConfig {
  AppConfig._();

  // Kiralama limitleri
  static const int minRentalDays = 1;
  static const int maxRentalDays = 30;

  // Fiyat filtresi
  static const double minPrice = 0;
  static const double maxPrice = 20000;
  static const int priceSliderDivisions = 40;

  // Sigorta fiyatı
  static const int fullInsurancePrice = 500;

  // Animasyon süreleri (ms)
  static const int splashDuration = 2000;
  static const int skeletonDuration = 800;
  static const int hintAnimationDelay = 600;
  static const int priceAnimationDuration = 300;
}
