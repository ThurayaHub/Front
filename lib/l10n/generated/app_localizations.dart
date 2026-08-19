import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Thuraya'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @trendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get trendingTitle;

  /// No description provided for @trendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover the city\'s most popular destinations right now.'**
  String get trendingDescription;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @trendingRestaurantOneName.
  ///
  /// In en, this message translates to:
  /// **'Ilia Diving'**
  String get trendingRestaurantOneName;

  /// No description provided for @trendingRestaurantOneDetails.
  ///
  /// In en, this message translates to:
  /// **'Seafood • Al Olaya'**
  String get trendingRestaurantOneDetails;

  /// No description provided for @trendingRestaurantTwoName.
  ///
  /// In en, this message translates to:
  /// **'Al Osool Roastery'**
  String get trendingRestaurantTwoName;

  /// No description provided for @trendingRestaurantTwoDetails.
  ///
  /// In en, this message translates to:
  /// **'Specialty coffee • Al Malqa'**
  String get trendingRestaurantTwoDetails;

  /// No description provided for @trendingRestaurantThreeName.
  ///
  /// In en, this message translates to:
  /// **'Locomotive'**
  String get trendingRestaurantThreeName;

  /// No description provided for @trendingRestaurantThreeDetails.
  ///
  /// In en, this message translates to:
  /// **'Fine desserts • Al Sulaymaniyah'**
  String get trendingRestaurantThreeDetails;

  /// No description provided for @restaurantOneCategory.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get restaurantOneCategory;

  /// No description provided for @restaurantOneNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Al Olaya'**
  String get restaurantOneNeighborhood;

  /// No description provided for @restaurantOneDescription.
  ///
  /// In en, this message translates to:
  /// **'Ilia Diving offers an exceptional seafood experience blending contemporary global flavors with classic coastal touches, in a refined atmosphere with attentive service for guests seeking something distinctive.'**
  String get restaurantOneDescription;

  /// No description provided for @restaurantTwoCategory.
  ///
  /// In en, this message translates to:
  /// **'Specialty coffee'**
  String get restaurantTwoCategory;

  /// No description provided for @restaurantTwoNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Al Malqa'**
  String get restaurantTwoNeighborhood;

  /// No description provided for @restaurantTwoDescription.
  ///
  /// In en, this message translates to:
  /// **'Al Osool Roastery offers a specialty coffee experience with close attention to every detail, from selecting and roasting the beans to serving them in a calm, modern setting for coffee lovers.'**
  String get restaurantTwoDescription;

  /// No description provided for @restaurantThreeCategory.
  ///
  /// In en, this message translates to:
  /// **'Fine desserts'**
  String get restaurantThreeCategory;

  /// No description provided for @restaurantThreeNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Al Sulaymaniyah'**
  String get restaurantThreeNeighborhood;

  /// No description provided for @restaurantThreeDescription.
  ///
  /// In en, this message translates to:
  /// **'Locomotive presents an inventive selection of carefully prepared fine desserts, with balanced flavors and elegant presentation in a warm setting for memorable gatherings.'**
  String get restaurantThreeDescription;

  /// No description provided for @saveRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Save restaurant'**
  String get saveRestaurant;

  /// No description provided for @thurayaStar.
  ///
  /// In en, this message translates to:
  /// **'Thuraya Star'**
  String get thurayaStar;

  /// No description provided for @thurayaStarDescription.
  ///
  /// In en, this message translates to:
  /// **'Awarded the star of excellence for culinary creativity'**
  String get thurayaStarDescription;

  /// No description provided for @userReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} user reviews'**
  String userReviewCount(int count);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @aboutRestaurant.
  ///
  /// In en, this message translates to:
  /// **'About the restaurant'**
  String get aboutRestaurant;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @openRestaurantReviews.
  ///
  /// In en, this message translates to:
  /// **'View user reviews'**
  String get openRestaurantReviews;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String ratingCount(int count);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @searchRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Search for a restaurant...'**
  String get searchRestaurant;

  /// No description provided for @filterRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Filter restaurants'**
  String get filterRestaurants;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @locatingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your current location'**
  String get locatingCurrentLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. You can enable it in Settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off'**
  String get locationServicesDisabled;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your location right now. Please try again.'**
  String get locationUnavailable;

  /// No description provided for @restaurantMarkersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restaurants cannot be loaded on the map right now'**
  String get restaurantMarkersUnavailable;

  /// No description provided for @loadingRestaurantDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading restaurant details...'**
  String get loadingRestaurantDetails;

  /// No description provided for @restaurantDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restaurant details cannot be loaded right now'**
  String get restaurantDetailsUnavailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @serviceAvailableInRegion.
  ///
  /// In en, this message translates to:
  /// **'The service is currently available only in {region}'**
  String serviceAvailableInRegion(String region);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @homeRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Nozomi'**
  String get homeRestaurantName;

  /// No description provided for @homeRestaurantCategory.
  ///
  /// In en, this message translates to:
  /// **'Contemporary Japanese cuisine'**
  String get homeRestaurantCategory;

  /// No description provided for @homeRestaurantNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Al Olaya'**
  String get homeRestaurantNeighborhood;

  /// No description provided for @homeRestaurantDescription.
  ///
  /// In en, this message translates to:
  /// **'Nozomi offers a refined contemporary Japanese dining experience with elegant dishes, balanced flavors, and attentive service in a sophisticated atmosphere.'**
  String get homeRestaurantDescription;

  /// No description provided for @minutesAway.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesAway(int count);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @wheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel'**
  String get wheel;

  /// No description provided for @wheelHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure? Leave it to us'**
  String get wheelHeroTitle;

  /// No description provided for @wheelHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel and try your luck'**
  String get wheelHeroSubtitle;

  /// No description provided for @addWheelOption.
  ///
  /// In en, this message translates to:
  /// **'Add an option'**
  String get addWheelOption;

  /// No description provided for @enterWheelOption.
  ///
  /// In en, this message translates to:
  /// **'Enter an option name'**
  String get enterWheelOption;

  /// No description provided for @duplicateWheelOption.
  ///
  /// In en, this message translates to:
  /// **'This option already exists'**
  String get duplicateWheelOption;

  /// No description provided for @minimumWheelOptions.
  ///
  /// In en, this message translates to:
  /// **'Add at least two options'**
  String get minimumWheelOptions;

  /// No description provided for @spinWheel.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel'**
  String get spinWheel;

  /// No description provided for @yourWheelChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice is'**
  String get yourWheelChoice;

  /// No description provided for @wheelOptionBurger.
  ///
  /// In en, this message translates to:
  /// **'Burger'**
  String get wheelOptionBurger;

  /// No description provided for @wheelOptionPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get wheelOptionPizza;

  /// No description provided for @wheelOptionSushi.
  ///
  /// In en, this message translates to:
  /// **'Sushi'**
  String get wheelOptionSushi;

  /// No description provided for @wheelOptionCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get wheelOptionCoffee;

  /// No description provided for @chooseRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Choose a restaurant'**
  String get chooseRestaurant;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
