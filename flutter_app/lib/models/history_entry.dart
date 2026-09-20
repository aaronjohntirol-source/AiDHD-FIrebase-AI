enum EntryType { mood, assessment }

enum MoodLabel { happy, okay, sad, stressed, overwhelmed }

extension MoodLabelExt on MoodLabel {
  String get displayName {
    switch (this) {
      case MoodLabel.happy:
        return 'Happy';
      case MoodLabel.okay:
        return 'Okay';
      case MoodLabel.sad:
        return 'Sad';
      case MoodLabel.stressed:
        return 'Stressed';
      case MoodLabel.overwhelmed:
        return 'Overwhelmed';
    }
  }

  String get emoji {
    switch (this) {
      case MoodLabel.happy:
        return '😊';
      case MoodLabel.okay:
        return '🙂';
      case MoodLabel.sad:
        return '😢';
      case MoodLabel.stressed:
        return '😰';
      case MoodLabel.overwhelmed:
        return '😩';
    }
  }

  static MoodLabel? fromString(String? s) {
    if (s == null) return null;
    return MoodLabel.values.firstWhere(
      (m) => m.displayName == s,
      orElse: () => MoodLabel.okay,
    );
  }
}

class HistoryEntry {
  final String id;
  final EntryType type;
  final String label;
  final String timestamp;
  final bool isToday; // true = Today, false = Yesterday
  final MoodLabel? mood;
  final int? score;
  final String? category;
  final String? note;
  final List<String> activities;

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.timestamp,
    required this.isToday,
    this.mood,
    this.score,
    this.category,
    this.note,
    this.activities = const [],
  });

  String get dayLabel => isToday ? 'Today' : 'Yesterday';

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        type: j['type'] == 'mood' ? EntryType.mood : EntryType.assessment,
        label: j['label'] as String,
        timestamp: j['timestamp'] as String,
        isToday: (j['day'] as String?) == 'Today',
        mood: MoodLabelExt.fromString(j['mood'] as String?),
        score: j['score'] as int?,
        category: j['category'] as String?,
        note: j['note'] as String?,
        activities: List<String>.from(j['activities'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == EntryType.mood ? 'mood' : 'assessment',
        'label': label,
        'timestamp': timestamp,
        'day': dayLabel,
        'mood': mood?.displayName,
        'score': score,
        'category': category,
        'note': note,
        'activities': activities,
      };
}
