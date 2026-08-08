import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

class VishramService {
  InlineSpan buildGurmukhiText(
    String gurmukhi, 
    String? visraamsJson, 
    TextStyle baseStyle,
    bool showVishrams,
  ) {
    // Logging the data incoming from DB
    dev.log('Rendering Line: "$gurmukhi"', name: 'GurbaniUI');
    dev.log('Vishram Data: $visraamsJson', name: 'GurbaniUI');

    if (!showVishrams || visraamsJson == null || visraamsJson.isEmpty || visraamsJson == '[]') {
      return TextSpan(text: gurmukhi, style: baseStyle);
    }

    try {
      final List<dynamic> vList = jsonDecode(visraamsJson);
      // Using precise word splitting logic (ignoring multiple spaces)
      final words = gurmukhi.trim().split(RegExp(r'\s+'));
      final List<InlineSpan> spans = [];

      dev.log('Split Words Count: ${words.length}', name: 'GurbaniUI');

      for (int i = 0; i < words.length; i++) {
        String? type;
        for (final v in vList) {
          final p = v['p'];
          final pIndex = p is int ? p : int.tryParse(p.toString());
          if (pIndex == i) {
            type = v['t'];
            dev.log('Highlight Triggered for Word [$i]: "${words[i]}" type: $type', name: 'GurbaniUI');
            break;
          }
        }
        
        Color? bgColor;
        Color? textColor;
        if (type == 'v') {
          bgColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
        } else if (type == 'y') {
          bgColor = Colors.blue.shade100;
          textColor = Colors.blue.shade900;
        }

        spans.add(TextSpan(
          text: words[i],
          style: TextStyle(
            backgroundColor: bgColor,
            color: textColor ?? Colors.black,
            fontWeight: textColor != null ? FontWeight.w900 : FontWeight.w500,
          ),
        ));

        if (i < words.length - 1) {
          spans.add(const TextSpan(text: ' ', style: TextStyle(backgroundColor: null, color: Colors.black)));
        }
      }

      // Add double danda if it was lost during splitting
      if (gurmukhi.endsWith('॥') && !words.last.contains('॥')) {
        spans.add(const TextSpan(text: ' ॥', style: TextStyle(color: Colors.black)));
      }

      return TextSpan(style: baseStyle, children: spans);
    } catch (e) {
      dev.log('Highlighting Logic Failed: $e', name: 'GurbaniUI', error: e);
      return TextSpan(text: gurmukhi, style: baseStyle);
    }
  }
}
