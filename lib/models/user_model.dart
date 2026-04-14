class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final String? phoneNumber;
  final String? address;
  final String? nip;
  final String? kelas;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    this.address,
    this.nip,
    this.kelas,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      photoUrl: json['photo_url'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      nip: json['nip'],
      kelas: json['kelas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'address': address,
      'nip': nip,
      'kelas': kelas,
    };
  }
}
