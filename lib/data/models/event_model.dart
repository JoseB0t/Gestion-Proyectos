class EventModel {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> telemetry;
  String status; // pending, sent, failed

  EventModel({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.telemetry,
    this.status = 'pending',
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: j['id'] as String,
        type: j['type'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        telemetry: Map<String, dynamic>.from(j['telemetry'] as Map),
        status: j['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'telemetry': telemetry,
        'status': status,
      };
}
