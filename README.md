# 🚗 RentGo — Araç Kiralama Uygulaması

<p align="center">
  <img src="screenshots/login.png" width="180" alt="Giriş"/>
  &nbsp;&nbsp;
  <img src="screenshots/anasayfa.png" width="180" alt="Ana Sayfa"/>
  &nbsp;&nbsp;
  <img src="screenshots/aracdetay.png" width="180" alt="Araç Detay"/>
</p>

<p align="center">
  <b>Flutter ile geliştirilmiş modern araç kiralama kataloğu uygulaması</b><br/>
  Kullanıcılar araçları listeleyebilir, filtreleyebilir, karşılaştırabilir ve rezervasyon yapabilir.
</p>

---

## 📱 Ekran Görüntüleri

### Onboarding & Giriş

<p align="center">
  <img src="screenshots/onboarding1.png" width="180" alt="Onboarding 1"/>
  &nbsp;&nbsp;
  <img src="screenshots/onboarding2.png" width="180" alt="Onboarding 2"/>
  &nbsp;&nbsp;
  <img src="screenshots/onboarding3.png" width="180" alt="Onboarding 3"/>
  &nbsp;&nbsp;
  <img src="screenshots/login.png" width="180" alt="Giriş"/>
</p>

### Ana Sayfa & Araç Detayı

<p align="center">
  <img src="screenshots/anasayfa.png" width="180" alt="Ana Sayfa"/>
  &nbsp;&nbsp;
  <img src="screenshots/aracdetay.png" width="180" alt="Araç Detay"/>
  &nbsp;&nbsp;
  <img src="screenshots/fiyatbenzeraraclar.png" width="180" alt="Fiyat & Benzer Araçlar"/>
  &nbsp;&nbsp;
  <img src="screenshots/tarihsigorta.png" width="180" alt="Tarih & Sigorta"/>
</p>

### Favoriler, Sepet & Rezervasyon

<p align="center">
  <img src="screenshots/favoriler.png" width="180" alt="Favoriler"/>
  &nbsp;&nbsp;
  <img src="screenshots/sepet.png" width="180" alt="Sepet"/>
  &nbsp;&nbsp;
  <img src="screenshots/rezervasyon.png" width="180" alt="Rezervasyon Özeti"/>
</p>

### Araç Karşılaştırma

<p align="center">
  <img src="screenshots/arackarsilastirma.png" width="180" alt="Araç Karşılaştırma"/>
  &nbsp;&nbsp;
  <img src="screenshots/arackarsilastirmadetay.png" width="180" alt="Karşılaştırma Detay"/>
</p>

---

## ✨ Özellikler

| Özellik | Açıklama |
|---|---|
| 🔐 Kullanıcı Girişi | İsim ve soyisim ile kişiselleştirilmiş giriş |
| 🌐 Web Servis Entegrasyonu | Unsplash API'den gerçek araç fotoğrafları (HTTP GET) |
| 🗄️ Veri Modelleme | `Car.fromJson()` ile JSON → model dönüşümü |
| 💾 Yerel Cache | SharedPreferences ile araç listesi önbellekleme |
| 🚗 Araç Kataloğu | 48 araç, 5 kategori, 20+ farklı marka |
| 🔍 Akıllı Arama | Marka, model ve şehre göre anlık arama |
| 🏙️ Şehir Filtresi | İstanbul, Ankara, İzmir, Antalya, Bursa |
| 🏷️ Tip Filtresi | Sedan, SUV, Elektrikli, Spor, Minivan |
| 💰 Fiyat Filtresi | Slider ile min-max fiyat aralığı |
| 📊 Sıralama | Ucuzdan pahalıya, pahalıdan ucuza, puana göre |
| 📋 Araç Detayı | Motor, 0-100, tüketim, menzil, donanım listesi |
| 📅 Tarih Seçimi | Alış ve iade tarihi, geçmiş tarih engeli |
| 🛡️ Sigorta Seçimi | Temel sigorta veya tam kasko |
| 💳 Fiyat Hesabı | Gün × (araç + sigorta) anlık hesaplama |
| ❤️ Favoriler | Araçları favorilere ekle/çıkar |
| 🛒 Sepet | Aynı araç farklı tarih/sigorta ile birden fazla |
| ⚖️ Karşılaştırma | 2 aracı yan yana karşılaştır |
| 📄 Rezervasyon Özeti | Tamamlanan rezervasyonların detaylı özeti |
| 🌟 Kullanıcı Yorumları | Araç detayında kullanıcı değerlendirmeleri |
| 🔄 Benzer Araçlar | Aynı kategoriden öneri araçlar |

---

## 🌐 API Entegrasyonu

Bu proje web servisinden gerçek veri çekmektedir.

### Unsplash API
- **Endpoint:** `https://api.unsplash.com/search/photos`
- **Kullanım:** Her araç için marka+model bazlı fotoğraf arama
- **Yöntem:** HTTP GET isteği, `Authorization: Client-ID` header
- **Dönüşüm:** Gelen JSON verisi `Car.fromJson()` ile modele dönüştürülür

