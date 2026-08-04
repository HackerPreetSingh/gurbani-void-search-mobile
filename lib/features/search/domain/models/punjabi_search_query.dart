enum PunjabiSearchKind {
  empty,
  gurmukhiWord,
  gurmukhiInitial,
  gurmukhiAmbiguous,
  unsupported,
}

class PunjabiSearchQuery {
  const PunjabiSearchQuery({
    required this.raw,
    required this.kind,
    this.wordTokens = const [],
    this.initialKey = '',
  });

  final String raw;
  final PunjabiSearchKind kind;
  final List<String> wordTokens;
  final String initialKey;

  bool get isSearchable {
    return kind == PunjabiSearchKind.gurmukhiWord ||
        kind == PunjabiSearchKind.gurmukhiInitial ||
        kind == PunjabiSearchKind.gurmukhiAmbiguous;
  }
}
