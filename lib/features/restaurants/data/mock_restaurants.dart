import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/features/restaurants/data/mock_restaurant_reviews.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

abstract final class MockRestaurants {
  static List<Restaurant> homeLocalized(AppLocalizations localizations) {
    const galleryImages = [
      AppAssets.homeNozomi,
      AppAssets.restaurantGalleryDining,
      AppAssets.restaurantGalleryCocktail,
    ];
    final existingRestaurants = localized(localizations);

    return [
      Restaurant(
        id: 4,
        cardImage: AppAssets.homeNozomi,
        coverImage: AppAssets.homeNozomi,
        name: localizations.homeRestaurantName,
        category: localizations.homeRestaurantCategory,
        neighborhood: localizations.homeRestaurantNeighborhood,
        priceLevel: r'$$$',
        rating: 4.8,
        reviewCount: 120,
        description: localizations.homeRestaurantDescription,
        galleryImages: galleryImages,
        reviews: MockRestaurantReviews.forRestaurant(1),
        cardStatus: RestaurantCardStatus.thurayaStar,
        thurayaRating: 4.9,
        travelMinutes: 5,
      ),
      existingRestaurants[0],
      existingRestaurants[1],
    ];
  }

  static List<Restaurant> localized(AppLocalizations localizations) {
    const galleryImages = [
      AppAssets.restaurantGalleryFood,
      AppAssets.restaurantGalleryDining,
      AppAssets.restaurantGalleryCocktail,
    ];

    return [
      Restaurant(
        id: 1,
        cardImage: AppAssets.trendingRestaurantInterior,
        coverImage: AppAssets.restaurantDetailsCover,
        name: localizations.trendingRestaurantOneName,
        category: localizations.restaurantOneCategory,
        neighborhood: localizations.restaurantOneNeighborhood,
        priceLevel: r'$$$',
        rating: 4.8,
        reviewCount: 124,
        description: localizations.restaurantOneDescription,
        galleryImages: galleryImages,
        reviews: MockRestaurantReviews.forRestaurant(1),
        cardStatus: RestaurantCardStatus.thurayaStar,
        isHot: true,
        thurayaRating: 4.9,
        travelMinutes: 7,
      ),
      Restaurant(
        id: 2,
        cardImage: AppAssets.trendingCoffeeShop,
        coverImage: AppAssets.trendingCoffeeShop,
        name: localizations.trendingRestaurantTwoName,
        category: localizations.restaurantTwoCategory,
        neighborhood: localizations.restaurantTwoNeighborhood,
        priceLevel: r'$$',
        rating: 4.8,
        reviewCount: 96,
        description: localizations.restaurantTwoDescription,
        galleryImages: galleryImages,
        reviews: MockRestaurantReviews.forRestaurant(2),
        cardStatus: RestaurantCardStatus.rating,
        isHot: true,
        thurayaRating: 4.7,
        travelMinutes: 9,
      ),
      Restaurant(
        id: 3,
        cardImage: AppAssets.trendingGourmetDessert,
        coverImage: AppAssets.trendingGourmetDessert,
        name: localizations.trendingRestaurantThreeName,
        category: localizations.restaurantThreeCategory,
        neighborhood: localizations.restaurantThreeNeighborhood,
        priceLevel: r'$$$',
        rating: 4.9,
        reviewCount: 142,
        description: localizations.restaurantThreeDescription,
        galleryImages: galleryImages,
        reviews: MockRestaurantReviews.forRestaurant(3),
        cardStatus: RestaurantCardStatus.thurayaStar,
        thurayaRating: 4.9,
        travelMinutes: 11,
      ),
    ];
  }
}
