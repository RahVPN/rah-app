enum AetherState { idle, starting, connected, stopping, error }

class AetherEvent {
  const AetherEvent({required this.state, this.message});

  final AetherState state;
  final String? message;
}
