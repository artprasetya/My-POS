import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Events ───
abstract class LocaleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocaleChanged extends LocaleEvent {
  final Locale locale;
  LocaleChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}

class LocaleLoadRequested extends LocaleEvent {}

// ─── State ───
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState(this.locale);

  @override
  List<Object?> get props => [locale];
}

// ─── Bloc ───
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'selected_locale';

  LocaleBloc() : super(const LocaleState(Locale('en'))) {
    on<LocaleLoadRequested>(_onLoad);
    on<LocaleChanged>(_onChange);
  }

  Future<void> _onLoad(LocaleLoadRequested event, Emitter<LocaleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      emit(LocaleState(Locale(languageCode)));
    }
  }

  Future<void> _onChange(LocaleChanged event, Emitter<LocaleState> emit) async {
    emit(LocaleState(event.locale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, event.locale.languageCode);
  }
}
