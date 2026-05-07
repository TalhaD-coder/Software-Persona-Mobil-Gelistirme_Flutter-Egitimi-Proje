import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../models/cart_item_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../utils/date_formatter.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/car_image.dart';
import 'detail_screen.dart';
import 'reservation_summary_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Car> allCars;
  final Map<String, CartItem> cartItems;
  final Function(String itemId, int days) onUpdateCart;
  final Function(CartItem) onAddToCart;
  final Set<int> compareIds;
  final Function(int) onCompareTap;
  final Set<int> favoriteIds; // Favori state'i
  final Function(int) onFavoriteTap; // Favori toggle

  const CartScreen({
    super.key,
    required this.allCars,
    required this.cartItems,
    required this.onUpdateCart,
    required this.onAddToCart,
    required this.compareIds,
    required this.onCompareTap,
    required this.favoriteIds,
    required this.onFavoriteTap,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _hintController;
  late Animation<Offset> _hintAnimation;
  bool _hintShown = false;

  List<MapEntry<String, CartItem>> get _cartEntries =>
      widget.cartItems.entries.toList();

  Car _carById(int carId) => widget.allCars.firstWhere(
    (c) => c.id == carId,
    orElse: () => widget.allCars.first,
  );

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _hintAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.1, 0)).animate(
          CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
        );

    // İlk açılışta ilk karta swipe hint göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hintShown && widget.cartItems.isNotEmpty) {
        _hintShown = true;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _hintController.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) _hintController.reverse();
              });
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  int get _totalPrice {
    int total = 0;
    for (final item in widget.cartItems.values) {
      total += item.totalPrice;
    }
    return total;
  }

  void _removeFromCart(String itemId) {
    widget.onUpdateCart(itemId, 0);
    setState(() {}); // Local rebuild için
  }

  void _updateDays(String itemId, int days) {
    widget.onUpdateCart(itemId, days);
    setState(() {}); // Local rebuild için
  }

  String _formatDate(DateTime date) => DateFormatter.short(date);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sepetim${_cartEntries.isNotEmpty ? ' (${_cartEntries.length})' : ''}',
        ),
        actions: [
          if (_cartEntries.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Sepeti Temizle'),
                  content: const Text('Tüm rezervasyonlar kaldırılsın mı?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        for (final e in _cartEntries.toList()) {
                          widget.onUpdateCart(e.key, 0);
                        }
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Temizle',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              child: const Text(
                'Temizle',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),

      body: _cartEntries.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _cartEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _cartEntries[index];
                      final item = entry.value;
                      final car = _carById(item.carId);
                      // Sadece ilk karta hint animasyonu uygula
                      final widget_ = _buildCartItem(car, item, entry.key);
                      if (index == 0) {
                        return SlideTransition(
                          position: _hintAnimation,
                          child: widget_,
                        );
                      }
                      return widget_;
                    },
                  ),
                ),
                _buildSummary(),
              ],
            ),
    );
  }

  Widget _buildCartItem(Car car, CartItem item, String itemId) {
    final days = item.days;

    return Dismissible(
      key: Key(itemId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        _removeFromCart(itemId);
        SnackBarHelper.showError(
          context,
          '${car.fullName} sepetten kaldırıldı',
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
        child: Column(
          children: [
            // Üst kısım — tıklanınca detaya git
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                      compareIds: widget.compareIds,
                      onCompareTap: widget.onCompareTap,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Araç görseli
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 95,
                        height: 72,
                        child: CarImage(car: car, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Araç adı + detay oku
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  car.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${car.city} · ${car.type} · ${car.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Tarih + sigorta yan yana
                          Row(
                            children: [
                              // Tarih
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Sigorta
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: item.hasFullInsurance
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.hasFullInsurance
                                        ? AppColors.success.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  item.hasFullInsurance
                                      ? '✓ Tam Kasko'
                                      : 'Temel',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.hasFullInsurance
                                        ? AppColors.success
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alt kısım — gün seçici + fiyat + sil
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  // Gün seçici
                  _dayButton(
                    icon: Icons.remove,
                    onTap: days > AppConfig.minRentalDays
                        ? () => _updateDays(itemId, days - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          '$days gün',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_formatDate(item.startDate)} - ${_formatDate(item.startDate.add(Duration(days: days)))}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _dayButton(
                    icon: Icons.add,
                    onTap: days < AppConfig.maxRentalDays
                        ? () => _updateDays(itemId, days + 1)
                        : null,
                  ),

                  const Spacer(),

                  // Fiyat
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${item.totalPrice}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '₺${item.dailyPrice}/gün',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),

                  // Sil butonu
                  IconButton(
                    onPressed: () => _removeFromCart(itemId),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.grey[400],
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Özet satırları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_cartEntries.length} rezervasyon',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                '₺$_totalPrice',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Tutar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₺$_totalPrice',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showReservationSuccess,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('Rezervasyonu Tamamla'),
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationSuccess() {
    final reservations = _cartEntries
        .map((e) => MapEntry(_carById(e.value.carId), e.value))
        .toList();
    final total = _totalPrice;
    for (final e in _cartEntries.toList()) {
      widget.onUpdateCart(e.key, 0);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationSummaryScreen(
          reservations: reservations,
          totalPrice: total,
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sepetiniz boş',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Araç detayından sepete ekleyebilirsiniz',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
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

