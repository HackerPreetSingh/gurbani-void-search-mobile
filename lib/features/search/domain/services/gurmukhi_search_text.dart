import 'package:characters/characters.dart';
import '../models/punjabi_search_query.dart';

/// Robust parser for Gurbani search queries.
abstract final class GurmukhiSearchText {
  static PunjabiSearchQuery parseQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return PunjabiSearchQuery(raw: raw, kind: PunjabiSearchKind.empty);
    }

    // 1. Identify Roman (English) Search
    // We allow spaces and common English characters.
    if (RegExp(r'^[a-zA-Z0-9\s\.\,\?\!]+$').hasMatch(trimmed)) {
      final tokens = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      if (tokens.length == 1 && trimmed.length > 1) {
        return PunjabiSearchQuery(
          raw: raw,
          kind: PunjabiSearchKind.romanInitial,
          wordTokens: tokens,
        );
      }
      return PunjabiSearchQuery(
        raw: raw,
        kind: PunjabiSearchKind.romanWord,
        wordTokens: tokens,
      );
    }

    // 2. Gurmukhi Processing
    // We extract all searchable tokens, ignoring hidden or invalid characters.
    final tokens = _normalizedTokens(raw);
    
    if (tokens.isEmpty) {
      // If we found Roman characters but they didn't match the strict regex above, 
      // or if it's just garbage, we return unsupported.
      return PunjabiSearchQuery(raw: raw, kind: PunjabiSearchKind.unsupported);
    }

    // 3. Determine Gurmukhi Search Type
    
    // Case A: Multiple single-character tokens (e.g., "ਸ ਸ ਸ ਗ")
    final everyTokenIsOneBase = tokens.every((String token) => _baseCharacterCount(token) == 1);
    if (everyTokenIsOneBase && tokens.length > 1) {
      return PunjabiSearchQuery(
        raw: raw,
        kind: PunjabiSearchKind.gurmukhiInitial,
        wordTokens: tokens,
        initialKey: _initialsFromNormalizedTokens(tokens),
      );
    }

    // Case B: Single multi-character token without marks (e.g., "ਸਸਸਗ" or "ਗਮਕਦ")
    // This is the "Ambiguous" case used for fast initials typing.
    final singleUnmarkedToken = tokens.length == 1 && 
                                tokens.single.characters.length > 1 && 
                                !_containsDependentMark(raw);
    if (singleUnmarkedToken) {
        return PunjabiSearchQuery(
          raw: raw,
          kind: PunjabiSearchKind.gurmukhiAmbiguous,
          wordTokens: tokens,
          initialKey: _initialSequence(tokens.single),
        );
    }

    // Case C: Explicit Word Search (e.g., "ਸਤਿਗੁਰ" or any query with vowel marks)
    return PunjabiSearchQuery(
      raw: raw,
      kind: PunjabiSearchKind.gurmukhiWord,
      wordTokens: tokens,
      initialKey: _initialsFromNormalizedTokens(tokens),
    );
  }

  static List<String> _normalizedTokens(String value) {
    final rawTokens = <String>[];
    var token = StringBuffer();

    void flushToken() {
      if (token.isEmpty) return;
      final normalized = _normalizeToken(token.toString());
      if (normalized.isNotEmpty) {
        rawTokens.add(normalized);
      }
      token = StringBuffer();
    }

    for (final rune in value.runes) {
      if (_isGurmukhiWordRune(rune)) {
        token.writeCharCode(rune);
      } else if (_isWhitespace(rune) || _isPunctuation(rune)) {
        flushToken();
      }
      // Hidden or unsupported characters are silently ignored
    }
    flushToken();

    return List.unmodifiable(rawTokens);
  }

  static String _initialsFromNormalizedTokens(Iterable<String> tokens) {
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

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D || rune == 0x00A0 || rune == 0x200B;

  static bool _isPunctuation(int rune) {
    return const <int>{
      0x21, 0x27, 0x28, 0x29, 0x2C, 0x2D, 0x2E, 0x2F, 0x3A, 0x3B, 0x3F, 0x5B, 0x5D, 0x7B, 0x7D, 0x0A64, 0x0A65,
    }.contains(rune);
  }

  static bool _isGurmukhiWordRune(int rune) {
    // Standard Gurmukhi Block
    return (rune >= 0x0A00 && rune <= 0x0A7F);
  }

  static bool _isGurmukhiBase(int rune) {
    return (rune >= 0x0A05 && rune <= 0x0A14) ||
        (rune >= 0x0A15 && rune <= 0x0A28) ||
        (rune >= 0x0A2A && rune <= 0x0A30) ||
        rune == 0x0A32 || rune == 0x0A33 || rune == 0x0A35 || rune == 0x0A36 ||
        (rune >= 0x0A38 && rune <= 0x0A39) ||
        (rune >= 0x0A59 && rune <= 0x0A5F) ||
        rune == 0x0A72 || rune == 0x0A73 || rune == 0x0A74;
  }

  static bool _containsDependentMark(String value) {
    return value.runes.any((int rune) =>
          rune == 0x0A3C || (rune >= 0x0A3E && rune <= 0x0A42) ||
          (rune >= 0x0A47 && rune <= 0x0A48) || (rune >= 0x0A4B && rune <= 0x0A4D) ||
          rune == 0x0A51 || (rune >= 0x0A70 && rune <= 0x0A71) || rune == 0x0A75);
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
    return rune == 0x0A01 || rune == 0x0A02 || rune == 0x0A3C ||
        (rune >= 0x0A3E && rune <= 0x0A42) || (rune >= 0x0A47 && rune <= 0x0A48) ||
        (rune >= 0x0A4B && rune <= 0x0A4D) || rune == 0x0A51 ||
        (rune >= 0x0A70 && rune <= 0x0A71) || rune == 0x0A75;
  }

  static int _foldBaseRune(int rune) {
    if (rune == 0x0A06 || rune == 0x0A10 || rune == 0x0A14) return 0x0A05;
    if (rune == 0x0A09 || rune == 0x0A0A || rune == 0x0A13 || rune == 0x0A74 || rune == 0x0A67) return 0x0A73;
    if (rune == 0x0A07 || rune == 0x0A08 || rune == 0x0A0F) return 0x0A72;
    return switch (rune) {
      0x0A33 => 0x0A32, 0x0A36 => 0x0A38, 0x0A59 => 0x0A16, 0x0A5A => 0x0A17,
      0x0A5B => 0x0A1C, 0x0A5C => 0x0A21, 0x0A5E => 0x0A2B, 0x0A5F => 0x0A2F, _ => rune,
    };
  }

  static int _foldMarkRune(int rune) {
    if (rune == 0x0A01 || rune == 0x0A70) return 0x0A02;
    return rune;
  }
}
