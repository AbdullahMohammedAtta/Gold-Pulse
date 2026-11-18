import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/gold_market/view/chart_screen.dart';
import 'package:gold/features/gold_market/view/home_screen.dart';
import 'package:gold/features/lay_out/view_model/lay_out_states.dart';
import 'package:gold/features/portfolio/view/portfolio_screen.dart';
import 'package:gold/features/settings/view/setting_screen.dart';
import 'package:material_ui/material_ui.dart' show Widget;

class LayOutCubit extends Cubit<LayOutStates>{
  LayOutCubit() : super(LayOutInitialState()); // بدون باراميترات


  // ignore: strict_top_level_inference
  static LayOutCubit get(context) => BlocProvider.of(context);

    int screensIndex = 0;
    List<Widget> screens =[
      HomeScreen(),
      ChartScreen(),
      PortfolioScreen(),
      SettingScreen(),
    ];

    // ignore: strict_top_level_inference
    void changeScreen(index)
    {
      screensIndex = index;
      emit(ChangeScreenLayOutState());
    }
}