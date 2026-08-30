import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_download_notifier.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('About This App', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Gurbani Search is a labor of love, built to help the global Sangat connect with Gurbani through a high-performance, offline-first experience. Our mission is to provide reliable and respectful access to spiritual wisdom, regardless of internet connectivity.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              Text('What we offer:', style: textTheme.titleLarge?.copyWith(color: Colors.teal)),
              const SizedBox(height: 16),
              const _Feature(
                icon: Icons.search,
                title: 'Powerful Search',
                description: 'Fast and intelligent searching across SGGS, Dasam Bani, and Vaaran Bhai Gurdas. Supports phonetic English typing for instant results.',
              ),
              const _Feature(
                icon: Icons.menu_book,
                title: 'Nitnem & Banis',
                description: 'Access complete liturgical paths in their correct sequence. Reorder your daily Banis to match your personal Maryada.',
              ),
              const _Feature(
                icon: Icons.track_changes,
                title: 'Nitnem Tracker',
                description: 'Set and manage your spiritual goals. Track Mool Mantar, Simran, or Sehaj Path progress with detailed analytics and history.',
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              Text('Special Thanks & Credits:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'This application would not be possible without the foundational research, data API, and open-source contributions provided by:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const BulletPoint(text: 'The BaniDB Team for their robust Gurbani API.'),
              const BulletPoint(text: 'Akal Technologies for their pioneering research in Gurbani technology.'),
              const BulletPoint(text: 'The Khalis Foundation & STTM teams for their dedication to digital Gurbani preservation.'),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showDownloadDialog(context),
                  icon: const Icon(Icons.download_for_offline),
                  label: const Text('Update / Download Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'May this small tool be a companion on your spiritual journey.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Database Update', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                const _ManualDownloadView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualDownloadView extends ConsumerWidget {
  const _ManualDownloadView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(databaseDownloadProvider);
    final downloadNotifier = ref.read(databaseDownloadProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (downloadState.status == DownloadStatus.downloading) ...[
          const Icon(Icons.downloading, size: 48, color: Colors.teal),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: downloadState.progress),
          const SizedBox(height: 8),
          Text(
            downloadState.progress != null && downloadState.progress! >= 0
                ? 'Downloading: ${(downloadState.progress! * 100).toStringAsFixed(1)}%'
                : 'Starting download...',
          ),
        ] else if (downloadState.status == DownloadStatus.idle || downloadState.status == DownloadStatus.error) ...[
          const Icon(Icons.cloud_download, size: 48, color: Colors.teal),
          const SizedBox(height: 16),
          const Text(
            'Click below to refresh the offline Gurbani database files.',
            textAlign: TextAlign.center,
          ),
          if (downloadState.status == DownloadStatus.error)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Error: ${downloadState.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => downloadNotifier.downloadDatabase(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Start Download'),
          ),
        ] else if (downloadState.status == DownloadStatus.success) ...[
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Database updated successfully!'),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _Feature({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.teal.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
