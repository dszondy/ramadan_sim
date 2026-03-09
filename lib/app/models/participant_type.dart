enum ParticipantType { man, woman, other }

extension ParticipantTypeAssetPath on ParticipantType {
  String get playerAssetPath {
    return switch (this) {
      ParticipantType.man => 'assets/rs_man.webp',
      ParticipantType.woman => 'assets/rs_woman.webp',
      ParticipantType.other => 'assets/rs_other.webp',
    };
  }
}
