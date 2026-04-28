import 'dart:developer' as dev;

class ContactModel {
  const ContactModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.currentBalance,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final double? currentBalance;

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    dev.log(json.toString());
    final first = json['FirstName'] as String? ?? '';
    final last = json['LastName'] as String? ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');

    return ContactModel(
      id: json['Id'] as String,
      fullName: full.isNotEmpty ? full : 'Unknown',
      email: json['Email'] as String?,
      phone: json['Phone'] as String?,
      currentBalance: (json['Current_Balance__c'] as num?)?.toDouble(),
    );
  }

  ContactModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    double? currentBalance,
  }) {
    return ContactModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
