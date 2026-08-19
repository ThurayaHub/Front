import 'package:flutter/material.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';

class NavigationPlaceholderPage extends StatelessWidget {
  const NavigationPlaceholderPage({
    super.key,
    required this.title,
    required this.selectedTab,
  });

  final String title;
  final ThurayaNavigationTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: ThurayaBottomNavigationBar(selectedTab: selectedTab),
      body: Center(
        child: Text(
          title,
          key: ValueKey('placeholder-${selectedTab.name}'),
          textAlign: TextAlign.center,
          style: AppTextStyles.screenTitle,
        ),
      ),
    );
  }
}
