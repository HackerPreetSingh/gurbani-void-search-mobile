import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import 'local_database.dart';
import '../di/core_providers.dart';

enum DownloadStatus { idle, downloading, success, error }

class DownloadState {
  final DownloadStatus status;
  final double? progress; 
  final String? errorMessage;

  DownloadState({
    required this.status,
    this.progress = 0,
    this.errorMessage,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    bool isIndeterminate = false,
    String? errorMessage,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: isIndeterminate ? null : (progress ?? this.progress),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DatabaseDownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    return DownloadState(status: DownloadStatus.idle);
  }

  Future<void> downloadDatabase() async {
    if (kIsWeb) {
       print('${AppConstants.logTag} Web platform detected. Manual download disabled.');
       return;
    }

    final methodStart = DateTime.now();
    print('${AppConstants.logTag} [$methodStart] START: downloadDatabase method');
    state = state.copyWith(status: DownloadStatus.downloading, progress: 0);

    try {
      final dio = ref.read(dioProvider);
      final database = ref.read(localDatabaseProvider);
      
      final pathStart = DateTime.now();
      final docsDir = await getApplicationDocumentsDirectory();
      final savePath = p.join(docsDir.path, AppConstants.dbFileName);
      final pathEnd = DateTime.now();
      print('${AppConstants.logTag} [$pathEnd] PATH_INFO: savePath=$savePath. getApplicationDocumentsDirectory took: ${pathEnd.difference(pathStart).inMilliseconds}ms');
      
      const url = AppConstants.databaseDownloadUrl;

      print('${AppConstants.logTag} [${DateTime.now()}] !!! IMPORTANT !!! STARTING DOWNLOAD FROM NEW URL: $url');
      print('${AppConstants.logTag} [${DateTime.now()}] TARGET SAVE PATH: $savePath');
      
      double lastLoggedProgress = -1;
      
      print('${AppConstants.logTag} [${DateTime.now()}] REQUEST_INFO: Sending GET request via Dio...');
      
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      final totalBytes = int.tryParse(response.headers.value('content-length') ?? '-1') ?? -1;
      print('${AppConstants.logTag} [${DateTime.now()}] DOWNLOAD_METADATA: Content-Length detected as: $totalBytes');

      final file = File(savePath);
      final raf = file.openSync(mode: FileMode.write);
      int receivedBytes = 0;

      await for (final chunk in response.data.stream) {
        raf.writeFromSync(chunk);
        receivedBytes += (chunk as List<int>).length;

        if (totalBytes != -1 && totalBytes > 0) {
          final progressValue = receivedBytes / totalBytes;
          state = state.copyWith(progress: progressValue);
          
          if ((progressValue * 20).floor() > lastLoggedProgress) {
            lastLoggedProgress = (progressValue * 20).floor().toDouble();
            print('${AppConstants.logTag} [${DateTime.now()}] DOWNLOAD_TICK: Received $receivedBytes of $totalBytes bytes (${(progressValue * 100).toStringAsFixed(1)}%)');
          }
        } else {
          // If total size is unknown, show indeterminate progress (null)
          if (state.progress != null) {
            state = state.copyWith(isIndeterminate: true);
          }
          
          // Throttled logging for indeterminate downloads
          final currentMB = receivedBytes ~/ (1024 * 1024);
          if (currentMB > lastLoggedProgress) {
            lastLoggedProgress = currentMB.toDouble();
            print('${AppConstants.logTag} [${DateTime.now()}] DOWNLOAD_TICK: Received $receivedBytes bytes (Indeterminate)...');
          }
        }
      }
      await raf.close();

      print('${AppConstants.logTag} [${DateTime.now()}] DOWNLOAD_SUCCESS: File written to $savePath');
      
      final fileLength = await file.length();
      print('${AppConstants.logTag} [${DateTime.now()}] VERIFY_FILE: Size on disk is $fileLength bytes (${(fileLength / 1024 / 1024).toStringAsFixed(2)} MB)');

      final reloadStart = DateTime.now();
      print('${AppConstants.logTag} [$reloadStart] RELOAD_PHASE: Triggering local database reload to pick up new file');
      await database.reload();
      
      print('${AppConstants.logTag} [${DateTime.now()}] RELOAD_PHASE: Invalidating databaseStatusProvider to notify UI');
      ref.invalidate(databaseStatusProvider);
      
      final reloadEnd = DateTime.now();
      print('${AppConstants.logTag} [$reloadEnd] RELOAD_PHASE_COMPLETE: Reload took ${reloadEnd.difference(reloadStart).inMilliseconds}ms');

      state = state.copyWith(status: DownloadStatus.success);
      final methodEnd = DateTime.now();
      print('${AppConstants.logTag} [$methodEnd] END_TO_END_SUCCESS: downloadDatabase finished successfully in ${methodEnd.difference(methodStart).inSeconds}s');
    } catch (e) {
      final methodEnd = DateTime.now();
      print('${AppConstants.logTag} [$methodEnd] END: downloadDatabase FAILED with error: $e');
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final databaseDownloadProvider =
    NotifierProvider<DatabaseDownloadNotifier, DownloadState>(() {
  return DatabaseDownloadNotifier();
});
