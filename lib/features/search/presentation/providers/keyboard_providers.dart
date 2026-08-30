import 'package:flutter_riverpod/flutter_riverpod.dart';

enum KeyboardType { punjabi, english }

class KeyboardTypeNotifier extends Notifier<KeyboardType> {
  @override
  KeyboardType build() => KeyboardType.punjabi;
  
  void setType(KeyboardType type) {
    if (state != type) {
      state = type;
      // Clear query when switching keyboards
      ref.read(searchQueryProvider.notifier).setQuery('');
    }
  }
}

final keyboardTypeProvider = NotifierProvider<KeyboardTypeNotifier, KeyboardType>(() => KeyboardTypeNotifier());

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void setQuery(String query) => state = query;
  void append(String char) => state = state + char;
  void delete() {
    if (state.isNotEmpty) {
      state = state.substring(0, state.length - 1);
    }
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

class CustomKeyboardVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  
  void setVisible(bool visible) => state = visible;
  void toggle() => state = !state;
}

final customKeyboardVisibleProvider = NotifierProvider<CustomKeyboardVisibilityNotifier, bool>(() => CustomKeyboardVisibilityNotifier());
