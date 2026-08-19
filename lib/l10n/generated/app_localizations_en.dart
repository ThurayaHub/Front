// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Thuraya';

  @override
  String get back => 'Back';

  @override
  String get trendingTitle => 'Trending now';

  @override
  String get trendingDescription =>
      'Discover the city\'s most popular destinations right now.';

  @override
  String get activeNow => 'Active now';

  @override
  String get trendingRestaurantOneName => 'Ilia Diving';

  @override
  String get trendingRestaurantOneDetails => 'Seafood • Al Olaya';

  @override
  String get trendingRestaurantTwoName => 'Al Osool Roastery';

  @override
  String get trendingRestaurantTwoDetails => 'Specialty coffee • Al Malqa';

  @override
  String get trendingRestaurantThreeName => 'Locomotive';

  @override
  String get trendingRestaurantThreeDetails =>
      'Fine desserts • Al Sulaymaniyah';

  @override
  String get restaurantOneCategory => 'Seafood';

  @override
  String get restaurantOneNeighborhood => 'Al Olaya';

  @override
  String get restaurantOneDescription =>
      'Ilia Diving offers an exceptional seafood experience blending contemporary global flavors with classic coastal touches, in a refined atmosphere with attentive service for guests seeking something distinctive.';

  @override
  String get restaurantTwoCategory => 'Specialty coffee';

  @override
  String get restaurantTwoNeighborhood => 'Al Malqa';

  @override
  String get restaurantTwoDescription =>
      'Al Osool Roastery offers a specialty coffee experience with close attention to every detail, from selecting and roasting the beans to serving them in a calm, modern setting for coffee lovers.';

  @override
  String get restaurantThreeCategory => 'Fine desserts';

  @override
  String get restaurantThreeNeighborhood => 'Al Sulaymaniyah';

  @override
  String get restaurantThreeDescription =>
      'Locomotive presents an inventive selection of carefully prepared fine desserts, with balanced flavors and elegant presentation in a warm setting for memorable gatherings.';

  @override
  String get saveRestaurant => 'Save restaurant';

  @override
  String get thurayaStar => 'Thuraya Star';

  @override
  String get thurayaStarDescription =>
      'Awarded the star of excellence for culinary creativity';

  @override
  String userReviewCount(int count) {
    return '$count user reviews';
  }

  @override
  String get call => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get share => 'Share';

  @override
  String get aboutRestaurant => 'About the restaurant';

  @override
  String get photos => 'Photos';

  @override
  String get viewAll => 'View all';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get openRestaurantReviews => 'View user reviews';

  @override
  String ratingCount(int count) {
    return '$count reviews';
  }

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get searchRestaurant => 'Search for a restaurant...';

  @override
  String get filterRestaurants => 'Filter restaurants';

  @override
  String get currentLocation => 'Current location';

  @override
  String get locatingCurrentLocation => 'Finding your current location';

  @override
  String get locationPermissionDenied => 'Location permission was denied';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location access is blocked. You can enable it in Settings.';

  @override
  String get locationServicesDisabled => 'Location services are turned off';

  @override
  String get locationUnavailable =>
      'We couldn\'t find your location right now. Please try again.';

  @override
  String get restaurantMarkersUnavailable =>
      'Restaurants cannot be loaded on the map right now';

  @override
  String get loadingRestaurantDetails => 'Loading restaurant details...';

  @override
  String get restaurantDetailsUnavailable =>
      'Restaurant details cannot be loaded right now';

  @override
  String get retry => 'Try again';

  @override
  String serviceAvailableInRegion(String region) {
    return 'The service is currently available only in $region';
  }

  @override
  String get settings => 'Settings';

  @override
  String get homeRestaurantName => 'Nozomi';

  @override
  String get homeRestaurantCategory => 'Contemporary Japanese cuisine';

  @override
  String get homeRestaurantNeighborhood => 'Al Olaya';

  @override
  String get homeRestaurantDescription =>
      'Nozomi offers a refined contemporary Japanese dining experience with elegant dishes, balanced flavors, and attentive service in a sophisticated atmosphere.';

  @override
  String minutesAway(int count) {
    return '$count min';
  }

  @override
  String get search => 'Search';

  @override
  String get trending => 'Trending';

  @override
  String get wheel => 'Wheel';

  @override
  String get wheelHeroTitle => 'Not sure? Leave it to us';

  @override
  String get wheelHeroSubtitle => 'Spin the wheel and try your luck';

  @override
  String get addWheelOption => 'Add an option';

  @override
  String get enterWheelOption => 'Enter an option name';

  @override
  String get duplicateWheelOption => 'This option already exists';

  @override
  String get minimumWheelOptions => 'Add at least two options';

  @override
  String get spinWheel => 'Spin the wheel';

  @override
  String get yourWheelChoice => 'Your choice is';

  @override
  String get wheelOptionBurger => 'Burger';

  @override
  String get wheelOptionPizza => 'Pizza';

  @override
  String get wheelOptionSushi => 'Sushi';

  @override
  String get wheelOptionCoffee => 'Coffee';

  @override
  String get chooseRestaurant => 'Choose a restaurant';

  @override
  String get account => 'Account';

  @override
  String get home => 'Home';
}
