import 'package:uuid/uuid.dart';

class Prakaran {
  final String id;
  final String name;
  final DateTime createdAt;

  Prakaran({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Prakaran.fromMap(Map<String, dynamic> map) {
    return Prakaran(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Prakaran.create(String name) {
    return Prakaran(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
  }
}

class PrakaranItem {
  final int? id;
  final String prakaranId;
  final String shabadId;
  final String? verseId;
  final String titleGurmukhi;
  final DateTime createdAt;

  PrakaranItem({
    this.id,
    required this.prakaranId,
    required this.shabadId,
    this.verseId,
    required this.titleGurmukhi,
    required this.createdAt,
  });

  factory PrakaranItem.fromMap(Map<String, dynamic> map) {
    return PrakaranItem(
      id: map['id'],
      prakaranId: map['prakaran_id'],
      shabadId: map['shabad_id'],
      verseId: map['verse_id'],
      titleGurmukhi: map['title_gurmukhi'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'prakaran_id': prakaranId,
      'shabad_id': shabadId,
      'verse_id': verseId,
      'title_gurmukhi': titleGurmukhi,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
