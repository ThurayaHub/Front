import 'package:thuraya/features/restaurants/models/restaurant_review.dart';

abstract final class MockRestaurantReviews {
  static List<RestaurantReview> forRestaurant(int restaurantId) {
    return switch (restaurantId) {
      1 => _iliaReviews,
      2 => _roasteryReviews,
      3 => _locomotiveReviews,
      _ => const [],
    };
  }

  static final List<RestaurantReview> _iliaReviews = [
    RestaurantReview(
      id: 101,
      restaurantId: 1,
      userId: 1001,
      reviewerName: 'عبدالله محمد',
      stars: 5,
      comment:
          'تجربة جميلة جداً، الخدمة ممتازة والطعام كان رائعاً. سأكرر الزيارة بالتأكيد.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 28, 12),
    ),
    RestaurantReview(
      id: 102,
      restaurantId: 1,
      userId: 1002,
      reviewerName: 'سارة أحمد',
      stars: 4,
      comment:
          'المكان جميل والأجواء هادئة، لكن وقت الانتظار كان أطول قليلاً من المتوقع.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 22, 12),
      updatedAtUtc: DateTime.utc(2026, 7, 23, 12),
    ),
    RestaurantReview(
      id: 103,
      restaurantId: 1,
      userId: 1003,
      reviewerName: 'نورة خالد',
      stars: 5,
      comment:
          'الأطباق البحرية طازجة والتقديم أنيق جداً. أعجبني اهتمام الفريق بالتفاصيل وسرعة الخدمة رغم ازدحام المطعم.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 16, 12),
    ),
    RestaurantReview(
      id: 104,
      restaurantId: 1,
      userId: 1004,
      reviewerName: 'محمد العتيبي',
      stars: 5,
      comment:
          'من أفضل التجارب البحرية في المدينة، وسأعود لتجربة بقية القائمة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 9, 12),
    ),
    RestaurantReview(
      id: 105,
      restaurantId: 1,
      userId: 1005,
      reviewerName: 'ريم السالم',
      stars: 5,
      comment:
          'جلسات مريحة وخدمة راقية، كما أن اقتراحات الموظف ساعدتنا في اختيار أطباق مناسبة للمشاركة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 6, 30, 12),
    ),
    RestaurantReview(
      id: 106,
      restaurantId: 1,
      userId: 1006,
      reviewerName: 'فيصل القحطاني',
      stars: 4,
      comment: 'جودة الطعام ممتازة والموقع جميل، والأسعار مرتفعة قليلاً.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 6, 21, 12),
    ),
  ];

  static final List<RestaurantReview> _roasteryReviews = [
    RestaurantReview(
      id: 201,
      restaurantId: 2,
      userId: 2001,
      reviewerName: 'ليان الشمري',
      stars: 5,
      comment: 'قهوة متقنة وطاقم يعرف تفاصيل المحاصيل ويقدم اقتراحات مناسبة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 25, 12),
    ),
    RestaurantReview(
      id: 202,
      restaurantId: 2,
      userId: 2002,
      reviewerName: 'عمر الحربي',
      stars: 5,
      comment: 'مكان هادئ ومناسب للعمل، والحلى كان خفيفاً ومتوازناً.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 18, 12),
    ),
    RestaurantReview(
      id: 203,
      restaurantId: 2,
      userId: 2003,
      reviewerName: 'هناء علي',
      stars: 4,
      comment: 'التجربة جميلة لكن الجلسات تمتلئ بسرعة في المساء.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 10, 12),
    ),
    RestaurantReview(
      id: 204,
      restaurantId: 2,
      userId: 2004,
      reviewerName: 'خالد صالح',
      stars: 5,
      comment: 'تحميص مميز وخيارات متنوعة لمحبي القهوة المقطرة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 2, 12),
    ),
  ];

  static final List<RestaurantReview> _locomotiveReviews = [
    RestaurantReview(
      id: 301,
      restaurantId: 3,
      userId: 3001,
      reviewerName: 'الجوهرة فهد',
      stars: 5,
      comment: 'حلويات رائعة وتقديم جميل، خصوصاً طبق الشوكولاتة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 27, 12),
    ),
    RestaurantReview(
      id: 302,
      restaurantId: 3,
      userId: 3002,
      reviewerName: 'ماجد الدوسري',
      stars: 5,
      comment: 'نكهات مبتكرة وأجواء دافئة، وكانت الخدمة سريعة ولطيفة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 20, 12),
    ),
    RestaurantReview(
      id: 303,
      restaurantId: 3,
      userId: 3003,
      reviewerName: 'أمل يوسف',
      stars: 4,
      comment: 'التجربة جميلة والتقديم أنيق، أتمنى إضافة خيارات أكثر بدون سكر.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 12, 12),
    ),
    RestaurantReview(
      id: 304,
      restaurantId: 3,
      userId: 3004,
      reviewerName: 'سلمان ناصر',
      stars: 5,
      comment: 'مناسب للقاءات الخفيفة والحلويات تستحق التجربة.',
      isPublished: true,
      createdAtUtc: DateTime.utc(2026, 7, 5, 12),
    ),
  ];
}
