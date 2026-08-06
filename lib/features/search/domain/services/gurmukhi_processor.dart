import 'package:characters/characters.dart';

abstract final class GurmukhiProcessor {
  static const Map<int, String> _unicodeToAscii = {
    0x0A05: 'A', 0x0A06: 'Aw', 0x0A07: 'ie', 0x0A08: 'eI', 0x0A09: 'au', 0x0A0A: 'aU',
    0x0A0F: 'ey', 0x0A10: 'AY', 0x0A13: 'E', 0x0A14: 'AO', 0x0A15: 'k', 0x0A16: 'K',
    0x0A17: 'g', 0x0A18: 'G', 0x0A19: '|', 0x0A1A: 'c', 0x0A1B: 'C', 0x0A1C: 'j',
    0x0A1D: 'J', 0x0A1E: '\\', 0x0A1F: 't', 0x0A20: 'T', 0x0A21: 'f', 0x0A22: 'F',
    0x0A23: 'x', 0x0A24: 'q', 0x0A25: 'Q', 0x0A26: 'd', 0x0A27: 'D', 0x0A28: 'n',
    0x0A2A: 'p', 0x0A2B: 'P', 0x0A2C: 'b', 0x0A2D: 'B', 0x0A2E: 'm', 0x0A2F: 'X',
    0x0A30: 'r', 0x0A32: 'l', 0x0A35: 'v', 0x0A38: 's', 0x0A39: 'h', 0x0A5B: 'z',
    0x0A5C: 'V', 0x0A72: 'e', 0x0A73: 'a', 0x0A74: '1',
  };

  static const Map<String, String> _romanToGurbaniAkhar = {
    'a': 'A', 'b': 'b', 'c': 'c', 'd': 'd', 'e': 'e', 'f': 'f', 'g': 'g', 'h': 'h',
    'i': 'i', 'j': 'j', 'k': 'k', 'l': 'l', 'm': 'm', 'n': 'n', 'o': 'E', 'p': 'p',
    'q': 'q', 'r': 'r', 's': 's', 't': 'q', 'u': 'a', 'v': 'v', 'w': 'v', 'x': 'x',
    'y': 'X', 'z': 'z',
  };

  static String generateFirstLetterStr(String unicode) {
    if (unicode.isEmpty) return '';
    final codes = <String>[];
    for (final word in unicode.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final ascii = _unicodeToAscii[word.characters.first.runes.first];
      if (ascii != null) {
        final code = ascii[0].codeUnitAt(0);
        codes.add(code < 100 ? '0$code' : code.toString());
      }
    }
    return codes.isEmpty ? '' : ',${codes.join(',')}';
  }

  static String queryToFirstLetterStr(String query) {
    if (query.isEmpty) return '';
    final codes = <String>[];
    final q = query.toLowerCase();
    
    int i = 0;
    while (i < q.length) {
      String? mapped;
      // Look ahead for pairs (kh, gh, etc)
      if (i + 1 < q.length) {
        final pair = q.substring(i, i + 2);
        if (pair == 'kh') mapped = 'K';
        else if (pair == 'gh') mapped = 'G';
        else if (pair == 'ch') mapped = 'C';
        else if (pair == 'jh') mapped = 'J';
        else if (pair == 'th') mapped = 'Q';
        else if (pair == 'dh') mapped = 'D';
        else if (pair == 'ph') mapped = 'P';
        else if (pair == 'bh') mapped = 'B';
        else if (pair == 'sh') mapped = 'S';
        
        if (mapped != null) {
          i += 2;
        }
      }
      
      if (mapped == null) {
        final char = q[i];
        final rune = char.runes.first;
        if (rune >= 0x61 && rune <= 0x7A) {
          mapped = _romanToGurbaniAkhar[char];
        } else {
          mapped = _unicodeToAscii[rune];
        }
        i++;
      }

      if (mapped != null) {
        final code = mapped.codeUnitAt(0);
        codes.add(code < 100 ? '0$code' : code.toString());
      }
    }
    return codes.isEmpty ? '' : ',${codes.join(',')}';
  }
}
