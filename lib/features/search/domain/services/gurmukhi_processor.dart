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
    0x0A5C: 'V', 0x0A72: 'e', 0x0A73: 'a', 0x0A74: '1', 0x0A71: 'S',
  };

  static const Map<String, String> _romanToGurbaniAkhar = {
    'a': 'A', 'A': 'A',
    'b': 'b', 'B': 'B',
    'c': 'c', 'C': 'C',
    'd': 'd', 'D': 'D',
    'e': 'e', 'E': 'E',
    'f': 'f', 'F': 'F',
    'g': 'g', 'G': 'G',
    'h': 'h', 'H': 'h',
    'i': 'i', 'I': 'I',
    'j': 'j', 'J': 'J',
    'k': 'k', 'K': 'K',
    'l': 'l', 'L': 'l',
    'm': 'm', 'M': 'm',
    'n': 'n', 'N': 'n',
    'o': 'E', 'O': 'E',
    'p': 'p', 'P': 'P',
    'q': 'q', 'Q': 'Q',
    'r': 'r', 'R': 'r',
    's': 's', 'S': 'S',
    't': 'q', 'T': 'T',
    'u': 'a', 'U': 'a',
    'v': 'v', 'V': 'V',
    'w': 'v', 'W': 'v',
    'x': 'x', 'X': 'X',
    'y': 'X', 'Y': 'X',
    'z': 'z', 'Z': 'z',
  };

  static int cleanGurmukhiRune(int rune) {
    switch (rune) {
      // ੲ (Iri) Family: ਇ (0x0A07), ਈ (0x0A08), ਏ (0x0A0F) -> ੲ (0x0A72)
      case 0x0A07:
      case 0x0A08:
      case 0x0A0F:
      case 0x0A72:
        return 0x0A72;

      // ੳ (Oura) Family: ਉ (0x0A09), ਊ (0x0A0A), ਓ (0x0A13) -> ੳ (0x0A73)
      case 0x0A09:
      case 0x0A0A:
      case 0x0A13:
      case 0x0A73:
        return 0x0A73;

      // ਅ (Aira) Family: ਅ (0x0A05), ਆ (0x0A06), ਐ (0x0A10), ਔ (0x0A14) -> ਅ (0x0A05)
      case 0x0A05:
      case 0x0A06:
      case 0x0A10:
      case 0x0A14:
        return 0x0A05;

      // Pairin Bindi (Nukta) Consonants -> Base 35 Akhar
      case 0x0A33: return 0x0A32; // ਲ਼ -> ਲ
      case 0x0A59: return 0x0A16; // ਖ਼ -> ਖ
      case 0x0A5A: return 0x0A17; // ਗ਼ -> ਗ
      case 0x0A5B: return 0x0A1C; // ਜ਼ -> ਜ
      case 0x0A5E: return 0x0A2B; // ਫ਼ -> ਫ

      default:
        return rune;
    }
  }

  static String extractEnglishInitials(String unicode) {
    if (unicode.isEmpty) return '';
    final res = StringBuffer();
    for (final word in unicode.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final firstChar = word.characters.first;
      final ascii = _unicodeToAscii[firstChar.runes.first];
      if (ascii != null) res.write(ascii[0].toLowerCase());
    }
    return res.toString();
  }

  static String extractPunjabiInitials(String unicode) {
    if (unicode.isEmpty) return '';
    final res = StringBuffer();
    final words = unicode.trim().split(RegExp(r'\s+'));

    // Multi-word scripture sentence -> take first letter of each word
    if (words.length > 1) {
      for (final word in words) {
        if (word.isEmpty) continue;
        final cleanWord = word.replaceAll(RegExp(r'[^\u0A01-\u0A75]'), '');
        if (cleanWord.isEmpty) continue;

        final rune = cleanWord.runes.first;
        final baseRune = cleanGurmukhiRune(rune);
        res.writeCharCode(baseRune);
      }
      return res.toString();
    }

    // Single word / typed initial query -> process every character in query
    final cleanQuery = unicode.replaceAll(RegExp(r'[^\u0A01-\u0A75]'), '');
    for (final rune in cleanQuery.runes) {
      // Ignore combining matras typed as standalone initials
      if ((rune >= 0x0A3E && rune <= 0x0A4C) || rune == 0x0A70 || rune == 0x0A71 || rune == 0x0A02 || rune == 0x0A3C) {
        continue;
      }
      final baseRune = cleanGurmukhiRune(rune);
      res.writeCharCode(baseRune);
    }
    return res.toString();
  }

  static String queryToFirstLetterStr(String query) {
    if (query.isEmpty) return '';
    String charCodeQuery = '';
    
    // Exact BaniDB API Logic:
    // 1. Ignore all spaces
    String q = query.replaceAll(RegExp(r'\s+'), '');
    
    // 2. Convert unicode to ascii (Handled by our Roman mapping + table)
    // 3. Iterate and pad with commas
    const operators = {43, 45, 42, 34, 39}; // +, -, *, ", '
    
    for (int i = 0; i < q.length; i++) {
      final char = q[i];
      final charCode = char.codeUnitAt(0);
      
      if (operators.contains(charCode)) {
        charCodeQuery += char;
      } else {
        String? mapped;
        final rune = char.runes.first;
        if ((rune >= 0x61 && rune <= 0x7A) || (rune >= 0x41 && rune <= 0x5A)) {
          mapped = _romanToGurbaniAkhar[char];
        } else {
          mapped = _unicodeToAscii[rune];
        }
        
        if (mapped != null) {
          int code = mapped.codeUnitAt(0);
          String formatted = code < 100 ? '0$code' : code.toString();
          charCodeQuery += ',$formatted';
        }
      }
    }
    return charCodeQuery;
  }

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

  static List<String> generatePhoneticVariations(String input) {
    const mapping = {
      'i': ['e'], 'e': ['i'],
      'u': ['o'], 'o': ['u', 'a'],
      'a': ['o'], 'v': ['w'], 'w': ['v'], 'z': ['j'],
      's': ['S'], 'S': ['s'],
      'k': ['K'], 'K': ['k'],
      'g': ['G'], 'G': ['g'],
      'c': ['C'], 'C': ['c'],
      'j': ['J', 'z'], 'J': ['j'],
      't': ['T', 'q', 'Q'],
      'q': ['Q', 't'],
      'd': ['D'], 'D': ['d'],
      'p': ['P'], 'P': ['p'],
      'b': ['B'], 'B': ['b'],
    };
    var variations = <String>{input.toLowerCase()};
    final rawInput = input.toLowerCase();
    final limit = rawInput.length > 6 ? 6 : rawInput.length;
    for (int i = 0; i < limit; i++) {
      final char = rawInput[i];
      if (mapping.containsKey(char)) {
        final newVariations = <String>{};
        for (final variant in variations) {
          for (final substitution in mapping[char]!) {
            final variantChars = variant.split('');
            variantChars[i] = substitution;
            newVariations.add(variantChars.join(''));
          }
        }
        variations.addAll(newVariations);
        if (variations.length > 64) break; 
      }
    }
    return variations.toList();
  }
}
