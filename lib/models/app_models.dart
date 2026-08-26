import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, rejected, cancelled, completed }

class VehicleModel {
  final String id;
  final String name;
  final String type; // SUV, Bus, Sedan, Coaster
  final int capacity;
  final double pricePerDay;
  final List<String> images;
  final List<String> features;
  final bool isAvailable;

  VehicleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.pricePerDay,
    required this.images,
    required this.features,
    this.isAvailable = true,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      capacity: data['capacity'] ?? 4,
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      features: List<String>.from(data['features'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'capacity': capacity,
      'pricePerDay': pricePerDay,
      'images': images,
      'features': features,
      'isAvailable': isAvailable,
    };
  }
}

class TourPackageModel {
  final String id;
  final String title;
  final String destination;
  final int durationDays;
  final double price;
  final List<String> images;
  final String description;
  final List<String> inclusions;

  TourPackageModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.durationDays,
    required this.price,
    required this.images,
    required this.description,
    required this.inclusions,
  });

  factory TourPackageModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TourPackageModel(
      id: doc.id,
      title: data['title'] ?? '',
      destination: data['destination'] ?? '',
      durationDays: data['durationDays'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      description: data['description'] ?? '',
      inclusions: List<String>.from(data['inclusions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'destination': destination,
      'durationDays': durationDays,
      'price': price,
      'images': images,
      'description': description,
      'inclusions': inclusions,
    };
  }
}

class BookingModel {
  final String id;
  final String userId;
  final String customerName;
  final String phone;
  final String whatsapp;
  final String? itemTitle; // Vehicle name or Tour title
  final String bookingType; // 'vehicle' or 'tour'
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropLocation;
  final int passengers;
  final double totalPrice;
  final BookingStatus status;
  final String specialInstructions;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.whatsapp,
    required this.itemTitle,
    required this.bookingType,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropLocation,
    required this.passengers,
    required this.totalPrice,
    required this.status,
    required this.specialInstructions,
    required this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      phone: data['phone'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      itemTitle: data['itemTitle'] ?? '',
      bookingType: data['bookingType'] ?? 'vehicle',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pickupLocation: data['pickupLocation'] ?? '',
      dropLocation: data['dropLocation'] ?? '',
      passengers: data['passengers'] ?? 1,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      specialInstructions: data['specialInstructions'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'phone': phone,
      'whatsapp': whatsapp,
      'itemTitle': itemTitle,
      'bookingType': bookingType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'passengers': passengers,
      'totalPrice': totalPrice,
      'status': status.name,
      'specialInstructions': specialInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

