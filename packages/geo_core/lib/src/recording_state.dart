/// A túra adatbázisban tárolt státusza (spec 7. fejezet).
enum TrackStatus { recording, paused, finished }

/// A rögzítés állapota. Az `interrupted` nem tárolt: induláskor vezetjük le.
enum RecState { idle, recording, paused, interrupted, finished }

/// A rögzítési állapotgép eseményei.
enum RecEvent {
  start,
  pause,
  resume,
  finish,

  /// Az új folyamat félbemaradt rögzítést talált az adatbázisban.
  foundUnfinished,
}

/// Érvénytelen állapotátmenet.
class InvalidTransitionError extends StateError {
  InvalidTransitionError(this.from, this.event)
    : super('Érvénytelen átmenet: $from állapotban nem lehet $event.');

  final RecState from;
  final RecEvent event;
}

const Map<RecState, Map<RecEvent, RecState>> _transitions = {
  RecState.idle: {
    RecEvent.start: RecState.recording,
    RecEvent.foundUnfinished: RecState.interrupted,
  },
  RecState.recording: {
    RecEvent.pause: RecState.paused,
    RecEvent.finish: RecState.finished,
    RecEvent.foundUnfinished: RecState.interrupted,
  },
  RecState.paused: {
    RecEvent.resume: RecState.recording,
    RecEvent.finish: RecState.finished,
  },
  RecState.interrupted: {
    RecEvent.resume: RecState.recording,
    RecEvent.finish: RecState.finished,
  },
  RecState.finished: {},
};

/// Az `event` érvényes-e a `from` állapotban.
bool canTransition(RecState from, RecEvent event) =>
    _transitions[from]!.containsKey(event);

/// A következő állapot; érvénytelen átmenetnél [InvalidTransitionError].
RecState nextState(RecState from, RecEvent event) {
  final next = _transitions[from]![event];
  if (next == null) throw InvalidTransitionError(from, event);
  return next;
}

/// Indulási állapot: ha a legutóbbi túra `recording` státuszú, de a folyamat
/// új, akkor a rögzítés megszakadt.
RecState deriveOnStartup({
  required TrackStatus? latestTrackStatus,
  required bool isNewProcess,
}) {
  if (isNewProcess && latestTrackStatus == TrackStatus.recording) {
    return nextState(RecState.idle, RecEvent.foundUnfinished);
  }
  return RecState.idle;
}
