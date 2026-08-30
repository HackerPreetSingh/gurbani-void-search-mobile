class DisplaySettings {
  final bool showEnglishMeaning;
  final bool showPunjabiMeaning;
  final bool showTransliteration;
  final bool showHindi;
  final bool showVishrams;
  final bool showLarivaar;
  final double fontSizeGurmukhi;
  final double fontSizeHindi;
  final double fontSizeEnglish;
  final double fontSizeMeaning;
  final double fontSizePunjabiMeaning;

  const DisplaySettings({
    required this.showEnglishMeaning,
    required this.showPunjabiMeaning,
    required this.showTransliteration,
    required this.showHindi,
    required this.showVishrams,
    required this.showLarivaar,
    required this.fontSizeGurmukhi,
    required this.fontSizeHindi,
    required this.fontSizeEnglish,
    required this.fontSizeMeaning,
    required this.fontSizePunjabiMeaning,
  });

  factory DisplaySettings.defaults() {
    return const DisplaySettings(
      showEnglishMeaning: false,
      showPunjabiMeaning: true,
      showTransliteration: false,
      showHindi: false,
      showVishrams: true,
      showLarivaar: false,
      fontSizeGurmukhi: 28,
      fontSizeHindi: 20,
      fontSizeEnglish: 16,
      fontSizeMeaning: 16,
      fontSizePunjabiMeaning: 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showEnglishMeaning': showEnglishMeaning,
      'showPunjabiMeaning': showPunjabiMeaning,
      'showTransliteration': showTransliteration,
      'showHindi': showHindi,
      'showVishrams': showVishrams,
      'showLarivaar': showLarivaar,
      'fontSizeGurmukhi': fontSizeGurmukhi,
      'fontSizeHindi': fontSizeHindi,
      'fontSizeEnglish': fontSizeEnglish,
      'fontSizeMeaning': fontSizeMeaning,
      'fontSizePunjabiMeaning': fontSizePunjabiMeaning,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    final d = DisplaySettings.defaults();
    return DisplaySettings(
      showEnglishMeaning: json['showEnglishMeaning'] ?? d.showEnglishMeaning,
      showPunjabiMeaning: json['showPunjabiMeaning'] ?? d.showPunjabiMeaning,
      showTransliteration: json['showTransliteration'] ?? d.showTransliteration,
      showHindi: json['showHindi'] ?? d.showHindi,
      showVishrams: json['showVishrams'] ?? d.showVishrams,
      showLarivaar: json['showLarivaar'] ?? d.showLarivaar,
      fontSizeGurmukhi: (json['fontSizeGurmukhi'] as num?)?.toDouble() ?? d.fontSizeGurmukhi,
      fontSizeHindi: (json['fontSizeHindi'] as num?)?.toDouble() ?? d.fontSizeHindi,
      fontSizeEnglish: (json['fontSizeEnglish'] as num?)?.toDouble() ?? d.fontSizeEnglish,
      fontSizeMeaning: (json['fontSizeMeaning'] as num?)?.toDouble() ?? d.fontSizeMeaning,
      fontSizePunjabiMeaning: (json['fontSizePunjabiMeaning'] as num?)?.toDouble() ?? d.fontSizePunjabiMeaning,
    );
  }

  DisplaySettings copyWith({
    bool? showEnglishMeaning,
    bool? showPunjabiMeaning,
    bool? showTransliteration,
    bool? showHindi,
    bool? showVishrams,
    bool? showLarivaar,
    double? fontSizeGurmukhi,
    double? fontSizeHindi,
    double? fontSizeEnglish,
    double? fontSizeMeaning,
    double? fontSizePunjabiMeaning,
  }) {
    return DisplaySettings(
      showEnglishMeaning: showEnglishMeaning ?? this.showEnglishMeaning,
      showPunjabiMeaning: showPunjabiMeaning ?? this.showPunjabiMeaning,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showHindi: showHindi ?? this.showHindi,
      showVishrams: showVishrams ?? this.showVishrams,
      showLarivaar: showLarivaar ?? this.showLarivaar,
      fontSizeGurmukhi: fontSizeGurmukhi ?? this.fontSizeGurmukhi,
      fontSizeHindi: fontSizeHindi ?? this.fontSizeHindi,
      fontSizeEnglish: fontSizeEnglish ?? this.fontSizeEnglish,
      fontSizeMeaning: fontSizeMeaning ?? this.fontSizeMeaning,
      fontSizePunjabiMeaning: fontSizePunjabiMeaning ?? this.fontSizePunjabiMeaning,
    );
  }
}
