import '../models/punjabi_search_query.dart';

/// Canonicalises the Gurmukhi forms used by the local word and initial indexes.
///
/// The rules intentionally fold common vowel, bindi, and nukta variants while
/// retaining dependent vowel signs and addak, which can change a word's form.
abstract final class GurmukhiSearchText {
  static PunjabiSearchQuery parseQuery(String raw) {
    if (raw.trim().isEmpty) {
      return PunjabiSearchQuery(raw: raw, kind: PunjabiSearchKind.empty);
    }

    if (!_containsOnlySupportedQueryCharacters(raw)) {
      return PunjabiSearchQuery(raw: raw, kind: PunjabiSearchKind.unsupported);
    }

    final tokens = normalizedTokens(raw);
    if (tokens.isEmpty) {
      return PunjabiSearchQuery(raw: raw, kind: PunjabiSearchKind.unsupported);
    }

    final everyTokenIsOneBase = tokens.every(
      (String token) => _baseCharacterCount(token) == 1,
    );
    if (everyTokenIsOneBase && tokens.length > 1) {
      return PunjabiSearchQuery(
        raw: raw,
        kind: PunjabiSearchKind.gurmukhiInitial,
        wordTokens: tokens,
        initialKey: initialsFromNormalizedTokens(tokens),
      );
    }

    final singleUnmarkedMultiBaseToken =
        tokens.length == 1 &&
        _baseCharacterCount(tokens.single) > 1 &&
        !_containsDependentMark(raw);
    if (singleUnmarkedMultiBaseToken) {
      return PunjabiSearchQuery(
        raw: raw,
        kind: PunjabiSearchKind.gurmukhiAmbiguous,
        wordTokens: tokens,
        initialKey: _initialSequence(tokens.single),
      );
    }

    return PunjabiSearchQuery(
      raw: raw,
      kind: PunjabiSearchKind.gurmukhiWord,
      wordTokens: tokens,
      initialKey: initialsFromNormalizedTokens(tokens),
    );
  }

  static List<String> normalizedTokens(String value) {
    final rawTokens = <String>[];
    var token = StringBuffer();

    void flushToken() {
      if (token.isEmpty) {
        return;
      }
      final normalized = _normalizeToken(token.toString());
      if (normalized.isNotEmpty) {
        rawTokens.add(normalized);
      }
      token = StringBuffer();
    }

    for (final rune in value.runes) {
      if (_isGurmukhiWordRune(rune)) {
        token.writeCharCode(rune);
      } else {
        flushToken();
      }
    }
    flushToken();

    return List.unmodifiable(rawTokens);
  }

  static String initialsFromNormalizedTokens(Iterable<String> tokens) {
    final initials = StringBuffer();
    for (final token in tokens) {
      for (final rune in token.runes) {
        if (_isGurmukhiBase(rune)) {
          initials.writeCharCode(_foldBaseRune(rune));
          break;
        }
      }
    }
    return initials.toString();
  }

  static bool _containsOnlySupportedQueryCharacters(String value) {
    for (final rune in value.runes) {
      if (_isGurmukhiWordRune(rune) ||
          _isWhitespace(rune) ||
          _isPunctuation(rune)) {
        continue;
      }
      return false;
    }
    return true;
  }

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;

  static bool _isPunctuation(int rune) {
    return const <int>{
      0x21,
      0x27,
      0x28,
      0x29,
      0x2C,
      0x2D,
      0x2E,
      0x2F,
      0x3A,
      0x3B,
      0x3F,
      0x5B,
      0x5D,
      0x7B,
      0x7D,
      0x0A64,
      0x0A65,
    }.contains(rune);
  }

  static bool _isGurmukhiWordRune(int rune) {
    if (rune < 0x0A00 || rune > 0x0A7F) {
      return false;
    }
    return !_isGurmukhiDigit(rune) && !_isPunctuation(rune);
  }

  static bool _isGurmukhiDigit(int rune) => rune >= 0x0A66 && rune <= 0x0A6F;

  static bool _isGurmukhiBase(int rune) {
    return (rune >= 0x0A05 && rune <= 0x0A14) ||
        (rune >= 0x0A15 && rune <= 0x0A28) ||
        (rune >= 0x0A2A && rune <= 0x0A30) ||
        rune == 0x0A32 ||
        rune == 0x0A33 ||
        rune == 0x0A35 ||
        rune == 0x0A36 ||
        (rune >= 0x0A38 && rune <= 0x0A39) ||
        (rune >= 0x0A59 && rune <= 0x0A5F) ||
        rune == 0x0A72 ||
        rune == 0x0A73 ||
        rune == 0x0A74;
  }

  static bool _containsDependentMark(String value) {
    return value.runes.any(
      (int rune) =>
          rune == 0x0A3C ||
          (rune >= 0x0A3E && rune <= 0x0A42) ||
          (rune >= 0x0A47 && rune <= 0x0A48) ||
          (rune >= 0x0A4B && rune <= 0x0A4D) ||
          rune == 0x0A51 ||
          (rune >= 0x0A70 && rune <= 0x0A71) ||
          rune == 0x0A75,
    );
  }

  static int _baseCharacterCount(String token) {
    return token.runes.where(_isGurmukhiBase).length;
  }

  static String _initialSequence(String token) {
    final initials = StringBuffer();
    for (final rune in token.runes) {
      if (_isGurmukhiBase(rune)) {
        initials.writeCharCode(_foldBaseRune(rune));
      }
    }
    return initials.toString();
  }

  static String _normalizeToken(String token) {
    final normalized = StringBuffer();
    for (final rune in token.runes) {
      if (_isGurmukhiBase(rune)) {
        normalized.writeCharCode(_foldBaseRune(rune));
      } else if (_isRetainedMark(rune)) {
        normalized.writeCharCode(_foldMarkRune(rune));
      }
    }
    return normalized.toString();
  }

  static bool _isRetainedMark(int rune) {
    return rune == 0x0A01 ||
        rune == 0x0A02 ||
        rune == 0x0A3C ||
        (rune >= 0x0A3E && rune <= 0x0A42) ||
        (rune >= 0x0A47 && rune <= 0x0A48) ||
        (rune >= 0x0A4B && rune <= 0x0A4D) ||
        rune == 0x0A51 ||
        (rune >= 0x0A70 && rune <= 0x0A71) ||
        rune == 0x0A75;
  }

  static int _foldBaseRune(int rune) {
    // Fold all 'A' vowels to 'A' base (0x0A05)
    if (rune == 0x0A06 || rune == 0x0A10 || rune == 0x0A14) return 0x0A05;
    // Fold all 'U' vowels and Ik Onkar/One to 'U' base (0x0A73)
    if (rune == 0x0A09 ||
        rune == 0x0A0A ||
        rune == 0x0A13 ||
        rune == 0x0A74 ||
        rune == 0x0A67) {
      return 0x0A73;
    }
    // Fold all 'I' vowels to 'I' base (0x0A72)
    if (rune == 0x0A07 || rune == 0x0A08 || rune == 0x0A0F) return 0x0A72;

    return switch (rune) {
      0x0A33 => 0x0A32,
      0x0A36 => 0x0A38,
      0x0A59 => 0x0A16,
      0x0A5A => 0x0A17,
      0x0A5B => 0x0A1C,
      0x0A5C => 0x0A21,
      0x0A5E => 0x0A2B,
      0x0A5F => 0x0A2F,
      _ => rune,
    };
  }

  static int _foldMarkRune(int rune) {
    if (rune == 0x0A01 || rune == 0x0A70) return 0x0A02;
    return rune;
  }
}
