import 'package:gold/features/gold_market/model/gold_price_model.dart';

abstract class GoldState {const GoldState();}

class GoldInitial extends GoldState {const GoldInitial();}

class GetGoldLoading extends GoldState {
  final GoldPriceModel? previousData;
  const GetGoldLoading({this.previousData});
}

class GetGoldSuccess extends GoldState {
  final GoldPriceModel goldData;
  final String selectedCurrency;
  final bool isRefreshing;

  const GetGoldSuccess({
    required this.goldData,
    required this.selectedCurrency,
    this.isRefreshing = false,
  });
}

class GetGoldError extends GoldState {
  final String message;
  final GoldPriceModel? previousData;

  const GetGoldError({
    required this.message,
    this.previousData,
  });
}