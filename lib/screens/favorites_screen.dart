import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../models/cart_item_model.dart';
import '../constants/app_colors.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/car_image.dart';
import 'detail_screen.dart';

// FavoritesScreen → Favoriye eklenen araçların listelendiği sayfa
// Stateful çünkü favori kaldırma işlemi anlık güncelleme gerektiriyor
class FavoritesScreen extends StatefulWidget {
  final List<Car> allCars;
  final Set<int> favoriteIds;
  final Function(int) onFavoriteTap;
  final Function(CartItem) onAddToCart;
  final Set<int> compareIds;
  final Function(int) onCompareTap;

  const FavoritesScreen({
    super.key,
    required this.allCars,
    required this.favoriteIds,
    required this.onFavoriteTap,
    required this.onAddToCart,
    required this.compareIds,
    required this.onCompareTap,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Favori araçları getir
  List<Car> get _favoriteCars {
    return widget.allCars
        .where((car) => widget.favoriteIds.contains(car.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorilerim'),
        actions: [
          // Favori sayısı badge
          if (_favoriteCars.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_favoriteCars.length} araç',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: _favoriteCars.isEmpty
          ? _buildEmptyFavorites()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteCars.length,
              itemBuilder: (context, index) {
                final car = _favoriteCars[index];
                return _buildFavoriteItem(car);
              },
            ),
    );
  }

  // Favori araç kartı
  Widget _buildFavoriteItem(Car car) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              car: car,
              isFavorite: widget.favoriteIds.contains(car.id),
              onFavoriteTap: () {
                widget.onFavoriteTap(car.id);
                setState(() {});
              },
              onAddToCart: widget.onAddToCart,
              allCars: widget.allCars,
              compareIds: widget.compareIds,
              onCompareTap: widget.onCompareTap,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Araç görseli
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 90,
                child: CarImage(car: car, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(width: 12),

            // Araç bilgileri
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Araç adı
                    Text(
                      car.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Şehir ve yıl
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${car.city} · ${car.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Fiyat ve puan
                    Row(
                      children: [
                        Text(
                          car.formattedPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Colors.amber,
                        ),
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

                    const SizedBox(height: 6),

                    // Araç tipi chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forCarType(
                          car.type,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        car.type,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.forCarType(car.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sağ taraf butonları — karşılaştır + favori kaldır
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Karşılaştırma butonu
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCompareTap(car.id);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.compareIds.contains(car.id)
                          ? AppColors.primary
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.compare_arrows,
                      size: 18,
                      color: widget.compareIds.contains(car.id)
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Favori kaldır butonu
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () {
                      widget.onFavoriteTap(car.id);
                      setState(() {});
                      SnackBarHelper.showInfo(
                        context,
                        '${car.fullName} favorilerden kaldırıldı',
                      );
                    },
                    icon: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Boş favoriler ekranı
  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Henüz favori eklemediniz',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Araç kartındaki kalp ikonuna basarak\nfavorilerinize ekleyebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('Araçlara Göz At'),
          ),
        ],
      ),
    );
  }
}


