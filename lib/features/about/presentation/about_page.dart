import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
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
