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
  final bool isConvertedByCurrentFx;

  ChartLoaded({
    required this.bars,
    required this.range,
    required this.currency,
    required this.periodHigh,
    required this.periodLow,
    required this.changePercent,
    required this.isConvertedByCurrentFx,
  });
}

class ChartError extends ChartState {
  final String message;

  ChartError(this.message);
}