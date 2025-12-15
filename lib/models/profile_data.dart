import 'package:flutter/foundation.dart';

@immutable
class ProfileData {
  final int? id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final String? bio;

  const ProfileData({
    this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.email,
    this.phone,
    this.avatarUrl,
    this.role,
    this.bio,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] as int?,
      name: json['name']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar']?.toString(),
      role: json['role']?.toString(),
      bio: json['bio']?.toString(),
    );
  }
}
