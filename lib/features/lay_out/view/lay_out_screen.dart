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
    final Color accentIconColor = isDark ? Colors.black : Colors.white;

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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.flash_on,
                        color: accentIconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: elevatedColor,
                      backgroundImage: const NetworkImage(
                        'https://i.imgur.com/BoN9kdC.png',
                      ),
                    ),
                  ],
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