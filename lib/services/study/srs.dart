// SM-2 spaced-repetition scheduler (pure, side-effect free).
//
// A simplified, well-tested variant of the classic SuperMemo-2 algorithm with
// four Anki-style grades. Kept behind this small interface so it can be swapped
// for FSRS later without touching callers.
//
// Guarantees (covered by test/srs_test.dart):
//  - `again` resets the card (reps 0, due today) and lowers ease.
//  - intervals are monotonic by grade: easy >= good >= hard (for a review).
//  - ease never drops below 1.3.

import 'dart:math' as math;

enum Grade { again, hard, good, easy }

const double _minEase = 1.3;
const double _startEase = 2.5;
const double _easyBonus = 1.3;
const double _hardMultiplier = 1.2;

/// Mutable-free snapshot of a card's scheduling state.
class SrsState {
  final int reps; // consecutive successful reviews
  final double ease; // ease factor (EF), >= 1.3
  final int intervalDays; // current interval in days

  const SrsState({
    this.reps = 0,
    this.ease = _startEase,
    this.intervalDays = 0,
  });
}

/// Result of scheduling a review: the new state plus the absolute due time.
class SrsResult {
  final int reps;
  final double ease;
  final int intervalDays;
  final DateTime due;

  const SrsResult({
    required this.reps,
    required this.ease,
    required this.intervalDays,
    required this.due,
  });

  SrsState get state =>
      SrsState(reps: reps, ease: ease, intervalDays: intervalDays);
}

/// Compute the next scheduling state for [state] given the user's [grade].
/// [now] is injectable for testing.
SrsResult schedule(SrsState state, Grade grade, {DateTime? now}) {
  final today = now ?? DateTime.now();

  if (grade == Grade.again) {
    // Lapse: reset reps, drop ease, review again today.
    final ease = math.max(_minEase, state.ease - 0.20);
    return SrsResult(
      reps: 0,
      ease: ease,
      intervalDays: 0,
      due: today,
    );
  }

  // Adjust ease per SM-2 quality (hard=3, good=4, easy=5).
  final q = grade == Grade.hard
      ? 3
      : grade == Grade.good
          ? 4
          : 5;
  var ease = state.ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
  ease = math.max(_minEase, ease);

  final reps = state.reps + 1;
  int interval;
  if (reps == 1) {
    interval = grade == Grade.easy ? 4 : 1;
  } else if (reps == 2) {
    interval = grade == Grade.hard ? 4 : 6;
  } else {
    final base = state.intervalDays <= 0 ? 1 : state.intervalDays;
    switch (grade) {
      case Grade.hard:
        interval = (base * _hardMultiplier).round();
        break;
      case Grade.good:
        interval = (base * ease).round();
        break;
      case Grade.easy:
        interval = (base * ease * _easyBonus).round();
        break;
      case Grade.again:
        interval = 0; // unreachable (handled above)
        break;
    }
    interval = math.max(interval, base + 1); // always move forward
  }

  return SrsResult(
    reps: reps,
    ease: ease,
    intervalDays: interval,
    due: DateTime(today.year, today.month, today.day).add(Duration(days: interval)),
  );
}
