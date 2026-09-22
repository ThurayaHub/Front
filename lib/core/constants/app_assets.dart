abstract final class AppAssets {
  static const String branding = 'assets/branding';
  static const String images = 'assets/images';
  static const String icons = 'assets/icons';

  static const String thurayaLogo = '$branding/thuraya_logo.png';
  static const String thurayaStar = '$images/awards/thuraya_star.png';

  static const String trendingRestaurantInterior =
      '$images/trending/restaurant_interior.png';
  static const String trendingCoffeeShop = '$images/trending/coffee_shop.png';
  static const String trendingGourmetDessert =
      '$images/trending/gourmet_dessert.png';

  static const String navTrending = '$icons/trending/trending.svg';
  static const String navProfile = '$icons/trending/profile.svg';
  static const String navHome = '$icons/trending/home_map.svg';
  static const String backArrow = '$icons/trending/back_arrow.svg';
  static const String ratingStar = '$icons/trending/rating_star.svg';
  static const String hot = '$icons/trending/hot.svg';
  static const String wheelPointer = '$icons/wheel/pointer.svg';

  static const String homeMap = '$images/home/map.png';
  static const String homeNozomi = '$images/home/nozomi.png';
  static const String homeFilter = '$icons/home/filter.svg';
  static const String homeSearch = '$icons/home/search.svg';
  static const String homeFavorite = '$icons/home/favorite.svg';
  static const String homeMarkerPremiumStar =
      '$icons/home/marker_premium_star.svg';
  static const String homeMarkerCutlery = '$icons/home/marker_cutlery.svg';
  static const String homeRatingStar = '$icons/home/rating_star.svg';
  static const String homeThurayaRatingStar =
      '$icons/home/thuraya_rating_star.svg';

  static const String restaurantDetailsCover =
      '$images/restaurant_details/cover.png';
  static const String restaurantGalleryFood =
      '$images/restaurant_details/gallery_food.jpeg';
  static const String restaurantGalleryDining =
      '$images/restaurant_details/gallery_dining.jpeg';
  static const String restaurantGalleryCocktail =
      '$images/restaurant_details/gallery_cocktail.jpeg';

  static const String restaurantBookmark =
      '$icons/restaurant_details/bookmark.svg';
  static const String restaurantBackArrow =
      '$icons/restaurant_details/back_arrow.svg';
  static const String restaurantCutlery =
      '$icons/restaurant_details/cutlery.svg';
  static const String restaurantRatingStar =
      '$icons/restaurant_details/rating_star.svg';
  static const String restaurantAwardStar =
      '$icons/restaurant_details/award_star.svg';
  static const String restaurantPhone = '$icons/restaurant_details/phone.svg';
  static const String restaurantDirections =
      '$icons/restaurant_details/directions.svg';
  static const String restaurantShare = '$icons/restaurant_details/share.svg';

  static String image(String fileName) => '$images/$fileName';

  static String icon(String fileName) => '$icons/$fileName';
}
