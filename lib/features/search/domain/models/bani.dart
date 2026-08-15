import 'gurbani_search_result.dart';

class Bani {
  final int id;
  final String namePa;
  final String nameEn;
  final int userOrder;
  final String? updatedAt;

  Bani({
    required this.id,
    required this.namePa,
    required this.nameEn,
    required this.userOrder,
    this.updatedAt,
  });

  factory Bani.fromMap(Map<String, dynamic> map) {
    return Bani(
      id: map['id'] as int,
      namePa: map['name_pa'] as String,
      nameEn: map['name_en'] as String,
      userOrder: (map['user_order'] as int?) ?? 0,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Bani copyWith({
    int? id,
    String? namePa,
    String? nameEn,
    int? userOrder,
    String? updatedAt,
  }) {
    return Bani(
      id: id ?? this.id,
      namePa: namePa ?? this.namePa,
      nameEn: nameEn ?? this.nameEn,
      userOrder: userOrder ?? this.userOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BaniVerse {
  final int sequenceOrder;
  final int header;
  final int? mangalPosition;
  final bool existsSGPC;
  final bool existsTaksal;
  final GurbaniSearchResult verse;

  BaniVerse({
    required this.sequenceOrder,
    required this.header,
    this.mangalPosition,
    required this.existsSGPC,
    required this.existsTaksal,
    required this.verse,
  });
}
