import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Vehicles
  Stream<List<VehicleModel>> getVehicles() {
    return _db.collection('vehicles').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList());
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    await _db.collection('vehicles').add(vehicle.toMap());
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    await _db.collection('vehicles').doc(vehicle.id).update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String id) async {
    await _db.collection('vehicles').doc(id).delete();
  }

  // Packages
  Stream<List<TourPackageModel>> getPackages() {
    return _db.collection('packages').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TourPackageModel.fromFirestore(doc)).toList());
  }

  Future<void> addPackage(TourPackageModel package) async {
    await _db.collection('packages').add(package.toMap());
  }

  // Bookings
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').add(booking.toMap());
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  Stream<List<BookingModel>> getAllBookings() {
    return _db.collection('bookings').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _db.collection('bookings').doc(id).update({'status': status.name});
  }
}

class ActionService {
  static Future<void> makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  static Future<void> openWhatsApp(String phoneNumber, String message) async {
    final Uri url = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openMap(String address) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

