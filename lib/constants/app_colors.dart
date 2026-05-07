import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan renk sabitleri
/// Tüm renk referansları buradan alınmalı
class AppColors {
  AppColors._(); // instantiate edilemesin

  // Ana renkler
  static const Color primary = Color(0xFF1A237E); // Lacivert
  static const Color primaryLight = Color(0xFF3949AB); // Açık lacivert
  static const Color primaryDark = Color(0xFF0D1333); // Koyu lacivert
  static const Color accent = Color(0xFFFF6F00); // Turuncu

  // Arka plan
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // Araç tipi renkleri
  static const Color typeSedan = primary;
  static Color typeSuv = Colors.blue[700]!;
  static Color typeElectric = Colors.green[700]!;
  static Color typeSport = Colors.red[700]!;
  static Color typeMinivan = Colors.purple[700]!;

  // Badge renkleri
  static Color badgeDiscount = Colors.red[600]!;
  static Color badgeNew = Colors.teal[600]!;
  static Color badgePopular = Colors.orange[700]!;

  // Durum renkleri
  static Color success = Colors.green[700]!;
  static Color error = Colors.red[700]!;
  static Color warning = Colors.orange[700]!;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Araç tipine göre renk döndürür
  static Color forCarType(String type) {
    switch (type) {
      case 'Elektrikli':
        return typeElectric;
      case 'Spor':
        return typeSport;
      case 'SUV':
        return typeSuv;
      case 'Minivan':
        return typeMinivan;
      default:
        return typeSedan;
    }
  }

  // Badge tipine göre renk döndürür
  static Color forBadge(String badge) {
    switch (badge) {
      case 'İndirimli':
        return badgeDiscount;
      case 'Yeni':
        return badgeNew;
      case 'Popüler':
        return badgePopular;
      default:
        return textSecondary;
    }
  }
}
