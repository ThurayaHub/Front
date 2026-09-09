import 'package:flutter/material.dart';

abstract final class ChooseRestaurantArabicLabels {
  static const Map<String, String> _priceLabels = {
    'cheap': 'اقتصادي',
    'medium': 'متوسط',
    'expensive': 'مرتفع',
    'very expensive': 'فاخر',
  };

  static const Map<String, String> _priceSymbols = {
    'cheap': r'$',
    'medium': r'$$',
    'expensive': r'$$$',
    'very expensive': r'$$$$',
  };

  static const Map<String, String> _categoryLabels = {
    'chinese': 'صيني',
    'asian': 'آسيوي',
    'saudi': 'سعودي',
    'gulf': 'خليجي',
    'american': 'أمريكي',
    'italian': 'إيطالي',
    'indian': 'هندي',
    'japanese': 'ياباني',
    'other': 'أخرى',
    'cafe': 'مقهى',
  };

  static String priceName(String backendName) {
    return _priceLabels[_key(backendName)] ?? 'غير محدد';
  }

  static String priceSymbol(String backendName) {
    return _priceSymbols[_key(backendName)] ?? r'$';
  }

  static String categoryName(String backendName) {
    return _categoryLabels[_key(backendName)] ?? 'أخرى';
  }

  static IconData categoryIcon(String backendName) {
    return switch (_key(backendName)) {
      'chinese' => Icons.ramen_dining_rounded,
      'asian' => Icons.rice_bowl_rounded,
      'saudi' => Icons.restaurant_rounded,
      'gulf' => Icons.dinner_dining_rounded,
      'american' => Icons.lunch_dining_rounded,
      'italian' => Icons.local_pizza_rounded,
      'indian' => Icons.restaurant_menu_rounded,
      'japanese' => Icons.set_meal_rounded,
      'cafe' => Icons.local_cafe_rounded,
      _ => Icons.flatware_rounded,
    };
  }

  static String _key(String value) => value.trim().toLowerCase();
}
