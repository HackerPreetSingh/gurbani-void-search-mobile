import 'package:flutter_test/flutter_test.dart';
import 'package:gurbani_voice_search/features/search/domain/models/punjabi_search_query.dart';
import 'package:gurbani_voice_search/features/search/domain/services/gurmukhi_search_text.dart';

void main() {
  group('GurmukhiSearchText', () {
    test('initialsFromNormalizedTokens handles ੴ by folding to ੳ', () {
      final tokens = ['ੴ', 'ਸਤਿ'];
      final initials = GurmukhiSearchText.initialsFromNormalizedTokens(tokens);
      // 0x0A73 is ੳ
      expect(initials, '${String.fromCharCode(0x0A73)}ਸ');
    });

    test('parseQuery handles ੳਸ matching ੴਸ', () {
      final query = GurmukhiSearchText.parseQuery('ੳਸ');
      // Both should fold to the same initial key
      expect(query.initialKey, '${String.fromCharCode(0x0A73)}ਸ');
    });

    test('parseQuery handles ਜਪੁ', () {
      final query = GurmukhiSearchText.parseQuery('ਜਪੁ');
      expect(query.kind, PunjabiSearchKind.gurmukhiWord);
    });

    test('normalizedTokens handles marks correctly', () {
      final tokens = GurmukhiSearchText.normalizedTokens('ਸਤਿ');
      expect(tokens, ['ਸਤਿ']);
    });
  });
}
