import 'package:flutter/material.dart';
import '../bani/presentation/bani_screen.dart';

class BaniPage extends StatelessWidget {
  final int baniId;
  final String? highlightVerseId;

  const BaniPage({super.key, required this.baniId, this.highlightVerseId});

  @override
  Widget build(BuildContext context) {
    return BaniScreen(
      baniId: baniId,
      highlightVerseId: highlightVerseId,
    );
  }
}
