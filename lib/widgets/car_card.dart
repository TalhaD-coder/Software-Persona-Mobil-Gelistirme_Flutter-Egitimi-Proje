import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../constants/app_colors.dart';
import 'car_image.dart';

/// Araç listesinde her araç için gösterilen kart widget'ı.
/// Stateless — tüm state dışarıdan (HomeScreen) yönetiliyor.
class CarCard extends StatelessWidget {
  final Car car;
  final bool isFavorite;
  final bool isInCart;
  final bool isComparing;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCompareTap;
  final VoidCallback onTap;

  const CarCard({
    super.key,
    required this.car,
    required this.isFavorite,
    required this.isInCart,
    required this.isComparing,
    required this.onFavoriteTap,
    required this.onCompareTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildImageSection(), _buildInfoSection()],
        ),
      ),
    );
  }

  /// Görsel + etiketler + butonlar
  Widget _buildImageSection() {
    return Stack(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Hero(
            tag: 'car_image_${car.id}',
            child: CarImage(car: car, fit: BoxFit.cover),
          ),
        ),

        // Sağ üst köşeye koyu gradient — ikonların her zaman görünmesi için
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Araç tipi etiketi (sol üst)
        Positioned(
          top: 8,
          left: 8,
          child: _badge(car.type, AppColors.forCarType(car.type)),
        ),

        // Badge etiketi (İndirimli, Yeni, Popüler)
        if (car.badge != null)
          Positioned(
            top: 8,
            right: 36,
            child: _badge(
              car.badge!,
              AppColors.forBadge(car.badge!),
              fontSize: 9,
            ),
          ),

        // "Sepette" göstergesi (sol alt)
        if (isInCart)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 10),
                  SizedBox(width: 4),
                  Text(
                    'Sepette',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Favori + Karşılaştırma butonları (sağ üst)
        Positioned(
          top: 4,
          right: 4,
          child: Column(
            children: [
              _iconButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
                bgColor: isFavorite
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.4),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onFavoriteTap();
                },
              ),
              const SizedBox(height: 4),
              _iconButton(
                icon: Icons.compare_arrows,
                color: Colors.white,
                bgColor: isComparing
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: 0.4),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCompareTap();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Araç bilgileri (isim, şehir, fiyat, puan, chip'ler)
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marka ve Model
          Text(
            car.fullName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Şehir ve Yıl
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text(
                '${car.city} · ${car.year}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fiyat ve Puan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (car.hasDiscount)
                    Text(
                      '₺${car.originalPrice}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    car.formattedPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    car.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vites ve Yakıt chip'leri
          Row(
            children: [
              _infoChip(Icons.settings, car.transmission),
              const SizedBox(width: 6),
              _infoChip(Icons.local_gas_station, car.fuel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, {double fontSize = 10}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
