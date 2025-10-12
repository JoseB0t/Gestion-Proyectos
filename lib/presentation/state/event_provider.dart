import 'package:neurodrive/data/models/event_model.dart';

/// Simple in-memory event store (replace with storage_service when ready)
class EventProvider {
  EventProvider._private();
  static final EventProvider instance = EventProvider._private();

  final List<EventModel> _events = [];

  void addEvent(EventModel e) {
    _events.insert(0, e); // latest first
  }

  List<EventModel> getAllEvents() => List.unmodifiable(_events);

  void clearAll() => _events.clear();
}
