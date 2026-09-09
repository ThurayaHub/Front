import 'package:flutter/material.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';

class ThurayaStartupScreen extends StatelessWidget {
  const ThurayaStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: ValueKey('thuraya-startup-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(child: Center(child: ThurayaLoadingIndicator(size: 176))),
    );
  }
}
