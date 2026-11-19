import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/gold_service.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';

import 'gold_state.dart';

class GoldCubit extends Cubit<GoldState> {
  final GoldService _goldService;
  String _currentCurrency = 'USD';

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
        GoldLoaded(
          goldData: currentData,
          selectedCurrency: _currentCurrency,
          isRefreshing: true,
        ),
      );
    } else {
      emit(const GoldLoading());
    }

    try {
      final GoldPriceModel result = await _goldService.getGoldPrices(
        currency: _currentCurrency,
        forceRefresh: forceRefresh,
      );

      emit(
        GoldLoaded(
          goldData: result,
          selectedCurrency: _currentCurrency,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      final String cleanMessage =
      e.toString().replaceFirst('Exception: ', '').trim();

      if (currentData != null) {
        emit(
          GoldLoaded(
            goldData: currentData,
            selectedCurrency: _currentCurrency,
            isRefreshing: false,
          ),
        );
      }

      emit(
        GoldError(
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
    if (normalized == _currentCurrency && state is GoldLoaded) return;
    await fetchGoldPrices(currency: normalized, forceRefresh: false);
  }

  /// تحديث إجباري (مثلاً عند Pull-to-Refresh أو زر تحديث)
  Future<void> refreshPrices() async {
    await fetchGoldPrices(currency: _currentCurrency, forceRefresh: true);
  }

  GoldPriceModel? _extractCurrentModel() {
    final currentState = state;
    if (currentState is GoldLoaded) return currentState.goldData;
    if (currentState is GoldLoading) return currentState.previousData;
    if (currentState is GoldError) return currentState.previousData;
    return null;
  }
}