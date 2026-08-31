import 'package:flutter/material.dart';
import '../../../domain/models/gurbani_search_result.dart';

class GurbaniHeader extends StatelessWidget {
  final GurbaniSearchResult firstVerse;

  const GurbaniHeader({super.key, required this.firstVerse});

  @override
  Widget build(BuildContext context) {
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
            Text(firstVerse.raagName!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          if (hasWriter)
            Text(firstVerse.writerName!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          if (hasSource) ...[
            const SizedBox(height: 4),
            Text(
              '${firstVerse.sourceName}${firstVerse.ang != null && firstVerse.ang != 0 ? " • Ang ${firstVerse.ang}" : ""}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
