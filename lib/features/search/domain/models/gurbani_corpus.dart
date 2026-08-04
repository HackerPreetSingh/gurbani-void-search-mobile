class GurbaniCorpusManifest {
  const GurbaniCorpusManifest({
    required this.id,
    required this.displayName,
    required this.version,
    required this.languageTag,
    required this.sourceUrl,
    required this.licenseUrl,
    required this.attribution,
    required this.contentSha256,
    required this.expectedLineCount,
  });

  final String id;
  final String displayName;
  final String version;
  final String languageTag;
  final Uri sourceUrl;
  final Uri licenseUrl;
  final String attribution;
  final String contentSha256;
  final int expectedLineCount;
}

class GurbaniCorpusSummary {
  const GurbaniCorpusSummary({
    required this.id,
    required this.displayName,
    required this.version,
    required this.lineCount,
    required this.attribution,
    required this.importedAtUtc,
  });

  final String id;
  final String displayName;
  final String version;
  final int lineCount;
  final String attribution;
  final DateTime importedAtUtc;
}

class GurbaniLineDraft {
  const GurbaniLineDraft({
    required this.stableId,
    required this.displayOrder,
    required this.gurmukhi,
    required this.sourceName,
    this.writerName,
    this.raagName,
    this.ang,
  });

  final String stableId;
  final int displayOrder;
  final String gurmukhi;
  final String sourceName;
  final String? writerName;
  final String? raagName;
  final int? ang;
}

class CorpusImportReport {
  const CorpusImportReport({
    required this.corpus,
    required this.indexedLineCount,
    required this.indexedTokenCount,
  });

  final GurbaniCorpusSummary corpus;
  final int indexedLineCount;
  final int indexedTokenCount;
}
