import 'package:flutter/material.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/features/account/presentation/account_page.dart';
import 'package:thuraya/features/account/presentation/profile_details_page.dart';
import 'package:thuraya/features/account/presentation/profile_favorites_page.dart';
import 'package:thuraya/features/account/presentation/profile_reviews_page.dart';
import 'package:thuraya/features/authentication/presentation/login_page.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_page.dart';
import 'package:thuraya/features/home/presentation/home_page.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/presentation/restaurant_details_page.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/restaurant_reviews_page.dart';
import 'package:thuraya/features/restaurant_reviews/models/restaurant_reviews_data.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/trending/presentation/trending_page.dart';
import 'package:thuraya/features/wheel/presentation/wheel_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case AppRouteNames.login:
        return MaterialPageRoute<bool>(
          builder: (_) => const LoginPage(),
          settings: settings,
          fullscreenDialog: true,
        );
      case AppRouteNames.account:
        return MaterialPageRoute<void>(
          builder: (_) => const AccountPage(),
          settings: settings,
        );
      case AppRouteNames.profileDetails:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileDetailsPage(),
          settings: settings,
        );
      case AppRouteNames.profileFavorites:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileFavoritesPage(),
          settings: settings,
        );
      case AppRouteNames.profileReviews:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileReviewsPage(),
          settings: settings,
        );
      case AppRouteNames.trending:
        return MaterialPageRoute<void>(
          builder: (_) => const TrendingPage(),
          settings: settings,
        );
      case AppRouteNames.restaurantDetails:
        final detailsArgument = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => switch (detailsArgument) {
            Restaurant restaurant => RestaurantDetailsPage(
              restaurant: restaurant,
            ),
            RestaurantDetailsDto details => RestaurantDetailsPage.fromDetails(
              details: details,
            ),
            int restaurantId => RestaurantDetailsPage.fromId(
              restaurantId: restaurantId,
            ),
            _ => throw FlutterError(
              'The restaurant details route requires a Restaurant, '
              'RestaurantDetailsDto, or int ID.',
            ),
          },
          settings: settings,
        );
      case AppRouteNames.restaurantReviews:
        final reviewsArgument = settings.arguments;
        if (reviewsArgument is! Restaurant &&
            reviewsArgument is! RestaurantReviewsData) {
          throw FlutterError(
            'The restaurant reviews route requires Restaurant or '
            'RestaurantReviewsData.',
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => reviewsArgument is RestaurantReviewsData
              ? RestaurantReviewsPage.fromData(data: reviewsArgument)
              : RestaurantReviewsPage(
                  restaurant: reviewsArgument as Restaurant,
                ),
          settings: settings,
        );
      case AppRouteNames.wheel:
        return MaterialPageRoute<void>(
          builder: (_) => const WheelPage(),
          settings: settings,
        );
      case AppRouteNames.chooseRestaurant:
        return MaterialPageRoute<void>(
          builder: (_) => const ChooseRestaurantPage(),
          settings: settings,
        );
      default:
        throw FlutterError('No route is defined for ${settings.name}.');
    }
  }
}
