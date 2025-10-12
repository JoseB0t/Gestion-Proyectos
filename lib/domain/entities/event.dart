class Event {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> telemetrySnapshot;
  String status;

  Event({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.telemetrySnapshot,
    this.status = 'pending',
  });
}
