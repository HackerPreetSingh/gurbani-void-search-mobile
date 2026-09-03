import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/gurbani_search_result.dart';
import '../../../../settings/presentation/display_settings_notifier.dart';

class GurbaniHeader extends ConsumerWidget {
  final GurbaniSearchResult firstVerse;

  const GurbaniHeader({super.key, required this.firstVerse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;
    final bool hasRaag = firstVerse.raagName != null &&
        firstVerse.raagName!.trim().isNotEmpty &&
        !firstVerse.raagName!.toLowerCase().contains('unknown') &&
        !firstVerse.raagName!.toLowerCase().contains('null');
    final bool hasWriter = firstVerse.writerName != null &&
        firstVerse.writerName!.trim().isNotEmpty &&
        !firstVerse.writerName!.toLowerCase().contains('unknown') &&
        !firstVerse.writerName!.toLowerCase().contains('null');
    final bool hasSource = firstVerse.sourceName.trim().isNotEmpty &&
        !firstVerse.sourceName.toLowerCase().contains('unknown') &&
        !firstVerse.sourceName.toLowerCase().contains('null');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.teal.withAlpha(15),
      child: Column(
        children: [
          if (hasRaag)
            Text(
              firstVerse.raagName!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                color: Colors.black,
              ),
            ),
          if (hasWriter)
            Text(
              firstVerse.writerName!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          if (hasSource) ...[
            const SizedBox(height: 4),
            Text(
              '${firstVerse.sourceName}${firstVerse.ang != null && firstVerse.ang != 0 ? " • Ang ${firstVerse.ang}" : ""}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
