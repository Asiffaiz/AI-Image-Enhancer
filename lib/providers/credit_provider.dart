import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

// Events
abstract class CreditEvent extends Equatable {
  const CreditEvent();

  @override
  List<Object> get props => [];
}

class CheckCreditsEvent extends CreditEvent {}

class UseCreditsEvent extends CreditEvent {}

class ResetCreditsEvent extends CreditEvent {}

// States
abstract class CreditState extends Equatable {
  const CreditState();

  @override
  List<Object> get props => [];
}

class CreditInitial extends CreditState {}

class CreditLoading extends CreditState {}

class CreditAvailable extends CreditState {
  final int remainingCredits;

  const CreditAvailable(this.remainingCredits);

  @override
  List<Object> get props => [remainingCredits];
}

class CreditExhausted extends CreditState {}

class CreditError extends CreditState {
  final String message;

  const CreditError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class CreditBloc extends Bloc<CreditEvent, CreditState> {
  CreditBloc() : super(CreditInitial()) {
    on<CheckCreditsEvent>(_checkCredits);
    on<UseCreditsEvent>(_useCredits);
    on<ResetCreditsEvent>(_resetCredits);
  }

  Future<void> _checkCredits(
    CheckCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final int dailyCount = await _getDailyCount(prefs);
      final int remainingCredits = AppConstants.freeCreditsPerDay - dailyCount;

      if (remainingCredits > 0) {
        emit(CreditAvailable(remainingCredits));
      } else {
        emit(CreditExhausted());
      }
    } catch (e) {
      debugPrint('Error checking credits: ${e.toString()}');
      emit(const CreditError('Failed to check credits'));
    }
  }

  Future<void> _useCredits(
    UseCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final int dailyCount = await _getDailyCount(prefs);

      if (dailyCount < AppConstants.freeCreditsPerDay) {
        await prefs.setInt(AppConstants.dailyCountKey, dailyCount + 1);
        final int remainingCredits =
            AppConstants.freeCreditsPerDay - (dailyCount + 1);

        if (remainingCredits > 0) {
          emit(CreditAvailable(remainingCredits));
        } else {
          emit(CreditExhausted());
        }
      } else {
        emit(CreditExhausted());
      }
    } catch (e) {
      debugPrint('Error using credits: ${e.toString()}');
      emit(const CreditError('Failed to use credits'));
    }
  }

  Future<void> _resetCredits(
    ResetCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.dailyCountKey, 0);
      await prefs.setString(AppConstants.lastDateKey, _getTodayDate());

      emit(CreditAvailable(AppConstants.freeCreditsPerDay));
    } catch (e) {
      debugPrint('Error resetting credits: ${e.toString()}');
      emit(const CreditError('Failed to reset credits'));
    }
  }

  // Helper methods
  Future<int> _getDailyCount(SharedPreferences prefs) async {
    final String lastDate = prefs.getString(AppConstants.lastDateKey) ?? '';
    final String todayDate = _getTodayDate();

    // Reset counter if it's a new day
    if (lastDate != todayDate) {
      await prefs.setInt(AppConstants.dailyCountKey, 0);
      await prefs.setString(AppConstants.lastDateKey, todayDate);
      return 0;
    }

    return prefs.getInt(AppConstants.dailyCountKey) ?? 0;
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
