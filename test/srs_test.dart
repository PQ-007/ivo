import 'package:flutter_test/flutter_test.dart';
import 'package:ivo/services/study/srs.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('again resets reps, lowers ease, due today', () {
    final r = schedule(
      const SrsState(reps: 5, ease: 2.5, intervalDays: 30),
      Grade.again,
      now: now,
    );
    expect(r.reps, 0);
    expect(r.intervalDays, 0);
    expect(r.ease, lessThan(2.5));
    expect(r.due, now);
  });

  test('ease never drops below 1.3', () {
    var s = const SrsState(reps: 0, ease: 1.3, intervalDays: 0);
    for (var i = 0; i < 10; i++) {
      s = schedule(s, Grade.again, now: now).state;
    }
    expect(s.ease, greaterThanOrEqualTo(1.3));
  });

  test('first two good reviews follow 1 then 6 days', () {
    final r1 = schedule(const SrsState(), Grade.good, now: now);
    expect(r1.reps, 1);
    expect(r1.intervalDays, 1);
    final r2 = schedule(r1.state, Grade.good, now: now);
    expect(r2.reps, 2);
    expect(r2.intervalDays, 6);
  });

  test('intervals are monotonic by grade: easy >= good >= hard', () {
    const base = SrsState(reps: 3, ease: 2.5, intervalDays: 10);
    final hard = schedule(base, Grade.hard, now: now).intervalDays;
    final good = schedule(base, Grade.good, now: now).intervalDays;
    final easy = schedule(base, Grade.easy, now: now).intervalDays;
    expect(good, greaterThanOrEqualTo(hard));
    expect(easy, greaterThanOrEqualTo(good));
  });

  test('mature interval always moves forward', () {
    final r = schedule(
      const SrsState(reps: 4, ease: 1.3, intervalDays: 10),
      Grade.hard,
      now: now,
    );
    expect(r.intervalDays, greaterThan(10));
  });

  test('due date matches interval days', () {
    final r = schedule(const SrsState(), Grade.easy, now: now);
    expect(r.due, now.add(Duration(days: r.intervalDays)));
  });
}
