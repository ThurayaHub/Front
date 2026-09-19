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
  /// **'Trending'**
  String get trendingTitle;

  /// No description provided for @trendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Trending restaurants'**
  String get trendingDescription;

  /// No description provided for @trendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trending restaurants right now'**
  String get trendingEmpty;

  /// No description provided for @trendingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Trending restaurants cannot be loaded right now'**
  String get trendingLoadError;

  /// No description provided for @trendingRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String trendingRankLabel(int rank);

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

  /// No description provided for @thurayaRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Thuraya rating'**
  String get thurayaRatingLabel;

  /// No description provided for @thurayaReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Thuraya review'**
  String get thurayaReviewLabel;

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

  /// No description provided for @directionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Directions cannot be opened right now.'**
  String get directionsUnavailable;

  /// No description provided for @shareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This restaurant cannot be shared right now.'**
  String get shareUnavailable;

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

  /// No description provided for @restaurantReviewListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The review summary is available, but individual user reviews are not currently provided by the server.'**
  String get restaurantReviewListUnavailable;

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

  /// No description provided for @searchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search and filters'**
  String get searchFiltersTitle;

  /// No description provided for @priceFilter.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceFilter;

  /// No description provided for @categoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFilter;

  /// No description provided for @ratingFilter.
  ///
  /// In en, this message translates to:
  /// **'User rating'**
  String get ratingFilter;

  /// No description provided for @minimumRatingHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get minimumRatingHint;

  /// No description provided for @hasThurayaRatingFilter.
  ///
  /// In en, this message translates to:
  /// **'Thuraya rated'**
  String get hasThurayaRatingFilter;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @restaurantResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} restaurants'**
  String restaurantResultsCount(int count);

  /// No description provided for @noSearchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find matching restaurants'**
  String get noSearchResultsTitle;

  /// No description provided for @noSearchResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search or removing some filters'**
  String get noSearchResultsSubtitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @searchResultsError.
  ///
  /// In en, this message translates to:
  /// **'Search results could not be loaded'**
  String get searchResultsError;

  /// No description provided for @filterOptionsError.
  ///
  /// In en, this message translates to:
  /// **'Filter choices could not be loaded'**
  String get filterOptionsError;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get activeFilters;

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

  /// No description provided for @wheelNetworkError.
  ///
  /// In en, this message translates to:
  /// **'The wheel could not connect right now. Please try again.'**
  String get wheelNetworkError;

  /// No description provided for @wheelBadRequestError.
  ///
  /// In en, this message translates to:
  /// **'The wheel request could not be completed. Check the options and try again.'**
  String get wheelBadRequestError;

  /// No description provided for @wheelForbiddenError.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this wheel session.'**
  String get wheelForbiddenError;

  /// No description provided for @wheelNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'This wheel session is no longer available. Please try again.'**
  String get wheelNotFoundError;

  /// No description provided for @wheelInvalidResponseError.
  ///
  /// In en, this message translates to:
  /// **'The wheel returned an unexpected result. Please try again.'**
  String get wheelInvalidResponseError;

  /// No description provided for @chooseRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Choose a restaurant'**
  String get chooseRestaurant;

  /// No description provided for @chooseRestaurantNavigation.
  ///
  /// In en, this message translates to:
  /// **'Choose for me'**
  String get chooseRestaurantNavigation;

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

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginTitle;

  /// No description provided for @authenticationWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Thuraya'**
  String get authenticationWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to continue to Thuraya features that require an account.'**
  String get loginSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+9665XXXXXXXX'**
  String get phoneNumberHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete registration'**
  String get registrationTitle;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This number is not registered. Complete your details to create a Thuraya account.'**
  String get registrationSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get changePhoneNumber;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @authenticationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete login right now. Please try again.'**
  String get authenticationUnavailable;

  /// No description provided for @accountGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Thuraya'**
  String get accountGuestTitle;

  /// No description provided for @accountGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to use favorites and features linked to your account.'**
  String get accountGuestSubtitle;

  /// No description provided for @accountWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String accountWelcome(String name);

  /// No description provided for @accountAuthenticatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your session is stored securely and protected Thuraya features are available.'**
  String get accountAuthenticatedSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @favoriteUpdateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Favorites cannot be updated right now. Please try again.'**
  String get favoriteUpdateUnavailable;

  /// No description provided for @profileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get profileDetailsTitle;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My favorites'**
  String get myFavorites;

  /// No description provided for @myReviews.
  ///
  /// In en, this message translates to:
  /// **'My reviews'**
  String get myReviews;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email address verified'**
  String get emailVerified;

  /// No description provided for @emailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Email address not verified'**
  String get emailUnverified;

  /// No description provided for @reviewsWritten.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsWritten(int count);

  /// No description provided for @profileDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Thuraya account information'**
  String get profileDetailsSubtitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurants you\'ve saved for easy access'**
  String get favoritesSubtitle;

  /// No description provided for @myReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant opinions and experiences'**
  String get myReviewsSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @emailVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get emailVerificationLabel;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(int year);

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Data could not be loaded'**
  String get profileLoadError;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any favorite restaurants yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save restaurants you like and find them here'**
  String get favoritesEmptySubtitle;

  /// No description provided for @reviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t written any reviews yet'**
  String get reviewsEmptyTitle;

  /// No description provided for @reviewsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a restaurant and share your experience'**
  String get reviewsEmptySubtitle;

  /// No description provided for @exploreRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Explore restaurants'**
  String get exploreRestaurants;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @favoriteRemoveError.
  ///
  /// In en, this message translates to:
  /// **'The restaurant could not be removed from favorites'**
  String get favoriteRemoveError;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @chooseStepOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get chooseStepOf;

  /// No description provided for @choosePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your budget?'**
  String get choosePriceTitle;

  /// No description provided for @choosePriceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the price level that suits you'**
  String get choosePriceSubtitle;

  /// No description provided for @chooseCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you craving today?'**
  String get chooseCategoryTitle;

  /// No description provided for @chooseCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more restaurant types'**
  String get chooseCategorySubtitle;

  /// No description provided for @chooseNeighborhoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to eat?'**
  String get chooseNeighborhoodTitle;

  /// No description provided for @chooseNeighborhoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a suitable neighborhood or neighborhoods'**
  String get chooseNeighborhoodSubtitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @selectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one option to continue'**
  String get selectionRequired;

  /// No description provided for @searchNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Search for a neighborhood...'**
  String get searchNeighborhood;

  /// No description provided for @selectedNeighborhoods.
  ///
  /// In en, this message translates to:
  /// **'Selected neighborhoods'**
  String get selectedNeighborhoods;

  /// No description provided for @allNeighborhoods.
  ///
  /// In en, this message translates to:
  /// **'All neighborhoods'**
  String get allNeighborhoods;

  /// No description provided for @allNeighborhoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Keep it open and we\'ll search every neighborhood'**
  String get allNeighborhoodsHint;

  /// No description provided for @noNeighborhoodResults.
  ///
  /// In en, this message translates to:
  /// **'No neighborhood matches that search'**
  String get noNeighborhoodResults;

  /// No description provided for @chooseLoading.
  ///
  /// In en, this message translates to:
  /// **'One moment... Thuraya is choosing for you'**
  String get chooseLoading;

  /// No description provided for @recommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Thuraya\'s choice for you'**
  String get recommendationTitle;

  /// No description provided for @viewRestaurant.
  ///
  /// In en, this message translates to:
  /// **'View restaurant'**
  String get viewRestaurant;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another restaurant'**
  String get chooseAnother;

  /// No description provided for @changeSelections.
  ///
  /// In en, this message translates to:
  /// **'Change selections'**
  String get changeSelections;

  /// No description provided for @noMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a restaurant matching every choice'**
  String get noMatchTitle;

  /// No description provided for @noMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broaden your choices and we\'ll choose again'**
  String get noMatchSubtitle;

  /// No description provided for @editSelections.
  ///
  /// In en, this message translates to:
  /// **'Edit selections'**
  String get editSelections;

  /// No description provided for @chooseLookupError.
  ///
  /// In en, this message translates to:
  /// **'Restaurant choices cannot be loaded right now'**
  String get chooseLookupError;

  /// No description provided for @chooseRequestError.
  ///
  /// In en, this message translates to:
  /// **'A restaurant cannot be selected right now. Try again.'**
  String get chooseRequestError;

  /// No description provided for @recommendedRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedRestaurant;

  /// No description provided for @writeYourReview.
  ///
  /// In en, this message translates to:
  /// **'Write your review'**
  String get writeYourReview;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @reviewRatingBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get reviewRatingBad;

  /// No description provided for @reviewRatingAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Acceptable'**
  String get reviewRatingAcceptable;

  /// No description provided for @reviewRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewRatingGood;

  /// No description provided for @reviewRatingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get reviewRatingVeryGood;

  /// No description provided for @reviewRatingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get reviewRatingExcellent;

  /// No description provided for @reviewCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Your comment'**
  String get reviewCommentLabel;

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your experience with the restaurant...'**
  String get reviewCommentHint;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reviewCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your review was added successfully'**
  String get reviewCreatedSuccess;

  /// No description provided for @reviewSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Your review could not be submitted right now. Please try again.'**
  String get reviewSubmitError;

  /// No description provided for @reviewDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this restaurant.'**
  String get reviewDuplicateError;
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
