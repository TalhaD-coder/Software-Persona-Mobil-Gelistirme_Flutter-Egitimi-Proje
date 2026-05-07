/// Araç veri modelini temsil eden sınıf.
/// JSON'dan Dart nesnesine ve Dart nesnesinden JSON'a dönüşüm yapabilir.
class Car {
  final int id;
  final String brand;
  final String model;
  final int year;
  final int pricePerDay;
  final String type;
  final String fuel;
  final String transmission;
  final int seats;
  final double rating;
  final String image;
  final List<String> features;
  final String city;
  final String? badge;
  final int? originalPrice;
  final bool isAsset; // true → Image.asset, false → Image.network

  // Teknik veriler
  final String engine; // Motor: "2.0L Turbo 184 HP"
  final String zeroToHundred; // 0-100: "7.1 sn"
  final String fuelConsumption; // Tüketim: "6.8 L/100km"
  final String range; // Menzil: "620 km"

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.pricePerDay,
    required this.type,
    required this.fuel,
    required this.transmission,
    required this.seats,
    required this.rating,
    required this.image,
    required this.features,
    required this.city,
    this.badge,
    this.originalPrice,
    this.isAsset = false,
    this.engine = '',
    this.zeroToHundred = '',
    this.fuelConsumption = '',
    this.range = '',
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      pricePerDay: json['pricePerDay'] as int,
      type: json['type'] as String,
      fuel: json['fuel'] as String,
      transmission: json['transmission'] as String,
      seats: json['seats'] as int,
      rating: (json['rating'] as num).toDouble(),
      image: json['image'] as String,
      features: List<String>.from(json['features'] as List),
      city: json['city'] as String,
      badge: json['badge'] as String?,
      originalPrice: json['originalPrice'] as int?,
      engine: json['engine'] as String? ?? '',
      zeroToHundred: json['zeroToHundred'] as String? ?? '',
      fuelConsumption: json['fuelConsumption'] as String? ?? '',
      range: json['range'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'pricePerDay': pricePerDay,
      'type': type,
      'fuel': fuel,
      'transmission': transmission,
      'seats': seats,
      'rating': rating,
      'image': image,
      'features': features,
      'city': city,
      'badge': badge,
      'originalPrice': originalPrice,
      'engine': engine,
      'zeroToHundred': zeroToHundred,
      'fuelConsumption': fuelConsumption,
      'range': range,
    };
  }

  String get fullName => '$brand $model';
  String get formattedPrice => '₺$pricePerDay / gün';
  bool get hasDiscount => originalPrice != null && originalPrice! > pricePerDay;
}
