import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gurbani_voice_search/core/database/local_database.dart';
import 'package:gurbani_voice_search/features/search/data/sqlite_punjabi_search_repository.dart';
import 'package:gurbani_voice_search/features/search/domain/models/gurbani_corpus.dart';
import 'package:gurbani_voice_search/features/search/domain/models/gurbani_search_result.dart';
import 'package:gurbani_voice_search/features/search/domain/repositories/punjabi_search_repository.dart';
import 'package:gurbani_voice_search/features/search/domain/services/gurmukhi_search_text.dart';

void main() {
  group('SqlitePunjabiSearchRepository', () {
    late LocalDatabase database;
    late SqlitePunjabiSearchRepository repository;

    setUp(() {
      database = LocalDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      repository = SqlitePunjabiSearchRepository(database);
    });

    tearDown(() => database.close());

    test(
      'returns a truthful no-corpus response before content is imported',
      () async {
        final response = await repository.search(
          GurmukhiSearchText.parseQuery('ਗਿਆਨ'),
        );

        expect(response.status, PunjabiSearchStatus.noCorpus);
        expect(response.results, isEmpty);
      },
    );

    test('imports, indexes, and searches Punjabi word prefixes', () async {
      final report = await repository.replaceCorpus(
        manifest: _manifest,
        lines: _lines,
      );

      final response = await repository.search(
        GurmukhiSearchText.parseQuery('ਗਿਆਨ ਦਿ'),
      );

      expect(report.indexedLineCount, 3);
      expect(report.indexedTokenCount, 10);
      expect(response.status, PunjabiSearchStatus.complete);
      expect(response.corpus?.lineCount, 3);
      expect(
        response.results.map((GurbaniSearchResult result) => result.stableId),
        ['line-1'],
      );
      expect(response.results.single.match, SearchResultMatch.word);
    });

    test('uses the build-time initial index for an initial query', () async {
      await repository.replaceCorpus(manifest: _manifest, lines: _lines);

      final response = await repository.search(
        GurmukhiSearchText.parseQuery('ਸ ਗ ਸ'),
      );

      expect(response.status, PunjabiSearchStatus.complete);
      expect(
        response.results.map((GurbaniSearchResult result) => result.stableId),
        ['line-2'],
      );
      expect(response.results.single.match, SearchResultMatch.initial);
    });

    test(
      'falls back from an ambiguous compact query to initial search',
      () async {
        await repository.replaceCorpus(manifest: _manifest, lines: _lines);

        final response = await repository.search(
          GurmukhiSearchText.parseQuery('ਸਗਰਦ'),
        );

        expect(response.results.single.stableId, 'line-1');
        expect(response.results.single.match, SearchResultMatch.initial);
      },
    );

    test(
      'rolls back an invalid replacement and keeps the active corpus',
      () async {
        await repository.replaceCorpus(manifest: _manifest, lines: _lines);

        await expectLater(
          repository.replaceCorpus(
            manifest: _manifest.copyWith(expectedLineCount: 2),
            lines: _lines.take(1),
          ),
          throwsA(isA<CorpusImportException>()),
        );

        final activeCorpus = await repository.activeCorpus();
        final response = await repository.search(
          GurmukhiSearchText.parseQuery('ਸ ਗ ਸ'),
        );

        expect(activeCorpus?.lineCount, 3);
        expect(response.results.single.stableId, 'line-2');
      },
    );
  });
}

final _manifest = GurbaniCorpusManifest(
  id: 'search-engine-test-corpus',
  displayName: 'Search engine test corpus',
  version: '1.0.0',
  languageTag: 'pa-Guru',
  sourceUrl: Uri.parse('https://example.invalid/search-engine-test-corpus'),
  licenseUrl: Uri.parse('https://example.invalid/search-engine-test-license'),
  attribution: 'Synthetic Punjabi test data; not a Gurbani corpus.',
  contentSha256:
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  expectedLineCount: 3,
);

const _lines = <GurbaniLineDraft>[
  GurbaniLineDraft(
    stableId: 'line-1',
    displayOrder: 1,
    gurmukhi: 'ਸਚਾ ਗਿਆਨ ਰਾਹ ਦਿਖਾਵੇ',
    sourceName: 'Search engine test fixture',
  ),
  GurbaniLineDraft(
    stableId: 'line-2',
    displayOrder: 2,
    gurmukhi: 'ਸਚ ਗਿਆਨ ਸੰਭਾਲੋ',
    sourceName: 'Search engine test fixture',
  ),
  GurbaniLineDraft(
    stableId: 'line-3',
    displayOrder: 3,
    gurmukhi: 'ਨਵਾਂ ਰਾਹ ਗਿਆਨ',
    sourceName: 'Search engine test fixture',
  ),
];

extension on GurbaniCorpusManifest {
  GurbaniCorpusManifest copyWith({int? expectedLineCount}) {
    return GurbaniCorpusManifest(
      id: id,
      displayName: displayName,
      version: version,
      languageTag: languageTag,
      sourceUrl: sourceUrl,
      licenseUrl: licenseUrl,
      attribution: attribution,
      contentSha256: contentSha256,
      expectedLineCount: expectedLineCount ?? this.expectedLineCount,
    );
  }
}
