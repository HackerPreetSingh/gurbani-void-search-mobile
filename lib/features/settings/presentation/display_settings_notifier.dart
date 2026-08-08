import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/settings_data_source.dart';
import '../domain/models/display_settings.dart';

class DisplaySettingsNotifier extends AsyncNotifier<DisplaySettings> {
  @override
  Future<DisplaySettings> build() async {
    return ref.watch(settingsDataSourceProvider).getDisplaySettings();
  }

  Future<void> updateSettings(DisplaySettings settings) async {
    state = AsyncData(settings);
    await ref.read(settingsDataSourceProvider).saveDisplaySettings(settings);
  }

  Future<void> toggleEnglishMeaning() async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(showEnglishMeaning: !current.showEnglishMeaning);
    await updateSettings(updated);
  }

  Future<void> togglePunjabiMeaning() async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(showPunjabiMeaning: !current.showPunjabiMeaning);
    await updateSettings(updated);
  }

  Future<void> toggleTransliteration() async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(showTransliteration: !current.showTransliteration);
    await updateSettings(updated);
  }

  Future<void> toggleHindi() async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(showHindi: !current.showHindi);
    await updateSettings(updated);
  }

  Future<void> toggleVishrams() async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(showVishrams: !current.showVishrams);
    await updateSettings(updated);
  }

  Future<void> updateFontSizeGurmukhi(double size) async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(fontSizeGurmukhi: size);
    await updateSettings(updated);
  }

  Future<void> updateFontSizeHindi(double size) async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(fontSizeHindi: size);
    await updateSettings(updated);
  }

  Future<void> updateFontSizeEnglish(double size) async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(fontSizeEnglish: size);
    await updateSettings(updated);
  }

  Future<void> updateFontSizeMeaning(double size) async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(fontSizeMeaning: size);
    await updateSettings(updated);
  }

  Future<void> updateFontSizePunjabiMeaning(double size) async {
    final current = state.value ?? DisplaySettings.defaults();
    final updated = current.copyWith(fontSizePunjabiMeaning: size);
    await updateSettings(updated);
  }
}

final displaySettingsProvider = AsyncNotifierProvider<DisplaySettingsNotifier, DisplaySettings>(() {
  return DisplaySettingsNotifier();
});
