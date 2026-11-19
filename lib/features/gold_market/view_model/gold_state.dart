import 'package:gold/features/gold_market/model/gold_price_model.dart';

abstract class GoldState {const GoldState();}

class GoldInitial extends GoldState {const GoldInitial();}

class GoldLoading extends GoldState {
  final GoldPriceModel? previousData;
  const GoldLoading({this.previousData});
}

class GoldLoaded extends GoldState {
  final GoldPriceModel goldData;
  final String selectedCurrency;
  final bool isRefreshing;

  const GoldLoaded({
    required this.goldData,
    required this.selectedCurrency,
    this.isRefreshing = false,
  });
}

class GoldError extends GoldState {
  final String message;
  final GoldPriceModel? previousData;

  const GoldError({
    required this.message,
    this.previousData,
  });
}