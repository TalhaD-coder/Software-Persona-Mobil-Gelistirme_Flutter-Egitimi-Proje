import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../constants/app_colors.dart';
import '../widgets/car_image.dart';

// CompareScreen → 2 aracı yan yana karşılaştırma ekranı
class CompareScreen extends StatelessWidget {
  final Car car1;
  final Car car2;

  const CompareScreen({super.key, required this.car1, required this.car2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Araç Karşılaştırma')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Araç görselleri
            Row(
              children: [
                Expanded(child: _carHeader(car1)),
                const SizedBox(width: 12),
                Expanded(child: _carHeader(car2)),
              ],
            ),
            const SizedBox(height: 16),

            // Karşılaştırma tablosu
            _compareSection(
              'Fiyat',
              '₺${car1.pricePerDay}/gün',
              '₺${car2.pricePerDay}/gün',
              highlight: car1.pricePerDay < car2.pricePerDay
                  ? 1
                  : (car2.pricePerDay < car1.pricePerDay ? 2 : 0),
            ),
            _compareSection(
              'Puan',
              car1.rating.toString(),
              car2.rating.toString(),
              highlight: car1.rating > car2.rating
                  ? 1
                  : (car2.rating > car1.rating ? 2 : 0),
            ),
            _compareSection('Yakıt', car1.fuel, car2.fuel),
            _compareSection('Vites', car1.transmission, car2.transmission),
            _compareSection(
              'Koltuk',
              '${car1.seats} kişi',
              '${car2.seats} kişi',
            ),
            _compareSection(
              'Yıl',
              '${car1.year}',
              '${car2.year}',
              highlight: car1.year > car2.year
                  ? 1
                  : (car2.year > car1.year ? 2 : 0),
            ),
            _compareSection('Şehir', car1.city, car2.city),
            _compareSection('Tip', car1.type, car2.type),

            const SizedBox(height: 16),

            // Donanım karşılaştırması
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donanım Karşılaştırması',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _featureList(car1)),
                      const SizedBox(width: 12),
                      Expanded(child: _featureList(car2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carHeader(Car car) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: CarImage(car: car, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            car.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareSection(
    String label,
    String val1,
    String val2, {
    int highlight = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _valueCell(val1, highlight == 1)),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(child: _valueCell(val2, highlight == 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueCell(String value, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green[50] : null,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isWinner)
            const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
          if (isWinner) const SizedBox(width: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: isWinner ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList(Car car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: car.features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
