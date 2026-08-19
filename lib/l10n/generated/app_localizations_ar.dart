// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ثريا';

  @override
  String get back => 'رجوع';

  @override
  String get trendingTitle => 'الترند الآن';

  @override
  String get trendingDescription =>
      'اكتشف الوجهات الأكثر رواجاً في المدينة هذه اللحظة.';

  @override
  String get activeNow => 'نشط الآن';

  @override
  String get trendingRestaurantOneName => 'إيليا للغوص';

  @override
  String get trendingRestaurantOneDetails => 'مأكولات بحرية • العليا';

  @override
  String get trendingRestaurantTwoName => 'محمصة الأصول';

  @override
  String get trendingRestaurantTwoDetails => 'مقهى مختص • الملقا';

  @override
  String get trendingRestaurantThreeName => 'لوكوموتيف';

  @override
  String get trendingRestaurantThreeDetails => 'حلويات فاخرة • السليمانية';

  @override
  String get restaurantOneCategory => 'مأكولات بحرية';

  @override
  String get restaurantOneNeighborhood => 'العليا';

  @override
  String get restaurantOneDescription =>
      'يقدم إيليا للغوص تجربة مأكولات بحرية استثنائية تمزج بين النكهات العالمية العصرية واللمسات البحرية الكلاسيكية. يتميز بأجواء فاخرة وخدمة راقية تلبي تطلعات الذواقة الباحثين عن التفرد.';

  @override
  String get restaurantTwoCategory => 'مقهى مختص';

  @override
  String get restaurantTwoNeighborhood => 'الملقا';

  @override
  String get restaurantTwoDescription =>
      'تقدم محمصة الأصول تجربة قهوة مختصة تهتم بأدق التفاصيل، من اختيار المحاصيل وتحميصها إلى تقديمها في أجواء هادئة وعصرية تناسب عشاق القهوة.';

  @override
  String get restaurantThreeCategory => 'حلويات فاخرة';

  @override
  String get restaurantThreeNeighborhood => 'السليمانية';

  @override
  String get restaurantThreeDescription =>
      'يقدم لوكوموتيف تشكيلة مبتكرة من الحلويات الفاخرة المحضرة بعناية، مع نكهات متوازنة وتقديم أنيق في أجواء دافئة تناسب اللقاءات المميزة.';

  @override
  String get saveRestaurant => 'حفظ المطعم';

  @override
  String get thurayaStar => 'نجمة ثريا';

  @override
  String get thurayaStarDescription => 'حائز على نجمة التميز للإبداع الطهوي';

  @override
  String userReviewCount(int count) {
    return '$count تقييم مستخدم';
  }

  @override
  String get call => 'اتصال';

  @override
  String get directions => 'الاتجاهات';

  @override
  String get share => 'مشاركة';

  @override
  String get aboutRestaurant => 'نبذة عن المطعم';

  @override
  String get photos => 'الصور';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get reviewsTitle => 'التقييمات';

  @override
  String get openRestaurantReviews => 'عرض تقييمات المستخدمين';

  @override
  String ratingCount(int count) {
    return '$count تقييم';
  }

  @override
  String get noReviewsYet => 'لا توجد تقييمات حتى الآن';

  @override
  String get searchRestaurant => 'ابحث عن مطعم...';

  @override
  String get filterRestaurants => 'تصفية المطاعم';

  @override
  String get currentLocation => 'موقعي الحالي';

  @override
  String get locatingCurrentLocation => 'جارٍ تحديد موقعك الحالي';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الوصول إلى الموقع';

  @override
  String get locationPermissionPermanentlyDenied =>
      'تم حظر الوصول إلى الموقع. يمكنك تفعيله من الإعدادات.';

  @override
  String get locationServicesDisabled => 'خدمات الموقع غير مفعلة';

  @override
  String get locationUnavailable => 'تعذر تحديد موقعك حالياً. حاول مرة أخرى.';

  @override
  String get restaurantMarkersUnavailable =>
      'تعذر تحميل المطاعم على الخريطة حالياً';

  @override
  String get loadingRestaurantDetails => 'جارٍ تحميل بيانات المطعم...';

  @override
  String get restaurantDetailsUnavailable => 'تعذر تحميل بيانات المطعم حالياً';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String serviceAvailableInRegion(String region) {
    return 'الخدمة متاحة حالياً داخل $region فقط';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get homeRestaurantName => 'نوزومي';

  @override
  String get homeRestaurantCategory => 'مأكولات يابانية عصرية';

  @override
  String get homeRestaurantNeighborhood => 'العليا';

  @override
  String get homeRestaurantDescription =>
      'يقدم نوزومي تجربة يابانية عصرية راقية تجمع بين الأطباق الأنيقة والنكهات المتوازنة والخدمة المميزة في أجواء فاخرة.';

  @override
  String minutesAway(int count) {
    return '$count د';
  }

  @override
  String get search => 'البحث';

  @override
  String get trending => 'الترند';

  @override
  String get wheel => 'العجلة';

  @override
  String get wheelHeroTitle => 'محتار؟ خلها علينا';

  @override
  String get wheelHeroSubtitle => 'لف العجلة وجرب حظك';

  @override
  String get addWheelOption => 'أضف خياراً';

  @override
  String get enterWheelOption => 'أدخل اسم خيار';

  @override
  String get duplicateWheelOption => 'هذا الخيار موجود بالفعل';

  @override
  String get minimumWheelOptions => 'أضف خيارين على الأقل';

  @override
  String get spinWheel => 'لف العجلة';

  @override
  String get yourWheelChoice => 'اختيارك هو';

  @override
  String get wheelOptionBurger => 'برجر';

  @override
  String get wheelOptionPizza => 'بيتزا';

  @override
  String get wheelOptionSushi => 'سوشي';

  @override
  String get wheelOptionCoffee => 'قهوة';

  @override
  String get chooseRestaurant => 'اختر لي مطعم';

  @override
  String get account => 'حسابي';

  @override
  String get home => 'الرئيسية';
}
