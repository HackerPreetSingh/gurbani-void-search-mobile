import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/database/database_download_notifier.dart';
import '../../../core/database/local_database.dart';
import '../../../core/di/core_providers.dart';

class FoundationPage extends ConsumerWidget {
  const FoundationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseStatus = ref.watch(databaseStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: databaseStatus.when(
            loading: () => const _DatabaseLoadingView(),
            error: (Object error, StackTrace stackTrace) {
              return _DatabaseErrorView(
                onRetry: () => ref.invalidate(databaseStatusProvider),
              );
            },
            data: (DatabaseStatus status) {
              if (!status.isAvailable) {
                return const _DownloadDatabaseView();
              }
              return _DatabaseReadyView(status: status);
            },
          ),
        ),
      ),
    );
  }
}

class _DownloadDatabaseView extends ConsumerWidget {
  const _DownloadDatabaseView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(databaseDownloadProvider);
    final downloadNotifier = ref.read(databaseDownloadProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 40),
            const SizedBox(height: 24),
            Text(
              'Database download required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'The local Gurbani database is missing. Please download it to enable instant offline search.',
            ),
            const SizedBox(height: 24),
            if (downloadState.status == DownloadStatus.downloading) ...[
              LinearProgressIndicator(value: downloadState.progress),
              const SizedBox(height: 8),
              Text(
                downloadState.progress != null && downloadState.progress! >= 0
                    ? 'Downloading: ${(downloadState.progress! * 100).toStringAsFixed(1)}%'
                    : 'Downloading...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              if (downloadState.status == DownloadStatus.error && downloadState.errorMessage != null) ...[
                Text(
                  'Error: ${downloadState.errorMessage}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: () => downloadNotifier.downloadDatabase(),
                icon: const Icon(Icons.download),
                label: const Text('Download Offline Database'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatabaseLoadingView extends StatelessWidget {
  const _DatabaseLoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preparing local database',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Preparing secure local storage…')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatabaseReadyView extends StatelessWidget {
  const _DatabaseReadyView({required this.status});

  final DatabaseStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Gurbani Search foundation ready',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_stories, color: colorScheme.primary, size: 40),
              const SizedBox(height: 24),
              Text('Gurbani Search', style: textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'An offline-first foundation for fast, respectful Gurbani discovery.',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 28),
              _StatusRow(
                icon: Icons.verified_outlined,
                label: 'Local SQLite storage verified',
                detail: 'Ready for use',
              ),
              const SizedBox(height: 18),
              const _StatusRow(
                icon: Icons.inventory_2_outlined,
                label: 'No Gurbani corpus is installed',
                detail:
                    'A verified, license-compliant corpus distribution is required before search can begin.',
              ),
              const SizedBox(height: 18),
              const _StatusRow(
                icon: Icons.lock_outline,
                label: 'Your future library remains on this device',
                detail:
                    'No cloud account or paid API is required by this foundation.',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoute.search),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(detail, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatabaseErrorView extends StatelessWidget {
  const _DatabaseErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.storage_outlined, size: 40),
            const SizedBox(height: 24),
            Text(
              'Local storage could not be prepared',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please try again. If the issue persists, restart the app or check available device storage.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
