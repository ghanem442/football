class BilingualMessage {
  final String en;
  final String ar;

  const BilingualMessage({required this.en, required this.ar});

  factory BilingualMessage.fromJson(Map<String, dynamic> json) {
    return BilingualMessage(
      en: (json['en'] ?? '').toString(),
      ar: (json['ar'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'en': en, 'ar': ar};
}