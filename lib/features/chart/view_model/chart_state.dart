// lib/features/chart/view_model/chart_state.dart
import 'package:gold/features/chart/model/gold_bar_model.dart';

enum ChartRange { week, month, quarter }

abstract class ChartState {}

class ChartInitial extends ChartState {}

class ChartLoading extends ChartState {}

class ChartLoaded extends ChartState {
  final List<GoldBarModel> bars;
  final ChartRange range;
  final String currency;
  final double periodHigh;
  final double periodLow;
  final double changePercent;

  ChartLoaded({
    required this.bars,
    required this.range,
    required this.currency,
    required this.periodHigh,
    required this.periodLow,
    required this.changePercent,
  });
}

class ChartError extends ChartState {
  final String message;

  ChartError(this.message);
}