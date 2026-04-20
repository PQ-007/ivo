import 'package:supabase_flutter/supabase_flutter.dart';

class StudySummary {
  final int totalReviewed;
  final int streakDays;
  final int daysActive;
  final double accuracy;

  const StudySummary({
    required this.totalReviewed,
    required this.streakDays,
    required this.daysActive,
    required this.accuracy,
  });

  static const empty = StudySummary(totalReviewed: 0, streakDays: 0, daysActive: 0, accuracy: 0);
}

class ProfileService {
  final _supabase = Supabase.instance.client;
  String? get _uid => _supabase.auth.currentUser?.id;

  Future<StudySummary> getStudySummary() async {
    final uid = _uid;
    if (uid == null) return StudySummary.empty;

    try {
      final reviews = await _supabase
          .from('flashcard_reviews')
          .select('quality, reviewed_at')
          .eq('user_id', uid)
          .order('reviewed_at', ascending: false);

      if (reviews.isEmpty) return StudySummary.empty;

      final total = reviews.length;
      final good = reviews.where((r) => (r['quality'] as int) >= 3).length;
      final accuracy = total == 0 ? 0.0 : good / total;

      // Count distinct days
      final days = reviews
          .map((r) => DateTime.parse(r['reviewed_at'] as String).toLocal())
          .map((d) => '${d.year}-${d.month}-${d.day}')
          .toSet();

      // Calculate streak (consecutive days ending today)
      final sortedDays = days.toList()..sort((a, b) => b.compareTo(a));
      int streak = 0;
      DateTime check = DateTime.now();
      for (final day in sortedDays) {
        final d = DateTime.parse(day);
        final diff = check.difference(d).inDays;
        if (diff <= 1) {
          streak++;
          check = d;
        } else {
          break;
        }
      }

      return StudySummary(
        totalReviewed: total,
        streakDays: streak,
        daysActive: days.length,
        accuracy: accuracy,
      );
    } catch (_) {
      return StudySummary.empty;
    }
  }
}
