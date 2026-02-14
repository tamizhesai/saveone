class UserModel {
  final int? id;
  final String name;
  final String email;
  final String phoneNumber;
  final String nomineeNumber;
  final int? fingerprintId;
  final String? profilePictureUrl;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.nomineeNumber,
    this.fingerprintId,
    this.profilePictureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      nomineeNumber: json['nominee_number'],
      fingerprintId: json['fingerprint_id'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'nominee_number': nomineeNumber,
      'fingerprint_id': fingerprintId,
      'profile_picture_url': profilePictureUrl,
    };
  }
}
