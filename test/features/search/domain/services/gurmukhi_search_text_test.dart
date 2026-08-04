import 'package:flutter_test/flutter_test.dart';
import 'package:gurbani_voice_search/features/search/domain/models/punjabi_search_query.dart';
import 'package:gurbani_voice_search/features/search/domain/services/gurmukhi_search_text.dart';

void main() {
  group('GurmukhiSearchText', () {
    test('parseQuery identifies Roman initials', () {
      final query = GurmukhiSearchText.parseQuery('sssg');
      expect(query.kind, PunjabiSearchKind.romanInitial);
    });

    test('parseQuery identifies Roman word', () {
      final query = GurmukhiSearchText.parseQuery('saas');
      expect(query.kind, PunjabiSearchKind.romanInitial); // Single word > 1 char is romanInitial for now
    });

    test('parseQuery handles ੴਸ', () {
      final query = GurmukhiSearchText.parseQuery('ੴਸ');
      expect(query.initialKey, 'ੳਸ');
    });

    test('parseQuery handles ਗਮਕਦ', () {
      final query = GurmukhiSearchText.parseQuery('ਗਮਕਦ');
      expect(query.kind, PunjabiSearchKind.gurmukhiAmbiguous);
      // Verify no 'unsupported' error shows up
      expect(query.isSearchable, isTrue);
    });

    test('parseQuery handles hidden characters', () {
      // Input with a Zero Width Space (common in some keyboards)
      final query = GurmukhiSearchText.parseQuery('ਸਸਸਗ\u200B');
      expect(query.kind, PunjabiSearchKind.gurmukhiAmbiguous);
      expect(query.isSearchable, isTrue);
    });
  });
}
