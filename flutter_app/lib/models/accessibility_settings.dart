enum TextSize { small, medium, large }

class AccessibilitySettings {
  final TextSize textSize;
  final bool highContrast;
  final bool easyFont;

  const AccessibilitySettings({
    this.textSize = TextSize.medium,
    this.highContrast = false,
    this.easyFont = false,
  });

  AccessibilitySettings copyWith({
    TextSize? textSize,
    bool? highContrast,
    bool? easyFont,
  }) =>
      AccessibilitySettings(
        textSize: textSize ?? this.textSize,
        highContrast: highContrast ?? this.highContrast,
        easyFont: easyFont ?? this.easyFont,
      );

  factory AccessibilitySettings.fromJson(Map<String, dynamic> j) =>
      AccessibilitySettings(
        textSize: TextSize.values.firstWhere(
          (t) => t.name == (j['textSize'] as String?)?.toLowerCase(),
          orElse: () => TextSize.medium,
        ),
        highContrast: j['highContrast'] as bool? ?? false,
        easyFont: j['easyFont'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'textSize': textSize.name,
        'highContrast': highContrast,
        'easyFont': easyFont,
      };

  double get fontScaleFactor {
    switch (textSize) {
      case TextSize.small:
        return 0.88;
      case TextSize.medium:
        return 1.0;
      case TextSize.large:
        return 1.14;
    }
  }
}
