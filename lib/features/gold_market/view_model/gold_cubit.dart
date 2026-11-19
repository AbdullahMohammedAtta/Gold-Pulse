import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/gold_service.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';

import 'gold_state.dart';

class GoldCubit extends Cubit<GoldState> {
  final GoldService _goldService;
  String _currentCurrency = 'EGP';

  GoldCubit(this._goldService) : super(const GoldInitial());

  String get currentCurrency => _currentCurrency;

  /// جلب الأسعار (عند الفتح أو تغيير العملة أو التحديث اليدوي)
  Future<void> fetchGoldPrices({String? currency, bool forceRefresh = false,
  }) async {
    if (currency != null && currency.trim().isNotEmpty) {
      _currentCurrency = currency.trim().toUpperCase();
    }

    final GoldPriceModel? currentData = _extractCurrentModel();

    if (currentData != null) {
      emit(
        GetGoldSuccess(
          goldData: currentData,
          selectedCurrency: _currentCurrency,
          isRefreshing: true,
        ),
      );
    } else {
      emit(const GetGoldLoading());
    }

    try {
      final GoldPriceModel result = await _goldService.getGoldPrices(
        currency: _currentCurrency,
        forceRefresh: forceRefresh,
      );

      emit(
        GetGoldSuccess(
          goldData: result,
          selectedCurrency: _currentCurrency,
          isRefreshing: false,
        ),
      );
      print(result.priceGram24k);
    } catch (e) {
      final String cleanMessage =
      e.toString().replaceFirst('Exception: ', '').trim();

      if (currentData != null) {
        emit(
          GetGoldSuccess(
            goldData: currentData,
            selectedCurrency: _currentCurrency,
            isRefreshing: false,
          ),
        );
      }

      emit(
        GetGoldError(
          message: cleanMessage.isEmpty
              ? 'حدث خطأ أثناء جلب أسعار الذهب'
              : cleanMessage,
          previousData: currentData,
        ),
      );
    }
  }

  /// تغيير العملة المختارة من الـ Chips في HomeScreen
  Future<void> changeCurrency(String newCurrency) async {
    final String normalized = newCurrency.trim().toUpperCase();
    if (normalized == _currentCurrency && state is GetGoldSuccess) return;
    await fetchGoldPrices(currency: normalized, forceRefresh: false);
  }

  /// تحديث إجباري (مثلاً عند Pull-to-Refresh أو زر تحديث)
  Future<void> refreshPrices() async {
    await fetchGoldPrices(currency: _currentCurrency, forceRefresh: true);
  }

  GoldPriceModel? _extractCurrentModel() {
    final currentState = state;
    if (currentState is GetGoldSuccess) return currentState.goldData;
    if (currentState is GetGoldLoading) return currentState.previousData;
    if (currentState is GetGoldError) return currentState.previousData;
    return null;
  }
}