import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

void main() {
  const valid = <(RecState, RecEvent, RecState)>[
    (RecState.idle, RecEvent.start, RecState.recording),
    (RecState.idle, RecEvent.foundUnfinished, RecState.interrupted),
    (RecState.recording, RecEvent.pause, RecState.paused),
    (RecState.recording, RecEvent.finish, RecState.finished),
    (RecState.recording, RecEvent.foundUnfinished, RecState.interrupted),
    (RecState.paused, RecEvent.resume, RecState.recording),
    (RecState.paused, RecEvent.finish, RecState.finished),
    (RecState.interrupted, RecEvent.resume, RecState.recording),
    (RecState.interrupted, RecEvent.finish, RecState.finished),
  ];

  group('érvényes átmenetek', () {
    for (final (from, event, to) in valid) {
      test('$from --$event--> $to', () {
        expect(canTransition(from, event), isTrue);
        expect(nextState(from, event), to);
      });
    }
  });

  group('érvénytelen átmenetek', () {
    for (final from in RecState.values) {
      for (final event in RecEvent.values) {
        if (valid.any((v) => v.$1 == from && v.$2 == event)) continue;
        test('$from --$event--> hiba', () {
          expect(canTransition(from, event), isFalse);
          expect(
            () => nextState(from, event),
            throwsA(
              isA<InvalidTransitionError>()
                  .having((e) => e.from, 'from', from)
                  .having((e) => e.event, 'event', event),
            ),
          );
        });
      }
    }
  });

  group('deriveOnStartup', () {
    test('új folyamat + recording státusz: megszakadt', () {
      expect(
        deriveOnStartup(
          latestTrackStatus: TrackStatus.recording,
          isNewProcess: true,
        ),
        RecState.interrupted,
      );
    });

    test('ugyanaz a folyamat: nem megszakadt', () {
      expect(
        deriveOnStartup(
          latestTrackStatus: TrackStatus.recording,
          isNewProcess: false,
        ),
        RecState.idle,
      );
    });

    test('lezárt, szüneteltetett vagy nincs túra: idle', () {
      for (final s in [TrackStatus.finished, TrackStatus.paused, null]) {
        expect(
          deriveOnStartup(latestTrackStatus: s, isNewProcess: true),
          RecState.idle,
        );
      }
    });
  });

  test('a hibaüzenet érthető', () {
    expect(
      InvalidTransitionError(RecState.finished, RecEvent.start).message,
      contains('finished'),
    );
  });
}
