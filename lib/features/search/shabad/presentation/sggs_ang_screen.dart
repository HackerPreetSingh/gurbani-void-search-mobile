import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/providers/shabad_providers.dart';
import '../../../settings/domain/models/display_settings.dart';
import '../../../settings/presentation/display_settings_notifier.dart';
import '../../shared/presentation/widgets/gurbani_verse_view.dart';
import '../../shared/presentation/widgets/pinch_to_zoom_wrapper.dart';
import 'widgets/shabad_settings_dialog.dart';

class SggsAngScreen extends ConsumerStatefulWidget {
  final int initialAng;
  const SggsAngScreen({super.key, required this.initialAng});

  @override
  ConsumerState<SggsAngScreen> createState() => _SggsAngScreenState();
}

class _SggsAngScreenState extends ConsumerState<SggsAngScreen> {
  late int _currentAng;

  @override
  void initState() {
    super.initState();
    _currentAng = widget.initialAng;
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _navigateToAng(int ang) {
    if (ang < 1 || ang > 1430) return;
    setState(() {
      _currentAng = ang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(angVersesProvider(_currentAng));
    final settingsAsync = ref.watch(shabadSettingsProvider);
    final settings = settingsAsync.value ?? DisplaySettings.defaults();

    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Sri Guru Granth Sahib Ji - Ang $_currentAng'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettingsDialog(context, settings),
            ),
          ],
        ),
        body: PinchToZoomWrapper(
          currentSize: settings.fontSizeGurmukhi,
          onSizeChanged: (newSize) => ref.read(shabadSettingsProvider.notifier).updateFontSizeGurmukhi(newSize),
          child: versesAsync.when(
            data: (verses) {
              if (verses.isEmpty) {
                return const Center(child: Text('Content not found for this Ang.'));
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      key: ValueKey('ang_$_currentAng'),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        return GurbaniVerseView(
                          verse: verses[index],
                          settings: settings,
                        );
                      },
                    ),
                  ),
                  _buildBottomNavigator(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentAng > 1 ? () => _navigateToAng(_currentAng - 1) : null,
              color: Colors.teal,
            ),
            TextButton(
              onPressed: _showJumpToAngDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ang $_currentAng / 1430',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentAng < 1430 ? () => _navigateToAng(_currentAng + 1) : null,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  void _showJumpToAngDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Ang'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter Ang (1-1430)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1 && val <= 1430) {
                Navigator.pop(context);
                _navigateToAng(val);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, DisplaySettings settings) {
    showDialog(
      context: context,
      builder: (context) => ShabadSettingsDialog(initialSettings: settings),
    );
  }
}