### Veri Akışı

```
Unsplash API
     │
     ▼ HTTP GET
CarService.getCars()
     │
     ▼ Car.fromJson()
List<Car>
     │
     ▼ SharedPreferences Cache
HomeScreen (GridView)
```

### Cache Mekanizması
- İlk açılışta API'den veri çekilir ve `SharedPreferences`'a kaydedilir
- Sonraki açılışlarda cache'den okunur — anında yüklenir
- Pull-to-refresh ile cache yenilenir

---

## 🎨 Teknik Özellikler

- **Hero Animasyonu** — Araç kartından detaya geçişte görsel animasyonu
- **Skeleton Loading** — İlk yüklemede shimmer animasyonlu placeholder
- **Swipe-to-Delete** — Sepette sola kaydırarak silme
- **Haptic Feedback** — Favori, sepet ve karşılaştırma işlemlerinde titreşim
- **Pull-to-Refresh** — Ana sayfada aşağı çekerek yenileme
- **Fiyat Animasyonu** — Detay sayfasında fiyat değişiminde animasyon

---

## 🛠️ Kullanılan Teknolojiler

```
Flutter 3.41.9 (stable)
Dart 3.11.5
```

| Paket | Versiyon | Kullanım |
|---|---|---|
| `http` | ^1.2.2 | Web servis HTTP istekleri |
| `shared_preferences` | ^2.3.2 | Araç listesi yerel önbellekleme |
| `cupertino_icons` | ^1.0.8 | iOS stil ikonlar |

**Mimari:**
- `StatelessWidget` / `StatefulWidget`
- `Navigator.push` / `pushReplacement` ile sayfa geçişleri
- `setState` ile state yönetimi
- Servis katmanı (`CarService`) ile UI/veri ayrımı

---

## 📁 Proje Yapısı

```
lib/
├── main.dart                           # Uygulama giriş noktası & tema
├── constants/
│   ├── app_colors.dart                 # Merkezi renk sabitleri
│   └── app_config.dart                 # Uygulama sabitleri
├── models/
│   ├── car_model.dart                  # Araç modeli (fromJson/toJson)
│   └── cart_item_model.dart            # Sepet öğesi modeli
├── services/
│   └── car_service.dart                # Unsplash API + cache yönetimi
├── screens/
│   ├── splash_screen.dart              # Açılış ekranı
│   ├── onboarding_screen.dart          # 3 sayfalık tanıtım
│   ├── login_screen.dart               # Kullanıcı giriş ekranı
│   ├── home_screen.dart                # Ana sayfa (liste, filtre, arama)
│   ├── detail_screen.dart              # Araç detay sayfası
│   ├── cart_screen.dart                # Sepet sayfası
│   ├── favorites_screen.dart           # Favoriler sayfası
│   ├── compare_screen.dart             # Araç karşılaştırma
│   └── reservation_summary_screen.dart # Rezervasyon özeti
├── utils/
│   ├── date_formatter.dart             # Tarih formatlama yardımcısı
│   └── snackbar_helper.dart            # Merkezi SnackBar yönetimi
└── widgets/
    ├── car_card.dart                   # Araç kart widget'ı
    ├── car_image.dart                  # Asset/Network görsel widget'ı
    └── skeleton_card.dart              # Yükleme animasyonu widget'ı
```

---

## 🚀 Çalıştırma Adımları

```bash
# 1. Projeyi klonla
git clone https://github.com/TalhaD-coder/Software-Persona-Mobil-Gelistirme_Flutter-Egitimi-Proje.git

# 2. Klasöre gir
cd mini_katalog

# 3. Bağımlılıkları yükle
flutter pub get

# 4. Uygulamayı çalıştır
flutter run
```

> **Not:** Android emülatör veya fiziksel Android cihaz gereklidir. İlk açılışta API'den veri çekildiği için internet bağlantısı gereklidir.

---

## 📚 Öğrenme Hedefleri

Bu proje aşağıdaki Flutter konularını kapsamaktadır:

- ✅ Widget ağacı ve Stateless/Stateful widget mantığı
- ✅ Navigator ile sayfa geçişleri ve Route Arguments
- ✅ GridView ve ListView.builder ile dinamik listeler
- ✅ **Web servisinden HTTP GET ile veri çekme**
- ✅ **Model sınıfı oluşturma ve JSON dönüşümü (fromJson)**
- ✅ **Yerel veri önbellekleme (SharedPreferences)**
- ✅ setState ile basit state yönetimi
- ✅ Material Design 3 tema ve bileşenleri
- ✅ Animasyonlar (Hero, AnimatedContainer, AnimatedSwitcher)

---

## 👨‍💻 Geliştirici

**Talha Dağ**  
Flutter Günlük Eğitim Programı — Proje Çıktısı

---

<p align="center">
  <i>Flutter ile geliştirildi 🚀</i>
</p>
