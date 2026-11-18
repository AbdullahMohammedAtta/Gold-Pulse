import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/lay_out/view/lay_out_screen.dart';
import 'package:gold/features/lay_out/view_model/lay_out_cubit.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => LayOutCubit(),
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aurum Gold',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121215),
          primaryColor: const Color(0xFFFFD700),
        ),
        home: LayOutScreen(),
      ),
    );
  }
}


