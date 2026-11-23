import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/lay_out/view_model/lay_out_cubit.dart';
import 'package:gold/features/lay_out/view_model/lay_out_states.dart';

class LayOutScreen extends StatelessWidget {
  const LayOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layOutCubit = LayOutCubit.get(context);
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
    isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color elevatedColor =
    isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final Color primaryText =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color secondaryText =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color borderColor =
    isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final Color accentColor = isDark ? AppColors.goldDark : AppColors.goldLight;

    return BlocConsumer<LayOutCubit, LayOutStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            foregroundColor: primaryText,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 14,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: accentColor,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Aurum',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'مباشر' : 'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: layOutCubit.screens[layOutCubit.screensIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.8),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: layOutCubit.screensIndex,
              onTap: (value) {
                layOutCubit.changeScreen(value);
              },
              backgroundColor: surfaceColor,
              selectedItemColor: accentColor,
              unselectedItemColor: secondaryText,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: isAr ? 'الرئيسية' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.show_chart_outlined),
                  activeIcon: const Icon(Icons.show_chart),
                  label: isAr ? 'المؤشر' : 'Chart',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: const Icon(Icons.account_balance_wallet),
                  label: isAr ? 'المحفظة' : 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: isAr ? 'الإعدادات' : 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}