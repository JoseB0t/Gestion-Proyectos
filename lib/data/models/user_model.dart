class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String plate;
  final String emergencyContact;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.plate,
    required this.emergencyContact,
    this.role = 'user',
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        plate: j['plate'] ?? '',
        emergencyContact: j['emergencyContact'] ?? '',
        role: j['role'] ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'plate': plate,
        'emergencyContact': emergencyContact,
        'role': role,
      };

      bool get isAdmin => role == 'admin';
      bool get isUser => role == 'user';
}
