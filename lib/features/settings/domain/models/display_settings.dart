enum BaniMaryada {
  sgpc,     // SGPC / Darbar Sahib Maryada (DEFAULT)
  taksal,   // Damdami Taksal Maryada
  budhaDal, // Shiromani Panth Akali Budha Dal Maryada
  medium,   // Medium / Standard Length
}

class DisplaySettings {
  final bool showEnglishMeaning;
  final bool showPunjabiMeaning;
  final bool showTransliteration;
  final bool showHindi;
  final bool showVishrams;
  final bool showLarivaar;
  final bool showJaapSahibParagraphView;
  final double fontSizeGurmukhi;
  final double fontSizeHindi;
  final double fontSizeEnglish;
  final double fontSizeMeaning;
  final double fontSizePunjabiMeaning;
  final BaniMaryada maryada;

  const DisplaySettings({
    required this.showEnglishMeaning,
    required this.showPunjabiMeaning,
    required this.showTransliteration,
    required this.showHindi,
    required this.showVishrams,
    required this.showLarivaar,
    this.showJaapSahibParagraphView = true,
    required this.fontSizeGurmukhi,
    required this.fontSizeHindi,
    required this.fontSizeEnglish,
    required this.fontSizeMeaning,
    required this.fontSizePunjabiMeaning,
    this.maryada = BaniMaryada.sgpc,
  });

  factory DisplaySettings.defaults() {
    return const DisplaySettings(
      showEnglishMeaning: false,
      showPunjabiMeaning: true,
      showTransliteration: false,
      showHindi: false,
      showVishrams: true,
      showLarivaar: false,
      showJaapSahibParagraphView: true,
      fontSizeGurmukhi: 30,
      fontSizeHindi: 22,
      fontSizeEnglish: 18,
      fontSizeMeaning: 18,
      fontSizePunjabiMeaning: 22,
      maryada: BaniMaryada.sgpc,
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
      'showJaapSahibParagraphView': showJaapSahibParagraphView,
      'fontSizeGurmukhi': fontSizeGurmukhi,
      'fontSizeHindi': fontSizeHindi,
      'fontSizeEnglish': fontSizeEnglish,
      'fontSizeMeaning': fontSizeMeaning,
      'fontSizePunjabiMeaning': fontSizePunjabiMeaning,
      'maryada': maryada.name,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    final d = DisplaySettings.defaults();
    final maryadaStr = json['maryada'] as String?;
    final maryadaVal = BaniMaryada.values.firstWhere(
      (m) => m.name == maryadaStr,
      orElse: () => BaniMaryada.sgpc,
    );

    return DisplaySettings(
      showEnglishMeaning: json['showEnglishMeaning'] ?? d.showEnglishMeaning,
      showPunjabiMeaning: json['showPunjabiMeaning'] ?? d.showPunjabiMeaning,
      showTransliteration: json['showTransliteration'] ?? d.showTransliteration,
      showHindi: json['showHindi'] ?? d.showHindi,
      showVishrams: json['showVishrams'] ?? d.showVishrams,
      showLarivaar: json['showLarivaar'] ?? d.showLarivaar,
      showJaapSahibParagraphView: json['showJaapSahibParagraphView'] ?? d.showJaapSahibParagraphView,
      fontSizeGurmukhi: (json['fontSizeGurmukhi'] as num?)?.toDouble() ?? d.fontSizeGurmukhi,
      fontSizeHindi: (json['fontSizeHindi'] as num?)?.toDouble() ?? d.fontSizeHindi,
      fontSizeEnglish: (json['fontSizeEnglish'] as num?)?.toDouble() ?? d.fontSizeEnglish,
      fontSizeMeaning: (json['fontSizeMeaning'] as num?)?.toDouble() ?? d.fontSizeMeaning,
      fontSizePunjabiMeaning: (json['fontSizePunjabiMeaning'] as num?)?.toDouble() ?? d.fontSizePunjabiMeaning,
      maryada: maryadaVal,
    );
  }

  DisplaySettings copyWith({
    bool? showEnglishMeaning,
    bool? showPunjabiMeaning,
    bool? showTransliteration,
    bool? showHindi,
    bool? showVishrams,
    bool? showLarivaar,
    bool? showJaapSahibParagraphView,
    double? fontSizeGurmukhi,
    double? fontSizeHindi,
    double? fontSizeEnglish,
    double? fontSizeMeaning,
    double? fontSizePunjabiMeaning,
    BaniMaryada? maryada,
  }) {
    return DisplaySettings(
      showEnglishMeaning: showEnglishMeaning ?? this.showEnglishMeaning,
      showPunjabiMeaning: showPunjabiMeaning ?? this.showPunjabiMeaning,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showHindi: showHindi ?? this.showHindi,
      showVishrams: showVishrams ?? this.showVishrams,
      showLarivaar: showLarivaar ?? this.showLarivaar,
      showJaapSahibParagraphView: showJaapSahibParagraphView ?? this.showJaapSahibParagraphView,
      fontSizeGurmukhi: fontSizeGurmukhi ?? this.fontSizeGurmukhi,
      fontSizeHindi: fontSizeHindi ?? this.fontSizeHindi,
      fontSizeEnglish: fontSizeEnglish ?? this.fontSizeEnglish,
      fontSizeMeaning: fontSizeMeaning ?? this.fontSizeMeaning,
      fontSizePunjabiMeaning: fontSizePunjabiMeaning ?? this.fontSizePunjabiMeaning,
      maryada: maryada ?? this.maryada,
    );
  }
}
