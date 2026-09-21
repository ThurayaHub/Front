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
  String get trendingTitle => 'الترند';

  @override
  String get trendingDescription => 'المطاعم الأكثر رواجاً';

  @override
  String get trendingEmpty => 'لا توجد مطاعم في الترند حالياً';

  @override
  String get trendingLoadError => 'تعذر تحميل مطاعم الترند حالياً';

  @override
  String trendingRankLabel(int rank) {
    return 'المرتبة $rank';
  }

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
  String get thurayaRatingLabel => 'تقييم ثريا';

  @override
  String get thurayaReviewLabel => 'رأي ثريا';

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
  String get directionsUnavailable => 'تعذر فتح الاتجاهات حالياً.';

  @override
  String get shareUnavailable => 'تعذرت مشاركة المطعم حالياً.';

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
  String get loadingReviews => 'جارٍ تحميل التقييمات...';

  @override
  String get reviewsLoadError => 'تعذر تحميل التقييمات.';

  @override
  String get searchRestaurant => 'ابحث عن مطعم...';

  @override
  String get closeSearch => 'إغلاق البحث';

  @override
  String get filterRestaurants => 'تصفية المطاعم';

  @override
  String get searchFiltersTitle => 'بحث وفلاتر';

  @override
  String get priceFilter => 'السعر';

  @override
  String get categoryFilter => 'التصنيف';

  @override
  String get ratingFilter => 'تقييم المستخدمين';

  @override
  String get minimumRatingHint => 'الحد الأدنى للتقييم';

  @override
  String get hasThurayaRatingFilter => 'بتقييم ثريا';

  @override
  String get showResults => 'عرض النتائج';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get mapView => 'الخريطة';

  @override
  String get listView => 'القائمة';

  @override
  String restaurantResultsCount(int count) {
    return '$count مطعم';
  }

  @override
  String get noSearchResultsTitle => 'ما لقينا مطاعم تطابق بحثك';

  @override
  String get noSearchResultsSubtitle => 'جرّب تغيير البحث أو إزالة بعض الفلاتر';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get searchResultsError => 'تعذر تحميل نتائج البحث';

  @override
  String get filterOptionsError => 'تعذر تحميل خيارات الفلاتر';

  @override
  String get activeFilters => 'الفلاتر النشطة';

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
  String get wheelEmptyState => 'أضف خياراتك وابدأ اللف';

  @override
  String get removeWheelOption => 'إزالة الخيار';

  @override
  String get wheelNetworkError => 'تعذر الاتصال بالعجلة حالياً. حاول مرة أخرى.';

  @override
  String get wheelBadRequestError =>
      'تعذر إكمال طلب العجلة. تحقق من الخيارات وحاول مرة أخرى.';

  @override
  String get wheelForbiddenError =>
      'ليس لديك صلاحية للوصول إلى جلسة العجلة هذه.';

  @override
  String get wheelNotFoundError =>
      'جلسة العجلة هذه لم تعد متاحة. حاول مرة أخرى.';

  @override
  String get wheelInvalidResponseError =>
      'أعادت العجلة نتيجة غير متوقعة. حاول مرة أخرى.';

  @override
  String get chooseRestaurant => 'اختر لي مطعم';

  @override
  String get chooseRestaurantNavigation => 'اختر لي';

  @override
  String get account => 'حسابي';

  @override
  String get home => 'الرئيسية';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get authenticationWelcome => 'مرحباً بك في ثريا';

  @override
  String get loginSubtitle =>
      'أدخل رقم جوالك للمتابعة إلى مزايا ثريا التي تتطلب حساباً.';

  @override
  String get phoneNumber => 'رقم الجوال';

  @override
  String get phoneNumberHint => '05XXXXXXXX';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get registrationTitle => 'إكمال التسجيل';

  @override
  String get registrationSubtitle =>
      'هذا الرقم غير مسجل. أكمل بياناتك لإنشاء حساب ثريا.';

  @override
  String get fullName => 'الاسم';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get changePhoneNumber => 'تغيير رقم الجوال';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get invalidSaudiPhone =>
      'أدخل رقم جوال سعودي صحيحاً من 10 أرقام يبدأ بـ 05';

  @override
  String get invalidNameCharacters =>
      'يقبل الاسم الحروف العربية أو الإنجليزية والمسافات فقط';

  @override
  String get invalidEmailCharacters =>
      'البريد الإلكتروني يحتوي على أحرف غير صالحة';

  @override
  String get emailAlreadyInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String maximumLengthExceeded(int maxLength) {
    return 'الحد الأقصى $maxLength حرفاً';
  }

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get authenticationUnavailable =>
      'تعذر إكمال تسجيل الدخول حالياً. حاول مرة أخرى.';

  @override
  String get accountGuestTitle => 'مرحباً بك في ثريا';

  @override
  String get accountGuestSubtitle =>
      'سجّل الدخول لاستخدام المفضلة والمزايا الخاصة بحسابك.';

  @override
  String accountWelcome(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get accountAuthenticatedSubtitle =>
      'جلستك محفوظة بأمان ويمكنك استخدام مزايا ثريا المحمية.';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get loggingOut => 'جارٍ تسجيل الخروج...';

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get favoriteUpdateUnavailable =>
      'تعذر تحديث المفضلة حالياً. حاول مرة أخرى.';

  @override
  String get profileDetailsTitle => 'بياناتي';

  @override
  String get myFavorites => 'مفضلاتي';

  @override
  String get myReviews => 'مراجعاتي';

  @override
  String get emailVerified => 'البريد الإلكتروني موثق';

  @override
  String get emailUnverified => 'البريد الإلكتروني غير موثق';

  @override
  String reviewsWritten(int count) {
    return '$count مراجعة';
  }

  @override
  String get profileDetailsSubtitle => 'معلومات حسابك في ثريا';

  @override
  String get favoritesSubtitle => 'المطاعم اللي حفظتها للرجوع لها بسهولة';

  @override
  String get myReviewsSubtitle => 'آراؤك وتجاربك مع المطاعم';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get phoneLabel => 'رقم الجوال';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailVerificationLabel => 'حالة توثيق البريد';

  @override
  String get notAdded => 'غير مضاف';

  @override
  String memberSince(int year) {
    return 'عضو منذ $year';
  }

  @override
  String get profileLoadError => 'تعذر تحميل البيانات';

  @override
  String get favoritesEmptyTitle => 'ما عندك مطاعم مفضلة للحين';

  @override
  String get favoritesEmptySubtitle => 'أضف المطاعم اللي تعجبك وبتلقاها هنا';

  @override
  String get reviewsEmptyTitle => 'ما كتبت أي مراجعة للحين';

  @override
  String get reviewsEmptySubtitle => 'جرّب مطعم وشاركنا رأيك';

  @override
  String get exploreRestaurants => 'استكشف المطاعم';

  @override
  String get removeFavorite => 'إزالة من المفضلة';

  @override
  String get favoriteRemoveError => 'تعذر إزالة المطعم من المفضلة حالياً';

  @override
  String get refresh => 'تحديث';

  @override
  String get chooseStepOf => 'من';

  @override
  String get choosePriceTitle => 'وش ميزانيتك؟';

  @override
  String get choosePriceSubtitle => 'حدد مستوى السعر المناسب لك';

  @override
  String get chooseCategoryTitle => 'وش تشتهي اليوم؟';

  @override
  String get chooseCategorySubtitle => 'اختر نوعاً أو أكثر، أو اختر الكل';

  @override
  String get allCuisines => 'الكل';

  @override
  String get chooseNeighborhoodTitle => 'وين ودك تاكل؟';

  @override
  String get chooseNeighborhoodSubtitle => 'اختر الحي أو الأحياء المناسبة لك';

  @override
  String get next => 'التالي';

  @override
  String get selectionRequired => 'اختر خياراً واحداً على الأقل للمتابعة';

  @override
  String get searchNeighborhood => 'ابحث عن حي...';

  @override
  String get selectedNeighborhoods => 'الأحياء المختارة';

  @override
  String get allNeighborhoods => 'كل الأحياء';

  @override
  String get allNeighborhoodsHint =>
      'خلّ الاختيار مفتوحاً ونبحث لك في كل الأحياء';

  @override
  String get noNeighborhoodResults => 'ما لقينا حياً بهذا الاسم';

  @override
  String get chooseLoading => 'لحظة... ثريا تختار لك';

  @override
  String get recommendationTitle => 'اختيار ثريا لك';

  @override
  String get viewRestaurant => 'عرض المطعم';

  @override
  String get chooseAnother => 'اختيار مطعم آخر';

  @override
  String get changeSelections => 'تغيير الاختيارات';

  @override
  String get noMatchTitle => 'ما لقينا مطعم يطابق كل اختياراتك';

  @override
  String get noMatchSubtitle => 'جرب توسع اختياراتك ونختار لك من جديد';

  @override
  String get editSelections => 'تعديل الاختيارات';

  @override
  String get chooseLookupError => 'تعذر تحميل خيارات المطاعم حالياً';

  @override
  String get chooseRequestError => 'تعذر اختيار مطعم حالياً. حاول مرة أخرى.';

  @override
  String get recommendedRestaurant => 'مطعم مقترح لك';

  @override
  String get writeYourReview => 'اكتب مراجعتك';

  @override
  String get yourRating => 'تقييمك';

  @override
  String get reviewRatingBad => 'سيئ';

  @override
  String get reviewRatingAcceptable => 'مقبول';

  @override
  String get reviewRatingGood => 'جيد';

  @override
  String get reviewRatingVeryGood => 'جيد جداً';

  @override
  String get reviewRatingExcellent => 'ممتاز';

  @override
  String get reviewCommentLabel => 'تعليقك';

  @override
  String get reviewCommentHint => 'اكتب تجربتك مع المطعم...';

  @override
  String get submitReview => 'إرسال المراجعة';

  @override
  String get reviewCreatedSuccess => 'تمت إضافة مراجعتك بنجاح';

  @override
  String get reviewSubmitError => 'تعذر إرسال المراجعة حالياً. حاول مرة أخرى.';

  @override
  String get reviewDuplicateError => 'سبق أن أضفت مراجعة لهذا المطعم.';
}
