import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gold/core/Theme/dark_theme.dart';
import 'package:gold/core/Theme/light_theme.dart';
import 'package:gold/core/services/gold_service.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/lay_out/view/lay_out_screen.dart';
import 'package:gold/features/lay_out/view_model/lay_out_cubit.dart';
import 'package:gold/features/settings/view_model/setting_states.dart';
import 'package:gold/features/settings/view_model/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SettingsState initialSettings = await SettingsCubit.loadSavedSettings();

  runApp(
    MyApp(initialSettings: initialSettings),
  );
}

class MyApp extends StatelessWidget {
  final SettingsState initialSettings;

  const MyApp({
    super.key,
    required this.initialSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(
            initialLocale: initialSettings.locale,
            initialThemeMode: initialSettings.themeMode,
          ),),
        BlocProvider<LayOutCubit>(
          create: (_) => LayOutCubit(),
        ),
        BlocProvider<GoldCubit>(
          create: (_) => GoldCubit(GoldService())
            ..fetchGoldPrices(currency: 'EGP'),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: settings.locale,
            themeMode: settings.themeMode,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            home: const LayOutScreen(),
          );
        },
      ),
    );
  }
}