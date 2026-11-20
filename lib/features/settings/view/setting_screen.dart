import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/settings/view_model/settings_cubit.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final bool isAr = settings.isArabic;
    final bool isDark = settings.isDark;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. إعداد اللغة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      isAr ? 'لغة التطبيق' : 'App Language',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OptionTile(
                        title: 'العربية',
                        subtitle: 'Arabic',
                        isSelected: isAr,
                        accent: accent,
                        customBadge: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isAr ? accent.withOpacity(0.16) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isAr ? accent : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            'ع',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isAr ? accent : Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                        onTap: () {
                          context.read<SettingsCubit>().changeLanguage('ar');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OptionTile(
                        title: 'English',
                        subtitle: 'الإنجليزية',
                        icon: Icons.abc,
                        isSelected: !isAr,
                        accent: accent,
                        onTap: () {
                          context.read<SettingsCubit>().changeLanguage('en');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. إعداد المظهر (Dark / Light)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAr ? 'مظهر التطبيق' : 'App Theme',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OptionTile(
                        title: isAr ? 'ليلي' : 'Dark',
                        subtitle: isAr ? 'وضع داكن' : 'Dark Mode',
                        icon: Icons.dark_mode_outlined,
                        isSelected: isDark,
                        accent: accent,
                        onTap: () {
                          context
                              .read<SettingsCubit>()
                              .changeThemeMode(ThemeMode.dark);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OptionTile(
                        title: isAr ? 'نهاري' : 'Light',
                        subtitle: isAr ? 'وضع فاتح' : 'Light Mode',
                        icon: Icons.light_mode_outlined,
                        isSelected: !isDark,
                        accent: accent,
                        onTap: () {
                          context
                              .read<SettingsCubit>()
                              .changeThemeMode(ThemeMode.light);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? customBadge;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.customBadge,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  }) : assert(icon != null || customBadge != null,
  'Provide either icon or customBadge');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            customBadge ??
                Icon(
                  icon!,
                  size: 20,
                  color:
                  isSelected ? accent : Theme.of(context).iconTheme.color,
                ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? accent : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}