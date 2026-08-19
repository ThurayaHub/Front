import 'package:flutter/material.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/features/home/presentation/home_page.dart';
import 'package:thuraya/features/restaurant_details/presentation/restaurant_details_page.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/restaurant_reviews_page.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/placeholders/presentation/navigation_placeholder_page.dart';
import 'package:thuraya/features/trending/presentation/trending_page.dart';
import 'package:thuraya/features/wheel/presentation/wheel_page.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case AppRouteNames.account:
        return MaterialPageRoute<void>(
          builder: (context) => NavigationPlaceholderPage(
            title: AppLocalizations.of(context).account,
            selectedTab: ThurayaNavigationTab.account,
          ),
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
            int restaurantId => RestaurantDetailsPage.fromId(
              restaurantId: restaurantId,
            ),
            _ => throw FlutterError(
              'The restaurant details route requires a Restaurant or int ID.',
            ),
          },
          settings: settings,
        );
      case AppRouteNames.restaurantReviews:
        final restaurant = settings.arguments;
        if (restaurant is! Restaurant) {
          throw FlutterError(
            'The restaurant reviews route requires a Restaurant argument.',
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => RestaurantReviewsPage(restaurant: restaurant),
          settings: settings,
        );
      case AppRouteNames.wheel:
        return MaterialPageRoute<void>(
          builder: (_) => const WheelPage(),
          settings: settings,
        );
      case AppRouteNames.chooseRestaurant:
        return MaterialPageRoute<void>(
          builder: (context) => NavigationPlaceholderPage(
            title: AppLocalizations.of(context).chooseRestaurant,
            selectedTab: ThurayaNavigationTab.chooseRestaurant,
          ),
          settings: settings,
        );
      default:
        throw FlutterError('No route is defined for ${settings.name}.');
    }
  }
}
