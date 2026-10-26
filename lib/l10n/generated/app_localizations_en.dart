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
  String get trendingTitle => 'Trending';

  @override
  String get trendingDescription => 'Trending restaurants';

  @override
  String get trendingEmpty => 'No trending restaurants right now';

  @override
  String get trendingLoadError =>
      'Trending restaurants cannot be loaded right now';

  @override
  String trendingRankLabel(int rank) {
    return 'Rank $rank';
  }

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
  String get thurayaRatingLabel => 'Thuraya rating';

  @override
  String get thurayaReviewLabel => 'Thuraya review';

  @override
  String get thurayaEvaluations => 'Thuraya evaluations';

  @override
  String thurayaRatedOn(String date) {
    return 'Rated on $date';
  }

  @override
  String thurayaRatingUpdatedOn(String date) {
    return 'Updated on $date';
  }

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
  String get directionsUnavailable => 'Directions cannot be opened right now.';

  @override
  String get shareUnavailable => 'This restaurant cannot be shared right now.';

  @override
  String get aboutRestaurant => 'About the restaurant';

  @override
  String get photos => 'Photos';

  @override
  String get overviewTab => 'Overview';

  @override
  String get communityRating => 'Community rating';

  @override
  String get restaurantHighlights => 'Restaurant highlights';

  @override
  String get restaurantInformation => 'Restaurant information';

  @override
  String get restaurantLocation => 'Location';

  @override
  String get cuisines => 'Cuisines';

  @override
  String get price => 'Price';

  @override
  String get restaurantStatus => 'Status';

  @override
  String get outOfFive => 'out of 5';

  @override
  String get outOfTen => 'out of 10';

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String get noPhotosAvailable => 'No restaurant photos yet';

  @override
  String get noPhotosAvailableSubtitle =>
      'Photos will appear here when they become available.';

  @override
  String get thurayaStarMeaning => 'What is the Thuraya Star?';

  @override
  String get thurayaStarMeaningDescription =>
      'The Thuraya Star is an exclusive distinction awarded by Thuraya. It is separate from Thuraya\'s numerical evaluation and community ratings.';

  @override
  String photoPosition(int current, int total) {
    return 'Photo $current of $total';
  }

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
  String get loadingReviews => 'Loading reviews...';

  @override
  String get reviewsLoadError => 'Reviews could not be loaded.';

  @override
  String get searchRestaurant => 'Search for a restaurant...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get filterRestaurants => 'Filter restaurants';

  @override
  String get searchFiltersTitle => 'Search and filters';

  @override
  String get priceFilter => 'Price';

  @override
  String get categoryFilter => 'Category';

  @override
  String get ratingFilter => 'User rating';

  @override
  String get minimumRatingHint => 'Minimum rating';

  @override
  String get hasThurayaRatingFilter => 'Thuraya rated';

  @override
  String get showResults => 'Show results';

  @override
  String get clearAll => 'Clear all';

  @override
  String get mapView => 'Map';

  @override
  String get listView => 'List';

  @override
  String restaurantResultsCount(int count) {
    return '$count restaurants';
  }

  @override
  String get noSearchResultsTitle => 'We couldn\'t find matching restaurants';

  @override
  String get noSearchResultsSubtitle =>
      'Try changing your search or removing some filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get searchResultsError => 'Search results could not be loaded';

  @override
  String get filterOptionsError => 'Filter choices could not be loaded';

  @override
  String get activeFilters => 'Active filters';

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
  String get wheelEmptyState => 'Add your options and start spinning';

  @override
  String get removeWheelOption => 'Remove option';

  @override
  String get wheelNetworkError =>
      'The wheel could not connect right now. Please try again.';

  @override
  String get wheelBadRequestError =>
      'The wheel request could not be completed. Check the options and try again.';

  @override
  String get wheelForbiddenError =>
      'You do not have access to this wheel session.';

  @override
  String get wheelNotFoundError =>
      'This wheel session is no longer available. Please try again.';

  @override
  String get wheelInvalidResponseError =>
      'The wheel returned an unexpected result. Please try again.';

  @override
  String get chooseRestaurant => 'Choose a restaurant';

  @override
  String get chooseRestaurantNavigation => 'Choose for me';

  @override
  String get account => 'Account';

  @override
  String get home => 'Home';

  @override
  String get loginTitle => 'Log in';

  @override
  String get authenticationWelcome => 'Welcome to Thuraya';

  @override
  String get loginSubtitle =>
      'Enter your mobile number to continue to Thuraya features that require an account.';

  @override
  String get phoneNumber => 'Mobile number';

  @override
  String get phoneNumberHint => '05XXXXXXXX';

  @override
  String get continueLabel => 'Continue';

  @override
  String get otpTitle => 'Verify mobile number';

  @override
  String get otpSubtitle =>
      'Enter the one-time code sent to your mobile number.';

  @override
  String otpSentTo(String phoneNumber) {
    return 'We sent a verification code to $phoneNumber';
  }

  @override
  String get otpCode => 'Verification code';

  @override
  String get otpHint => 'Enter the code';

  @override
  String get verifyOtp => 'Verify code';

  @override
  String get resendOtp => 'Resend code';

  @override
  String get otpSent => 'A new verification code was sent.';

  @override
  String get invalidOtp => 'Enter a valid verification code';

  @override
  String get otpTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get otpUnavailable =>
      'Phone verification is unavailable right now. Please try again.';

  @override
  String get registrationTitle => 'Complete registration';

  @override
  String get registrationSubtitle =>
      'This number is not registered. Complete your details to create a Thuraya account.';

  @override
  String get fullName => 'Name';

  @override
  String get emailAddress => 'Email address';

  @override
  String get createAccount => 'Create account';

  @override
  String get changePhoneNumber => 'Change mobile number';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidSaudiPhone =>
      'Enter a valid 10-digit Saudi mobile number starting with 05';

  @override
  String get invalidNameCharacters =>
      'Name can contain only Arabic or English letters and spaces';

  @override
  String get invalidEmailCharacters => 'Email contains invalid characters';

  @override
  String get emailAlreadyInUse => 'This email address is already in use';

  @override
  String maximumLengthExceeded(int maxLength) {
    return 'Maximum length is $maxLength characters';
  }

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get authenticationUnavailable =>
      'We couldn\'t complete login right now. Please try again.';

  @override
  String get accountGuestTitle => 'Welcome to Thuraya';

  @override
  String get accountGuestSubtitle =>
      'Log in to use favorites and features linked to your account.';

  @override
  String accountWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get accountAuthenticatedSubtitle =>
      'Your session is stored securely and protected Thuraya features are available.';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get favoriteUpdateUnavailable =>
      'Favorites cannot be updated right now. Please try again.';

  @override
  String get profileDetailsTitle => 'My details';

  @override
  String get myFavorites => 'My favorites';

  @override
  String get myReviews => 'My reviews';

  @override
  String get emailVerified => 'Verified';

  @override
  String get emailUnverified => 'Not Verified';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String resendVerificationEmailIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get sendingVerificationEmail => 'Sending verification email...';

  @override
  String get verificationEmailSent =>
      'Verification email sent. Open the link in the email, then return to Thuraya.';

  @override
  String get verificationEmailRateLimited =>
      'Please wait before requesting another verification email.';

  @override
  String get verificationEmailRequestFailed =>
      'We couldn\'t send the verification email. Please try again.';

  @override
  String reviewsWritten(int count) {
    return '$count reviews';
  }

  @override
  String get profileDetailsSubtitle => 'Your Thuraya account information';

  @override
  String get favoritesSubtitle => 'Restaurants you\'ve saved for easy access';

  @override
  String get myReviewsSubtitle => 'Your restaurant opinions and experiences';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailVerificationLabel => 'Email verification';

  @override
  String get notAdded => 'Not added';

  @override
  String memberSince(int year) {
    return 'Member since $year';
  }

  @override
  String get profileLoadError => 'Data could not be loaded';

  @override
  String get favoritesEmptyTitle =>
      'You don\'t have any favorite restaurants yet';

  @override
  String get favoritesEmptySubtitle =>
      'Save restaurants you like and find them here';

  @override
  String get reviewsEmptyTitle => 'You haven\'t written any reviews yet';

  @override
  String get reviewsEmptySubtitle =>
      'Try a restaurant and share your experience';

  @override
  String get exploreRestaurants => 'Explore restaurants';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get favoriteRemoveError =>
      'The restaurant could not be removed from favorites';

  @override
  String get refresh => 'Refresh';

  @override
  String get chooseStepOf => 'of';

  @override
  String get choosePriceTitle => 'What\'s your budget?';

  @override
  String get choosePriceSubtitle => 'Select the price level that suits you';

  @override
  String get chooseCategoryTitle => 'What are you craving today?';

  @override
  String get chooseCategorySubtitle =>
      'Choose one or more cuisines, or choose All';

  @override
  String get allCuisines => 'All';

  @override
  String get chooseNeighborhoodTitle => 'Where would you like to eat?';

  @override
  String get chooseNeighborhoodSubtitle =>
      'Choose a suitable neighborhood or neighborhoods';

  @override
  String get next => 'Next';

  @override
  String get selectionRequired => 'Choose at least one option to continue';

  @override
  String get searchNeighborhood => 'Search for a neighborhood...';

  @override
  String get selectedNeighborhoods => 'Selected neighborhoods';

  @override
  String get allNeighborhoods => 'All neighborhoods';

  @override
  String get allNeighborhoodsHint =>
      'Keep it open and we\'ll search every neighborhood';

  @override
  String get noNeighborhoodResults => 'No neighborhood matches that search';

  @override
  String get chooseLoading => 'One moment... Thuraya is choosing for you';

  @override
  String get recommendationTitle => 'Thuraya\'s choice for you';

  @override
  String get viewRestaurant => 'View restaurant';

  @override
  String get chooseAnother => 'Choose another restaurant';

  @override
  String get changeSelections => 'Change selections';

  @override
  String get noMatchTitle =>
      'We couldn\'t find a restaurant matching every choice';

  @override
  String get noMatchSubtitle => 'Broaden your choices and we\'ll choose again';

  @override
  String get editSelections => 'Edit selections';

  @override
  String get chooseLookupError =>
      'Restaurant choices cannot be loaded right now';

  @override
  String get chooseRequestError =>
      'A restaurant cannot be selected right now. Try again.';

  @override
  String get recommendedRestaurant => 'Recommended for you';

  @override
  String get writeYourReview => 'Write your review';

  @override
  String get yourRating => 'Your rating';

  @override
  String get reviewRatingBad => 'Bad';

  @override
  String get reviewRatingAcceptable => 'Acceptable';

  @override
  String get reviewRatingGood => 'Good';

  @override
  String get reviewRatingVeryGood => 'Very good';

  @override
  String get reviewRatingExcellent => 'Excellent';

  @override
  String get reviewCommentLabel => 'Your comment';

  @override
  String get reviewCommentHint =>
      'Tell us about your experience with the restaurant...';

  @override
  String get submitReview => 'Submit review';

  @override
  String get reviewCreatedSuccess => 'Your review was added successfully';

  @override
  String get reviewSubmitError =>
      'Your review could not be submitted right now. Please try again.';

  @override
  String get reviewDuplicateError =>
      'You have already reviewed this restaurant.';

  @override
  String get editProfileField => 'Edit';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get verified => 'Verified';

  @override
  String get unverified => 'Not verified';

  @override
  String get editNameTitle => 'Edit name';

  @override
  String get editEmailTitle => 'Change email address';

  @override
  String get editPhoneTitle => 'Change mobile number';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get profileUpdateSuccess => 'Your profile was updated.';

  @override
  String get profileUpdateFailed =>
      'We couldn\'t update your profile. Please try again.';

  @override
  String get pendingEmailTitle => 'Email change pending';

  @override
  String pendingEmailMessage(String email) {
    return 'We sent a verification link to $email. Your current email remains active until you confirm it.';
  }

  @override
  String get pendingPhoneTitle => 'Mobile change pending';

  @override
  String pendingPhoneMessage(String phone) {
    return 'Enter the OTP sent to $phone to finish changing your mobile number.';
  }

  @override
  String get enterOtpTitle => 'Verify new mobile number';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get verifyCode => 'Verify code';

  @override
  String get resendCode => 'Resend code';

  @override
  String get cancelChange => 'Cancel change';

  @override
  String get emailChangeRequested =>
      'Check the new inbox and open the verification link.';

  @override
  String get phoneCodeSent =>
      'A verification code was sent to the new mobile number.';

  @override
  String get phoneVerified => 'Your mobile number was changed and verified.';

  @override
  String get saving => 'Saving...';
}
