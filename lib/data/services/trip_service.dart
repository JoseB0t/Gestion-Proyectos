import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class TripService {
  Position? _startPosition;
  DateTime? _startTime;
  bool isTripActive = false;

  Future<void> startTrip() async {
    _startTime = DateTime.now();
    _startPosition = await Geolocator.getCurrentPosition();
    isTripActive = true;
  }

  Future<void> endTrip() async {
    final endTime = DateTime.now();
    final endPosition = await Geolocator.getCurrentPosition();

    final duration = endTime.difference(_startTime!);
    final distanceMeters = Geolocator.distanceBetween(
      _startPosition!.latitude,
      _startPosition!.longitude,
      endPosition.latitude,
      endPosition.longitude,
    );
    final distanceKm = (distanceMeters / 1000).toStringAsFixed(2);

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('trips')
        .add({
      'title': 'Viaje del ${_startTime!.day}/${_startTime!.month}',
      'startTime': _startTime,
      'endTime': endTime,
      'duration': '${duration.inMinutes} min',
      'distance': '$distanceKm km',
      'rating': 'Pendiente',
    });

    isTripActive = false;
    _startPosition = null;
    _startTime = null;
  }
}
