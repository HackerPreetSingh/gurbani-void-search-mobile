import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import 'corpus_import_service.dart';

class CorpusDownloadService {
  CorpusDownloadService(this._importService);

  final CorpusImportService _importService;
  final _dio = Dio();

  static const _productionDbUrl = AppConstants.databaseDownloadUrl;

  Future<void> downloadAndImport({
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, 'banidb_download.sqlite');

    onStatus('Downloading production corpus...');
    
    try {
      await _dio.download(
        _productionDbUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      onStatus('Indexing data for offline use...');
      await _importService.importFromBaniDbSnapshot(tempPath);
      
      onStatus('Cleaning up...');
      final file = File(tempPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to setup search engine: $e');
    }
  }
}
