import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
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
      final shabadDb = ref.read(shabadDatabaseProvider);
      final nitnemDb = ref.read(nitnemDatabaseProvider);
      
      final docsDir = await getApplicationDocumentsDirectory();
      
      // 1. Download Shabad Database
      await _downloadSingleFile(
        dio, 
        AppConstants.shabadDownloadUrl, 
        p.join(docsDir.path, AppConstants.shabadDbFile),
        'SHABAD_DB',
        0.0, 0.5
      );

      // 2. Download Nitnem Database
      await _downloadSingleFile(
        dio, 
        AppConstants.nitnemDownloadUrl, 
        p.join(docsDir.path, AppConstants.nitnemDbFile),
        'NITNEM_DB',
        0.5, 1.0
      );

      print('${AppConstants.logTag} [${DateTime.now()}] RELOAD_PHASE: Triggering local database reloads');
      await shabadDb.reload();
      await nitnemDb.reload();
      
      print('${AppConstants.logTag} [${DateTime.now()}] RELOAD_PHASE: Invalidating databaseStatusProvider');
      ref.invalidate(databaseStatusProvider);
      
      state = state.copyWith(status: DownloadStatus.success, progress: 1.0);
      print('${AppConstants.logTag} [${DateTime.now()}] END_TO_END_SUCCESS: All databases downloaded and ready.');
    } catch (e) {
      final methodEnd = DateTime.now();
      print('${AppConstants.logTag} [$methodEnd] END: downloadDatabase FAILED with error: $e');
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _downloadSingleFile(
    Dio dio, 
    String url, 
    String savePath, 
    String logLabel,
    double startProgress,
    double endProgress,
  ) async {
    print('${AppConstants.logTag} [${DateTime.now()}] $logLabel: Starting download from $url');
    print('${AppConstants.logTag} [${DateTime.now()}] $logLabel: Save path: $savePath');

    final response = await dio.get(
      url,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    final totalBytes = int.tryParse(response.headers.value('content-length') ?? '-1') ?? -1;
    final file = File(savePath);
    final raf = file.openSync(mode: FileMode.write);
    int receivedBytes = 0;
    double lastLoggedProgress = -1;

    await for (final chunk in response.data.stream) {
      raf.writeFromSync(chunk);
      receivedBytes += (chunk as List<int>).length;

      if (totalBytes > 0) {
        final relativeProgress = receivedBytes / totalBytes;
        final globalProgress = startProgress + (relativeProgress * (endProgress - startProgress));
        state = state.copyWith(progress: globalProgress);
        
        if ((relativeProgress * 10).floor() > lastLoggedProgress) {
          lastLoggedProgress = (relativeProgress * 10).floor().toDouble();
          print('${AppConstants.logTag} [${DateTime.now()}] $logLabel: ${(relativeProgress * 100).toStringAsFixed(1)}% complete');
        }
      } else {
        state = state.copyWith(isIndeterminate: true);
      }
    }
    await raf.close();
    print('${AppConstants.logTag} [${DateTime.now()}] $logLabel: Download successful.');
  }
}

final databaseDownloadProvider =
    NotifierProvider<DatabaseDownloadNotifier, DownloadState>(() {
  return DatabaseDownloadNotifier();
});
