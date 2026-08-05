import 'package:characters/characters.dart';

/// The core intelligence of the Gurbani Search Engine.
abstract final class GurmukhiProcessor {
  /// Maps Unicode Gurmukhi characters to Gurbani Akhar ASCII.
  static const Map<int, String> _unicodeToAscii = {
    0x0A05: 'A', // ਅ
    0x0A06: 'Aw', // ਆ
    0x0A07: 'ie', // ਇ
    0x0A08: 'eI', // ਈ
    0x0A09: 'au', // ਉ
    0x0A0A: 'aU', // ਊ
    0x0A0F: 'ey', // ਏ
    0x0A10: 'AY', // ਐ
    0x0A13: 'E', // ਓ
    0x0A14: 'AO', // ਔ
    0x0A15: 'k', // ਕ
    0x0A16: 'K', // ਖ
    0x0A17: 'g', // ਗ
    0x0A18: 'G', // ਘ
    0x0A19: '|', // ਙ
    0x0A1A: 'c', // ਚ
    0x0A1B: 'C', // ਛ
    0x0A1C: 'j', // ਜ
    0x0A1D: 'J', // ਝ
    0x0A1E: '\\', // ਞ
    0x0A1F: 't', // ਟ
    0x0A20: 'T', // ਠ
    0x0A21: 'f', // ਡ
    0x0A22: 'F', // ਢ
    0x0A23: 'x', // ਣ
    0x0A24: 'q', // ਤ
    0x0A25: 'Q', // ਥ
    0x0A26: 'd', // ਦ
    0x0A27: 'D', // ਧ
    0x0A28: 'n', // ਨ
    0x0A2A: 'p', // ਪ
    0x0A2B: 'P', // ਫ
    0x0A2C: 'b', // ਬ
    0x0A2D: 'B', // ਭ
    0x0A2E: 'm', // ਮ
    0x0A2F: 'X', // ਯ
    0x0A30: 'r', // ਰ
    0x0A32: 'l', // ਲ
    0x0A35: 'v', // ਵ
    0x0A38: 's', // ਸ
    0x0A39: 'h', // ਹ
    0x0A5B: 'z', // ਜ਼
    0x0A5C: 'V', // ੜ
    0x0A72: 'e', // ੲ
    0x0A73: 'a', // ੳ
    0x0A74: '1', // ੴ
  };

  /// Maps Roman keys (user input) to Gurbani Akhar ASCII first letters.
  static const Map<String, String> _romanToGurbaniAkhar = {
    'a': 'A', // Maps to ਅ or ਆ (A)
    'b': 'b',
    'c': 'c',
    'd': 'd',
    'e': 'e',
    'f': 'f',
    'g': 'g',
    'h': 'h',
    'i': 'i', // Maps to ਇ (ie)
    'j': 'j',
    'k': 'k',
    'l': 'l',
    'm': 'm',
    'n': 'n',
    'o': 'E', // Maps to ਓ (E)
    'p': 'p',
    'q': 'q',
    'r': 'r',
    's': 's',
    't': 'q', // Maps to ਤ (q)
    'u': 'a', // Maps to ਉ (au)
    'v': 'v',
    'w': 'v',
    'x': 'x',
    'y': 'X',
    'z': 'z',
  };

  /// Generates the 'FirstLetterStr' index used in production BaniDB search.
  static String generateFirstLetterStr(String unicode) {
    if (unicode.isEmpty) return '';
    final codes = <String>[];
    final words = unicode.trim().split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.isEmpty) continue;
      final firstGrapheme = word.characters.first;
      final rune = firstGrapheme.runes.first;
      final ascii = _unicodeToAscii[rune];
      if (ascii != null) {
        final decimalCode = ascii[0].codeUnitAt(0);
        codes.add(decimalCode < 100 ? '0$decimalCode' : decimalCode.toString());
      }
    }
    return codes.isEmpty ? '' : ',${codes.join(',')}';
  }

  /// Generates the search code sequence for a user query.
  static String queryToFirstLetterStr(String query) {
    if (query.isEmpty) return '';
    final codes = <String>[];
    
    for (final char in query.toLowerCase().characters) {
      final rune = char.runes.first;
      
      // Case 1: Roman letter input
      if (rune >= 0x61 && rune <= 0x7A) {
        final mapped = _romanToGurbaniAkhar[char];
        if (mapped != null) {
           final decimalCode = mapped.codeUnitAt(0);
           codes.add(decimalCode < 100 ? '0$decimalCode' : decimalCode.toString());
        }
        continue;
      }

      // Case 2: Gurmukhi character input
      final ascii = _unicodeToAscii[rune];
      if (ascii != null) {
        final decimalCode = ascii[0].codeUnitAt(0);
        codes.add(decimalCode < 100 ? '0$decimalCode' : decimalCode.toString());
      }
    }
    return codes.isEmpty ? '' : ',${codes.join(',')}';
  }
}
