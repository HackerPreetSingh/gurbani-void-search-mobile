import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('About Gurbani Search', style: textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              'Gurbani Search is being built as a free, offline-first application for respectful and reliable Gurbani discovery across every Flutter platform.',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            const _Principle(
              icon: Icons.offline_bolt_outlined,
              title: 'Offline first',
              description:
                  'The search corpus and future speech models are designed to work on-device after installation.',
            ),
            const SizedBox(height: 20),
            const _Principle(
              icon: Icons.fact_check_outlined,
              title: 'Source stewardship',
              description:
                  'Every corpus release must preserve source provenance, licensing obligations, and correction history.',
            ),
            const SizedBox(height: 20),
            const _Principle(
              icon: Icons.architecture_outlined,
              title: 'Built to last',
              description:
                  'Search, speech, and the interface are deliberately separated so each can evolve without destabilizing the others.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
