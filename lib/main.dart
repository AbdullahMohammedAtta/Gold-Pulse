import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/BlocObserver.dart';
import 'package:gold/core/services/gold_service.dart';
import 'package:gold/features/lay_out/view/lay_out_screen.dart';
import 'package:gold/features/lay_out/view_model/lay_out_cubit.dart';

// عدّل مسارات الاستيراد أدناه حسب أماكن الملفات الحقيقية في مشروعك
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = MyBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LayOutCubit>(
          create: (context) => LayOutCubit(),
        ),
        BlocProvider<GoldCubit>(
          create: (context) =>
          GoldCubit(GoldService())..fetchGoldPrices(currency: 'ُEGP'),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aurum Gold',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121215),
          primaryColor: const Color(0xFFFFD700),
        ),
        home: const LayOutScreen(),
      ),
    );
  }
}