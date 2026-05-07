import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../models/cart_item_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../utils/date_formatter.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/car_image.dart';

// DetailScreen → Araç detay sayfası
class DetailScreen extends StatefulWidget {
  final Car car;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final Function(CartItem) onAddToCart;
  final List<Car> allCars;
  final Set<int> compareIds; // Karşılaştırma state'i
  final Function(int) onCompareTap; // Karşılaştırmaya ekle/çıkar

  const DetailScreen({
    super.key,
    required this.car,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onAddToCart,
    this.allCars = const [],
    this.compareIds = const {},
    required this.onCompareTap,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _fullInsurance = false;
  bool _addedToCart = false;
  late bool _isFav;
  late bool _isComparing; // Karşılaştırmada mı?
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _isComparing = widget.compareIds.contains(widget.car.id);
    // Varsayılan: yarın başla, 1 gün
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _endDate = _startDate.add(const Duration(days: 1));
  }

  // Kaç gün seçildi
  int get _days => _endDate.difference(_startDate).inDays;

  /// Sigorta fiyatı — AppConfig'den alınır
  int get _insurancePrice => _fullInsurance ? AppConfig.fullInsurancePrice : 0;

  // Günlük fiyat (sigorta dahil)
  int get _dailyPrice => widget.car.pricePerDay + _insurancePrice;

  // Toplam fiyat
  int get _totalPrice => _dailyPrice * _days;

  /// Araç tipine göre renk — AppColors'dan alınır
  Color _getTypeColor(String type) => AppColors.forCarType(type);

  /// Tarih formatı — DateFormatter'dan alınır
  String _formatDate(DateTime date) => DateFormatter.full(date);

  // Başlangıç tarihi seçici
  Future<void> _pickStartDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Bitiş tarihi başlangıçtan önceye düştüyse düzelt
        if (_endDate.isBefore(_startDate.add(const Duration(days: 1)))) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
        _addedToCart = false;
      });
    }
  }

  // Bitiş tarihi seçici
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)), // En az 1 gün
      lastDate: _startDate.add(const Duration(days: AppConfig.maxRentalDays)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _addedToCart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- BÜYÜK ARAÇ GÖRSELİ ---
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            // Geri butonu — koyu daire içinde
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            actions: [
              // Favori butonu — koyu daire içinde
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onFavoriteTap();
                    setState(() => _isFav = !_isFav);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isFav
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _isFav ? Icons.favorite : Icons.favorite_border,
                      color: _isFav ? Colors.red : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'car_image_${widget.car.id}',
                    child: CarImage(
                      car: widget.car,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppColors.primary,
                        child: const Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Alt gradient — araç tipi etiketi için
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Üst gradient — geri ok ve favori butonu için
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Araç tipi etiketi — renkli
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(widget.car.type),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.car.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ARAÇ ADI + PUAN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.car.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.car.city} · ${widget.car.year}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.car.rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- TEKNİK ÖZELLİKLER ---
                  const Text(
                    'Teknik Özellikler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _specCard(
                          Icons.settings,
                          'Vites',
                          widget.car.transmission,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _specCard(
                          Icons.local_gas_station,
                          'Yakıt',
                          widget.car.fuel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _specCard(
                          Icons.people,
                          'Koltuk',
                          '${widget.car.seats} Kişi',
                        ),
                      ),
                    ],
                  ),

                  // Motor, 0-100, tüketim, menzil
                  if (widget.car.engine.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _specCard(
                            Icons.speed,
                            '0-100',
                            widget.car.zeroToHundred,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _specCard(
                            Icons.water_drop_outlined,
                            'Tüketim',
                            widget.car.fuelConsumption,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _specCard(
                            Icons.route,
                            'Menzil',
                            widget.car.range,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.engineering,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.car.engine,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- DONANIM ---
                  const Text(
                    'Donanım',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.car.features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A237E,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF1A237E,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // --- KULLANICI YORUMLARI ---
                  const Text(
                    'Kullanıcı Yorumları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _reviewCard(
                    'Ahmet Y.',
                    5,
                    'Harika bir araç! Çok temiz ve bakımlıydı. Kesinlikle tekrar kiralayacağım.',
                    '2 gün önce',
                  ),
                  const SizedBox(height: 8),
                  _reviewCard(
                    'Selin K.',
                    4,
                    'Genel olarak memnun kaldım. Teslim süreci çok hızlıydı.',
                    '1 hafta önce',
                  ),
                  const SizedBox(height: 8),
                  _reviewCard(
                    'Murat D.',
                    5,
                    'Fiyat/performans açısından mükemmel. Tavsiye ederim.',
                    '2 hafta önce',
                  ),

                  const SizedBox(height: 20),

                  // --- SİGORTA SEÇİMİ ---
                  const Text(
                    'Sigorta Seçimi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _insuranceOption(
                    title: 'Temel Sigorta',
                    subtitle: 'Zorunlu trafik sigortası dahil',
                    price: 'Ücretsiz',
                    isSelected: !_fullInsurance,
                    onTap: () => setState(() {
                      _fullInsurance = false;
                      _addedToCart = false;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _insuranceOption(
                    title: 'Tam Kasko',
                    subtitle: 'Her türlü hasar güvencesi',
                    price: '+₺500/gün',
                    isSelected: _fullInsurance,
                    onTap: () => setState(() {
                      _fullInsurance = true;
                      _addedToCart = false;
                    }),
                  ),

                  const SizedBox(height: 20),

                  // --- TARİH SEÇİMİ ---
                  const Text(
                    'Kiralama Tarihleri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Başlangıç tarihi
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartDate,
                          child: _dateCard(
                            label: 'Alış Tarihi',
                            date: _formatDate(_startDate),
                            icon: Icons.flight_takeoff,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bitiş tarihi
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndDate,
                          child: _dateCard(
                            label: 'İade Tarihi',
                            date: _formatDate(_endDate),
                            icon: Icons.flight_land,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Gün sayısı bilgisi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_days gün kiralama',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TOPLAM FİYAT ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Araç Ücreti/Gün',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₺${widget.car.pricePerDay}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (_fullInsurance) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tam Kasko/Gün',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                '+₺500',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Süre',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$_days gün',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Toplam Tutar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // AnimatedSwitcher — fiyat değişince yukarı kayarak güncellenir
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.5),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                '₺$_totalPrice',
                                key: ValueKey(_totalPrice),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- KARŞILAŞTIRMA BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        widget.onCompareTap(widget.car.id);
                        setState(() => _isComparing = !_isComparing);
                        SnackBarHelper.showInfo(
                          context,
                          _isComparing
                              ? '${widget.car.fullName} karşılaştırmaya eklendi'
                              : '${widget.car.fullName} karşılaştırmadan çıkarıldı',
                        );
                      },
                      icon: Icon(
                        _isComparing ? Icons.compare_arrows : Icons.add,
                        color: _isComparing
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                      label: Text(
                        _isComparing
                            ? 'Karşılaştırmada ✓'
                            : 'Karşılaştırmaya Ekle',
                        style: TextStyle(
                          color: _isComparing
                              ? AppColors.accent
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isComparing
                              ? AppColors.accent
                              : AppColors.primary,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- SEPETE EKLE BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addedToCart
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              final itemId =
                                  '${widget.car.id}_${_startDate.toIso8601String()}_${_fullInsurance ? 'kasko' : 'temel'}';
                              final item = CartItem(
                                id: itemId,
                                carId: widget.car.id,
                                startDate: _startDate,
                                endDate: _endDate,
                                days: _days,
                                dailyPrice: _dailyPrice,
                                hasFullInsurance: _fullInsurance,
                              );
                              widget.onAddToCart(item);
                              setState(() => _addedToCart = true);
                              SnackBarHelper.showSuccess(
                                context,
                                '${widget.car.fullName} sepete eklendi!',
                              );
                            },
                      icon: Icon(
                        _addedToCart ? Icons.check : Icons.shopping_cart,
                      ),
                      label: Text(
                        _addedToCart ? 'Sepete Eklendi' : 'Sepete Ekle',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _addedToCart
                            ? Colors.grey
                            : AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- BENZERİ ARAÇLAR ---
                  if (widget.allCars.isNotEmpty) ...[
                    const Text(
                      'Benzer Araçlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: widget.allCars
                            .where(
                              (c) =>
                                  c.id != widget.car.id &&
                                  c.type == widget.car.type,
                            )
                            .take(5)
                            .map((c) => _similarCarCard(c))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Benzer araç kartı
  Widget _similarCarCard(Car car) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              car: car,
              isFavorite: false,
              onFavoriteTap: () {},
              onAddToCart: widget.onAddToCart,
              allCars: widget.allCars,
              compareIds: widget.compareIds,
              onCompareTap: widget.onCompareTap,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: CarImage(car: car, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    car.formattedPrice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        car.rating.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
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

  // Kullanıcı yorum kartı
  Widget _reviewCard(String name, int stars, String comment, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(
                      0xFF1A237E,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Tarih kartı
  Widget _dateCard({
    required String label,
    required String date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Değiştir',
            style: TextStyle(fontSize: 11, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  // Teknik özellik kartı
  Widget _specCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  // Sigorta seçenek kartı
  Widget _insuranceOption({
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.accent : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

