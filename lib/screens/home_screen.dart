import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../models/cart_item_model.dart';
import '../data/mock_data.dart';
import '../widgets/car_card.dart';
import '../widgets/skeleton_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import 'detail_screen.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'compare_screen.dart';

// HomeScreen → Ana sayfa
// Stateful çünkü: arama, filtre, favori, sepet state'leri burada yönetiliyor
class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tüm araçlar
  final List<Car> _allCars = MockData.getCars();
  bool _isLoading = true; // İlk yükleme skeleton için

  // Favori araç id'leri
  final Set<int> _favoriteIds = {};

  // Sepet: benzersiz id → CartItem (aynı araç farklı tarihlerle birden fazla olabilir)
  final Map<String, CartItem> _cartItems = {};

  // Toplam sepet ürün sayısı (badge için)
  int get _cartCount => _cartItems.length;

  // Seçili şehir filtresi
  String _selectedCity = 'Tümü';

  // Seçili araç tipi filtresi
  String _selectedType = 'Tümü';

  // Sıralama
  String _sortBy = 'Varsayılan';

  // Fiyat filtresi
  RangeValues _priceRange = const RangeValues(
    AppConfig.minPrice,
    AppConfig.maxPrice,
  );

  // Karşılaştırma için seçili araçlar
  final Set<int> _compareIds = {};

  // Arama metni
  String _searchQuery = '';

  // Arama controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kısa bir gecikme ile skeleton'dan gerçek listeye geç
    Future.delayed(
      const Duration(milliseconds: AppConfig.skeletonDuration),
      () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrelenmiş araç listesi — şehir + tip + arama + fiyat + sıralama
  List<Car> get _filteredCars {
    var list = _allCars.where((car) {
      final matchesCity = _selectedCity == 'Tümü' || car.city == _selectedCity;
      final matchesType = _selectedType == 'Tümü' || car.type == _selectedType;
      final matchesSearch =
          _searchQuery.isEmpty ||
          car.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.city.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPrice =
          car.pricePerDay >= _priceRange.start &&
          car.pricePerDay <= _priceRange.end;
      return matchesCity && matchesType && matchesSearch && matchesPrice;
    }).toList();

    // Sıralama
    if (_sortBy == 'Ucuzdan Pahalıya') {
      list.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (_sortBy == 'Pahalıdan Ucuza') {
      list.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    } else if (_sortBy == 'Puana Göre') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  bool get _isPriceFiltered =>
      _priceRange != const RangeValues(AppConfig.minPrice, AppConfig.maxPrice);

  // Bu araç sepette var mı?
  bool _isInCart(int carId) =>
      _cartItems.values.any((item) => item.carId == carId);

  // Favori toggle
  void _toggleFavorite(int carId) {
    setState(() {
      if (_favoriteIds.contains(carId)) {
        _favoriteIds.remove(carId);
      } else {
        _favoriteIds.add(carId);
      }
    });
  }

  // Sepete araç ekle — detay sayfasından CartItem gelir
  void _addToCart(CartItem item) {
    setState(() {
      _cartItems[item.id] = item; // Aynı id varsa üzerine yazar (günceller)
    });
  }

  /// Karşılaştırma toggle — aynı araç iki kez eklenemez
  void _toggleCompare(int carId) {
    setState(() {
      if (_compareIds.contains(carId)) {
        _compareIds.remove(carId);
      } else if (_compareIds.length < 2) {
        _compareIds.add(carId);
      } else {
        // 2 araç doluysa en eskiyi çıkar, yenisini ekle
        _compareIds.remove(_compareIds.first);
        _compareIds.add(carId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // --- APP BAR ---
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text('RentGo'),
          ],
        ),
        // Sol üstte hoşgeldin mesajı
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoşgeldin,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10,
                ),
              ),
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        leadingWidth: 120,
        actions: [
          // Favoriler ikonu
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(
                    allCars: _allCars,
                    favoriteIds: _favoriteIds,
                    onFavoriteTap: _toggleFavorite,
                    onAddToCart: _addToCart,
                    compareIds: _compareIds,
                    onCompareTap: _toggleCompare,
                  ),
                ),
              ).then((_) => setState(() {})); // Dönünce banner güncelle
            },
          ),

          // Sepet ikonu + badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        allCars: _allCars,
                        cartItems: _cartItems,
                        onAddToCart: _addToCart,
                        compareIds: _compareIds,
                        onCompareTap: _toggleCompare,
                        favoriteIds: _favoriteIds,
                        onFavoriteTap: _toggleFavorite,
                        onUpdateCart: (itemId, days) {
                          setState(() {
                            if (days == 0) {
                              _cartItems.remove(itemId);
                            } else {
                              final old = _cartItems[itemId];
                              if (old != null) {
                                _cartItems[itemId] = old.copyWithDays(days);
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ).then((_) => setState(() {})); // Geri dönünce badge güncelle
                },
              ),
              // Badge — sepette ürün varsa göster
              if (_cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ÜST BÖLÜM: Arama + Filtreler ---
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Marka, model veya şehir ara...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Şehir seçimi dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: MockData.cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_city,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(city, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCity = value!);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- ARAÇ TİPİ FİLTRE CHİP'LERİ ---
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: MockData.carTypes.length,
              itemBuilder: (context, index) {
                final type = MockData.carTypes[index];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- KARŞILAŞTIRMA BANNER ---
          if (_compareIds.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _compareIds.length == 1
                          ? '1 araç seçildi — 1 araç daha seç'
                          : '2 araç hazır!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_compareIds.length == 2)
                    ElevatedButton(
                      onPressed: () {
                        final cars = _allCars
                            .where((c) => _compareIds.contains(c.id))
                            .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompareScreen(car1: cars[0], car2: cars[1]),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Karşılaştır'),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _compareIds.clear()),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

          // --- SONUÇ SAYISI + SIRALAMA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredCars.length} araç bulundu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    // Fiyat filtresi butonu
                    GestureDetector(
                      onTap: _showPriceFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _isPriceFiltered
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune,
                              size: 14,
                              color: _isPriceFiltered
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fiyat',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isPriceFiltered
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        icon: const Icon(Icons.sort, size: 18),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        items:
                            [
                                  'Varsayılan',
                                  'Ucuzdan Pahalıya',
                                  'Pahalıdan Ucuza',
                                  'Puana Göre',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _sortBy = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- ARAÇ LİSTESİ (GridView) ---
          Expanded(
            child: _isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const SkeletonCard(),
                  )
                : _filteredCars.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await Future.delayed(const Duration(milliseconds: 800));
                      setState(() {}); // Listeyi yenile
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio:
                                0.65, // Daha uzun kart — overflow önlenir
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredCars.length,
                      itemBuilder: (context, index) {
                        final car = _filteredCars[index];
                        return CarCard(
                          car: car,
                          isFavorite: _favoriteIds.contains(car.id),
                          isInCart: _isInCart(car.id),
                          isComparing: _compareIds.contains(car.id),
                          onFavoriteTap: () => _toggleFavorite(car.id),
                          onCompareTap: () => _toggleCompare(car.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  car: car,
                                  isFavorite: _favoriteIds.contains(car.id),
                                  onFavoriteTap: () => _toggleFavorite(car.id),
                                  onAddToCart: _addToCart,
                                  allCars: _allCars,
                                  compareIds: _compareIds,
                                  onCompareTap: _toggleCompare,
                                ),
                              ),
                            ).then(
                              (_) => setState(() {}),
                            ); // Dönünce banner güncelle
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Fiyat filtresi bottom sheet
  void _showPriceFilter() {
    RangeValues tempRange = _priceRange;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fiyat Aralığı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${tempRange.start.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₺${tempRange.end.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: AppConfig.minPrice,
                    max: AppConfig.maxPrice,
                    divisions: AppConfig.priceSliderDivisions,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => tempRange = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(
                              () => _priceRange = const RangeValues(
                                AppConfig.minPrice,
                                AppConfig.maxPrice,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Sıfırla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _priceRange = tempRange);
                            Navigator.pop(context);
                          },
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Sonuç bulunamadığında gösterilecek widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Araç bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir filtre veya arama deneyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

