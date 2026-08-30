import 'dart:convert';
import 'package:flutter/material.dart';

class VishramService {
  InlineSpan buildGurmukhiText(
    String gurmukhi, 
    String? visraamsJson, 
    TextStyle baseStyle,
    bool showVishrams,
    bool isLarivaar,
  ) {
    if ((!showVishrams || visraamsJson == null || visraamsJson.isEmpty || visraamsJson == '[]') && !isLarivaar) {
      return TextSpan(text: gurmukhi, style: baseStyle);
    }

    try {
      final List<dynamic> vList = visraamsJson != null && visraamsJson.isNotEmpty && visraamsJson != '[]' 
          ? jsonDecode(visraamsJson) 
          : [];
      
      final words = gurmukhi.trim().split(RegExp(r'\s+'));
      final List<InlineSpan> spans = [];

      for (int i = 0; i < words.length; i++) {
        String? type;
        if (showVishrams) {
          for (final v in vList) {
            final p = v['p'];
            final pIndex = p is int ? p : int.tryParse(p.toString());
            if (pIndex == i) {
              type = v['t'];
              break;
            }
          }
        }
        
        Color? textColor;
        if (type == 'v') {
          textColor = Colors.green.shade900;
        } else if (type == 'y') {
          textColor = Colors.blue.shade900;
        }

        spans.add(TextSpan(
          text: words[i],
          style: TextStyle(
            color: textColor ?? baseStyle.color,
            fontWeight: baseStyle.fontWeight,
          ),
        ));

        // In Larivaar mode, we skip adding spaces between words.
        if (!isLarivaar && i < words.length - 1) {
          spans.add(TextSpan(text: ' ', style: TextStyle(color: baseStyle.color)));
        }
      }

      // Add double danda if it was lost during splitting
      if (gurmukhi.endsWith('॥') && !words.last.contains('॥')) {
        if (!isLarivaar) {
          spans.add(TextSpan(text: ' ॥', style: TextStyle(color: baseStyle.color)));
        } else {
          spans.add(TextSpan(text: '॥', style: TextStyle(color: baseStyle.color)));
        }
      }

      return TextSpan(style: baseStyle, children: spans);
    } catch (e) {
      String text = isLarivaar ? gurmukhi.replaceAll(' ', '') : gurmukhi;
      return TextSpan(text: text, style: baseStyle);
    }
  }
}
