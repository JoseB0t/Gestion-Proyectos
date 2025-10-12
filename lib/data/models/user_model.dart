class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String plate;
  final String emergencyContact;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.plate,
    required this.emergencyContact,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        plate: j['plate'] ?? '',
        emergencyContact: j['emergencyContact'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'plate': plate,
        'emergencyContact': emergencyContact,
      };
}
