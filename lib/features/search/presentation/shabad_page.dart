import 'package:flutter/material.dart';
import '../shabad/presentation/shabad_screen.dart';

class ShabadPage extends StatelessWidget {
  final String shabadId;
  final String? highlightVerseId;

  const ShabadPage({super.key, required this.shabadId, this.highlightVerseId});

  @override
  Widget build(BuildContext context) {
    return ShabadScreen(
      shabadId: shabadId,
      highlightVerseId: highlightVerseId,
    );
  }
}
