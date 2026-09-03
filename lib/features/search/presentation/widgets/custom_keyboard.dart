import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/display_settings_notifier.dart';
import '../providers/keyboard_providers.dart';

class CustomKeyboard extends ConsumerWidget {
  const CustomKeyboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardType = ref.watch(keyboardTypeProvider);
    final isVisible = ref.watch(customKeyboardVisibleProvider);

    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 2, right: 2),
      child: SafeArea(
        top: false,
        child: keyboardType == KeyboardType.punjabi
            ? _buildPunjabiLayout(ref)
            : _buildEnglishLayout(ref),
      ),
    );
  }

  Widget _buildPunjabiLayout(WidgetRef ref) {
    final rows = [
      ['ੳ', 'ਅ', 'ੲ', 'ਸ', 'ਹ', 'ਕ', 'ਖ'],
      ['ਗ', 'ਘ', 'ਙ', 'ਚ', 'ਛ', 'ਜ', 'ਝ'],
      ['ਞ', 'ਟ', 'ਠ', 'ਡ', 'ਢ', 'ਣ', 'ਤ'],
      ['ਥ', 'ਦ', 'ਧ', 'ਨ', 'ਪ', 'ਫ', 'ਬ'],
      ['ਭ', 'ਮ', 'ਯ', 'ਰ', 'ਲ', 'ਵ', 'ੜ'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows.map((row) => _buildKeyboardRow(ref, row)),
        _buildBottomRow(ref),
      ],
    );
  }

  Widget _buildEnglishLayout(WidgetRef ref) {
    final rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows.map((row) => _buildKeyboardRow(ref, row)),
        _buildBottomRow(ref),
      ],
    );
  }

  Widget _buildKeyboardRow(WidgetRef ref, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) => Expanded(
          child: _KeyboardKey(label: key, onTap: () => ref.read(searchQueryProvider.notifier).append(key)),
        )).toList(),
      ),
    );
  }

  Widget _buildBottomRow(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _KeyboardKey(
              icon: Icons.delete_forever_outlined,
              onTap: () => ref.read(searchQueryProvider.notifier).setQuery(''),
              color: Colors.orangeAccent.withAlpha(40),
            ),
          ),
          Expanded(
            flex: 2,
            child: _KeyboardKey(
              icon: Icons.backspace_outlined,
              onTap: () => ref.read(searchQueryProvider.notifier).delete(),
              color: Colors.redAccent.withAlpha(40),
            ),
          ),
          Expanded(
            flex: 4,
            child: _KeyboardKey(
              icon: Icons.space_bar,
              onTap: () => ref.read(searchQueryProvider.notifier).append(' '),
              color: Colors.white,
            ),
          ),
          Expanded(
            flex: 2,
            child: _KeyboardKey(
              icon: Icons.keyboard_hide_outlined,
              onTap: () => ref.read(customKeyboardVisibleProvider.notifier).setVisible(false),
              color: Colors.teal.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardKey extends ConsumerWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  const _KeyboardKey({this.label, this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 1, offset: const Offset(0, 1)),
            ],
          ),
          alignment: Alignment.center,
          child: icon != null 
            ? Icon(icon, size: 20, color: Colors.black87)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}
