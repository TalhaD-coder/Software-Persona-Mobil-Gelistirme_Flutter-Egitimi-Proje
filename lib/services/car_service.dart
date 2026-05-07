import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car_model.dart';

/// Araç verisi servisi.
///
/// Veri kaynakları:
/// 1. NHTSA vPIC API — araç marka/model verisi (ücretsiz, key gerektirmez)
///    https://vpic.nhtsa.dot.gov/api/
/// 2. Unsplash API — araç fotoğrafları (ücretsiz)
///    https://api.unsplash.com/search/photos
///
/// Cache: SharedPreferences ile yerel cache — ilk açılışta API çağrısı yapılır,
/// sonraki açılışlarda cache'den okunur (anında yüklenir).
/// JSON → Car.fromJson() dönüşümü bu sınıfta gerçekleşir.
class CarService {
  static const String _unsplashBaseUrl = 'https://api.unsplash.com';
  static const String _unsplashKey =
      'n9cZcF8NwNR9wQPYkcqvbSzQXDD07w74VCXbKm9Qkz0';
  static const String _cacheKey = 'rentgo_cars_cache';

  static const List<String> _cities = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Antalya',
    'Bursa',
  ];

  /// Kategori bazlı araç listesi — her kategoride çeşitli markalar
  /// type: Sedan | SUV | Elektrikli | Spor | Minivan
  static const List<Map<String, String>> _carDefinitions = [
    // ── SEDAN ──────────────────────────────────────────────
    {'make': 'BMW', 'model': '3 Series', 'type': 'Sedan'},
    {'make': 'BMW', 'model': '5 Series', 'type': 'Sedan'},
    {'make': 'Mercedes-Benz', 'model': 'C-Class', 'type': 'Sedan'},
    {'make': 'Mercedes-Benz', 'model': 'E-Class', 'type': 'Sedan'},
    {'make': 'Audi', 'model': 'A4', 'type': 'Sedan'},
    {'make': 'Audi', 'model': 'A6', 'type': 'Sedan'},
    {'make': 'Volvo', 'model': 'S60', 'type': 'Sedan'},
    {'make': 'Jaguar', 'model': 'XE', 'type': 'Sedan'},
    {'make': 'Honda', 'model': 'Accord', 'type': 'Sedan'},
    {'make': 'Toyota', 'model': 'Camry', 'type': 'Sedan'},
    // ── SUV ────────────────────────────────────────────────
    {'make': 'BMW', 'model': 'X5', 'type': 'SUV'},
    {'make': 'Mercedes-Benz', 'model': 'GLE', 'type': 'SUV'},
    {'make': 'Audi', 'model': 'Q7', 'type': 'SUV'},
    {'make': 'Toyota', 'model': 'RAV4', 'type': 'SUV'},
    {'make': 'Volkswagen', 'model': 'Tiguan', 'type': 'SUV'},
    {'make': 'Hyundai', 'model': 'Tucson', 'type': 'SUV'},
    {'make': 'Kia', 'model': 'Sportage', 'type': 'SUV'},
    {'make': 'Jeep', 'model': 'Grand Cherokee', 'type': 'SUV'},
    {'make': 'Porsche', 'model': 'Macan', 'type': 'SUV'},
    {'make': 'Range Rover', 'model': 'Sport', 'type': 'SUV'},
    // ── ELEKTRİKLİ ─────────────────────────────────────────
    {'make': 'Tesla', 'model': 'Model 3', 'type': 'Elektrikli'},
    {'make': 'Tesla', 'model': 'Model Y', 'type': 'Elektrikli'},
    {'make': 'Tesla', 'model': 'Model S', 'type': 'Elektrikli'},
    {'make': 'BMW', 'model': 'i4', 'type': 'Elektrikli'},
    {'make': 'Audi', 'model': 'e-tron', 'type': 'Elektrikli'},
    {'make': 'Mercedes-Benz', 'model': 'EQS', 'type': 'Elektrikli'},
    {'make': 'Hyundai', 'model': 'IONIQ 6', 'type': 'Elektrikli'},
    {'make': 'Kia', 'model': 'EV6', 'type': 'Elektrikli'},
    {'make': 'Volkswagen', 'model': 'ID.4', 'type': 'Elektrikli'},
    {'make': 'Polestar', 'model': 'Polestar 2', 'type': 'Elektrikli'},
    // ── SPOR ───────────────────────────────────────────────
    {'make': 'Porsche', 'model': '911', 'type': 'Spor'},
    {'make': 'Ferrari', 'model': 'Roma', 'type': 'Spor'},
    {'make': 'Lamborghini', 'model': 'Huracan', 'type': 'Spor'},
    {'make': 'BMW', 'model': 'M4', 'type': 'Spor'},
    {'make': 'Mercedes-Benz', 'model': 'AMG GT', 'type': 'Spor'},
    {'make': 'Audi', 'model': 'R8', 'type': 'Spor'},
    {'make': 'Jaguar', 'model': 'F-Type', 'type': 'Spor'},
    {'make': 'Mazda', 'model': 'MX-5', 'type': 'Spor'},
    {'make': 'Ford', 'model': 'Mustang', 'type': 'Spor'},
    {'make': 'Bentley', 'model': 'Continental GT', 'type': 'Spor'},
    // ── MİNİVAN ────────────────────────────────────────────
    {'make': 'Mercedes-Benz', 'model': 'V-Class', 'type': 'Minivan'},
    {'make': 'Volkswagen', 'model': 'Multivan', 'type': 'Minivan'},
    {'make': 'Toyota', 'model': 'Sienna', 'type': 'Minivan'},
    {'make': 'Kia', 'model': 'Carnival', 'type': 'Minivan'},
    {'make': 'Ford', 'model': 'Tourneo', 'type': 'Minivan'},
    {'make': 'Peugeot', 'model': 'Traveller', 'type': 'Minivan'},
    {'make': 'Honda', 'model': 'Odyssey', 'type': 'Minivan'},
    {'make': 'Chrysler', 'model': 'Pacifica', 'type': 'Minivan'},
  ];

  // ── Teknik veriler ──────────────────────────────────────────────────────────

  static const Map<String, String> _fuelMap = {
    'Tesla': 'Elektrik',
    'Polestar': 'Elektrik',
    'Toyota': 'Hibrit',
    'Hyundai': 'Hibrit',
    'Volvo': 'Hibrit',
    'Volkswagen': 'Dizel',
    'Peugeot': 'Dizel',
    'BMW': 'Benzin',
    'Mercedes-Benz': 'Benzin',
    'Audi': 'Benzin',
    'Porsche': 'Benzin',
    'Ferrari': 'Benzin',
    'Lamborghini': 'Benzin',
    'Jaguar': 'Benzin',
    'Ford': 'Benzin',
    'Honda': 'Benzin',
    'Kia': 'Benzin',
    'Jeep': 'Benzin',
    'Range Rover': 'Dizel',
    'Mazda': 'Benzin',
    'Bentley': 'Benzin',
    'Chrysler': 'Benzin',
  };

  static const Map<String, String> _engineMap = {
    'BMW': '2.0L TwinPower Turbo 184 HP',
    'Mercedes-Benz': '2.0L EQ Boost 204 HP',
    'Audi': '2.0L TFSI 150 HP',
    'Toyota': '2.5L Hybrid 222 HP',
    'Tesla': 'Çift Motor AWD 358 HP',
    'Polestar': 'Çift Motor AWD 408 HP',
    'Porsche': '3.0L Twin-Turbo 450 HP',
    'Ferrari': '3.9L V8 Twin-Turbo 620 HP',
    'Lamborghini': '5.2L V10 610 HP',
    'Volkswagen': '2.0L TDI 150 HP',
    'Ford': '2.3L EcoBoost 280 HP',
    'Honda': '1.5L VTEC Turbo 192 HP',
    'Hyundai': '1.6L T-GDI 230 HP',
    'Kia': '1.6L T-GDI 150 HP',
    'Volvo': '2.0L T6 PHEV 340 HP',
    'Jaguar': '2.0L Turbo 300 HP',
    'Jeep': '3.6L V6 286 HP',
    'Range Rover': '3.0L SDV6 249 HP',
    'Mazda': '2.0L SKYACTIV-G 184 HP',
    'Bentley': '4.0L V8 Twin-Turbo 550 HP',
    'Peugeot': '2.0L BlueHDi 180 HP',
    'Chrysler': '3.6L Pentastar V6 287 HP',
  };

  static const Map<String, int> _priceMap = {
    'Ferrari': 18000,
    'Lamborghini': 22000,
    'Bentley': 14000,
    'Porsche': 9500,
    'Range Rover': 7500,
    'Tesla': 4200,
    'Mercedes-Benz': 3800,
    'BMW': 3200,
    'Audi': 2800,
    'Jaguar': 3500,
    'Volvo': 2900,
    'Polestar': 3600,
    'Toyota': 2200,
    'Volkswagen': 1900,
    'Hyundai': 1800,
    'Kia': 1700,
    'Ford': 2000,
    'Honda': 1600,
    'Jeep': 4200,
    'Mazda': 2200,
    'Peugeot': 2400,
    'Chrysler': 2600,
  };

  static const Map<String, double> _ratingMap = {
    'Ferrari': 5.0,
    'Lamborghini': 5.0,
    'Porsche': 4.9,
    'Mercedes-Benz': 4.9,
    'BMW': 4.8,
    'Tesla': 4.8,
    'Bentley': 4.9,
    'Audi': 4.7,
    'Range Rover': 4.9,
    'Volvo': 4.6,
    'Jaguar': 4.6,
    'Polestar': 4.7,
    'Toyota': 4.7,
    'Volkswagen': 4.5,
    'Hyundai': 4.4,
    'Kia': 4.4,
    'Ford': 4.5,
    'Honda': 4.3,
    'Jeep': 4.5,
    'Mazda': 4.7,
    'Peugeot': 4.3,
    'Chrysler': 4.2,
  };

  static const Map<String, String> _zeroMap = {
    'Ferrari': '3.4 sn',
    'Lamborghini': '3.3 sn',
    'Bentley': '4.0 sn',
    'Porsche': '3.5 sn',
    'Tesla': '4.4 sn',
    'Polestar': '4.7 sn',
    'BMW': '7.1 sn',
    'Mercedes-Benz': '7.3 sn',
    'Audi': '8.5 sn',
    'Jaguar': '5.7 sn',
    'Volvo': '5.5 sn',
    'Range Rover': '7.1 sn',
    'Toyota': '8.1 sn',
    'Volkswagen': '9.0 sn',
    'Hyundai': '8.2 sn',
    'Kia': '9.5 sn',
    'Ford': '6.5 sn',
    'Honda': '8.0 sn',
    'Jeep': '7.9 sn',
    'Mazda': '6.5 sn',
    'Peugeot': '10.5 sn',
    'Chrysler': '8.5 sn',
  };

  static const Map<String, String> _consumptionMap = {
    'Ferrari': '11.0 L/100km',
    'Lamborghini': '13.7 L/100km',
    'Bentley': '12.5 L/100km',
    'Porsche': '10.4 L/100km',
    'BMW': '6.8 L/100km',
    'Mercedes-Benz': '7.1 L/100km',
    'Audi': '5.2 L/100km',
    'Jaguar': '7.8 L/100km',
    'Volvo': '1.8 L/100km',
    'Range Rover': '8.4 L/100km',
    'Toyota': '4.7 L/100km',
    'Volkswagen': '5.8 L/100km',
    'Hyundai': '5.5 L/100km',
    'Kia': '7.2 L/100km',
    'Ford': '8.5 L/100km',
    'Honda': '6.2 L/100km',
    'Jeep': '11.2 L/100km',
    'Mazda': '7.7 L/100km',
    'Peugeot': '6.8 L/100km',
    'Chrysler': '9.5 L/100km',
  };

  static const Map<String, String> _rangeMap = {
    'Tesla': '602 km',
    'Polestar': '540 km',
    'BMW': '620 km',
    'Mercedes-Benz': '600 km',
    'Audi': '900 km',
    'Toyota': '900 km',
    'Volkswagen': '850 km',
    'Hyundai': '800 km',
    'Kia': '650 km',
    'Volvo': '700 km',
    'Range Rover': '750 km',
    'Porsche': '480 km',
    'Ferrari': '450 km',
    'Lamborghini': '380 km',
    'Bentley': '480 km',
    'Jaguar': '560 km',
    'Ford': '420 km',
    'Honda': '680 km',
    'Jeep': '550 km',
    'Mazda': '520 km',
    'Peugeot': '850 km',
    'Chrysler': '600 km',
  };

  // ── Ana metodlar ────────────────────────────────────────────────────────────

  /// Cache'den araçları yükler. Cache yoksa API'den çeker ve cache'e kaydeder.
  static Future<List<Car>> getCars() async {
    // 1. Cache'e bak
    final cached = await _loadFromCache();
    if (cached != null && cached.isNotEmpty) return cached;

    // 2. Cache yoksa API'den çek
    final cars = await _fetchFromApi();

    // 3. Cache'e kaydet
    if (cars.isNotEmpty) await _saveToCache(cars);

    return cars;
  }

  /// Cache'i temizler — bir sonraki açılışta API'den yeniden çeker
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  // ── Cache işlemleri ─────────────────────────────────────────────────────────

  static Future<List<Car>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToCache(List<Car> cars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(cars.map((c) => c.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
    } catch (_) {
      // Cache kaydedilemezse sessizce geç
    }
  }

  // ── API çağrıları ───────────────────────────────────────────────────────────

  /// Tüm araçları API'den çeker.
  /// Her araç için NHTSA model doğrulaması + Unsplash fotoğrafı.
  static Future<List<Car>> _fetchFromApi() async {
    final List<Car> cars = [];

    for (int i = 0; i < _carDefinitions.length; i++) {
      final def = _carDefinitions[i];
      final make = def['make']!;
      final model = def['model']!;
      final type = def['type']!;

      try {
        // Unsplash'tan fotoğraf çek
        final imageUrl = await _fetchCarImage(make, model);

        // Car.fromJson() ile dönüştür
        final car = Car.fromJson(
          _buildCarJson(
            id: i + 1,
            make: make,
            model: model,
            type: type,
            imageUrl: imageUrl,
          ),
        );

        cars.add(car);
      } catch (_) {
        // Bu araç başarısız olursa fotoğrafsız ekle
        final car = Car.fromJson(
          _buildCarJson(
            id: i + 1,
            make: make,
            model: model,
            type: type,
            imageUrl: '',
          ),
        );
        cars.add(car);
      }
    }

    return cars;
  }

  /// Unsplash'tan araç fotoğrafı çeker.
  /// Önce "BMW 3 Series" dener, bulamazsa "BMW car" dener.
  static Future<String> _fetchCarImage(String make, String model) async {
    String? url = await _searchUnsplash('$make $model');
    url ??= await _searchUnsplash('$make car');
    return url ?? '';
  }

  /// Unsplash'ta arama yapar, ilk sonucun regular URL'ini döner
  static Future<String?> _searchUnsplash(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          '$_unsplashBaseUrl/search/photos?query=$encodedQuery&per_page=1&orientation=landscape';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Client-ID $_unsplashKey'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          final urls = first['urls'] as Map<String, dynamic>;
          return urls['regular'] as String?;
        }
      }
    } catch (_) {
      // Sessizce geç
    }
    return null;
  }

  // ── JSON builder ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _buildCarJson({
    required int id,
    required String make,
    required String model,
    required String type,
    required String imageUrl,
  }) {
    final fuel = _fuelMap[make] ?? 'Benzin';
    // Elektrikli tipindeki araçlar için yakıt override
    final effectiveFuel = type == 'Elektrikli' ? 'Elektrik' : fuel;
    final price = _priceMap[make] ?? 2000;
    final rating = _ratingMap[make] ?? 4.3;
    final engine = _engineMap[make] ?? '2.0L Turbo';
    final consumption = type == 'Elektrikli'
        ? '0 L/100km'
        : (_consumptionMap[make] ?? '7.0 L/100km');
    final range = _rangeMap[make] ?? '600 km';
    final seats = type == 'Spor' ? 2 : (type == 'Minivan' ? 7 : 5);

    return {
      'id': id,
      'brand': make,
      'model': model,
      'year': 2023,
      'pricePerDay': price,
      'type': type,
      'fuel': effectiveFuel,
      'transmission': 'Otomatik',
      'seats': seats,
      'rating': rating,
      'image': imageUrl,
      'features': _featuresForType(type, effectiveFuel),
      'city': _cities[id % _cities.length],
      'badge': _badgeForMake(make),
      'originalPrice': null,
      'isAsset': false,
      'engine': engine,
      'zeroToHundred': _zeroMap[make] ?? '8.0 sn',
      'fuelConsumption': consumption,
      'range': range,
    };
  }

  static List<String> _featuresForType(String type, String fuel) {
    final base = <String>['Klima', 'Bluetooth', 'GPS', 'Geri Görüş Kamerası'];
    if (fuel == 'Elektrik') base.addAll(['Hızlı Şarj', 'Otopilot']);
    if (fuel == 'Hibrit') base.add('Eco Mode');
    if (type == 'SUV') base.addAll(['AWD', 'Şerit Takip']);
    if (type == 'Spor') base.addAll(['Spor Egzoz', 'Deri Koltuk']);
    if (type == 'Sedan') base.add('Isıtmalı Koltuk');
    if (type == 'Minivan') base.addAll(['7+ Koltuk', 'Geniş Bagaj']);
    return base;
  }

  static String? _badgeForMake(String make) {
    const popular = {
      'Ferrari',
      'Lamborghini',
      'Porsche',
      'Tesla',
      'BMW',
      'Range Rover',
    };
    const newBadge = {'Hyundai', 'Kia', 'Polestar', 'Volvo'};
    if (popular.contains(make)) return 'Popüler';
    if (newBadge.contains(make)) return 'Yeni';
    return null;
  }
}
