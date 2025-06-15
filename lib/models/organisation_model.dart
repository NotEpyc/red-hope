class OrganisationModel {
  final String? id;
  final String name;
  final String address;
  final int phone;
  final String email;
  final String type;

  OrganisationModel({
    this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.phone = 0,
    this.type = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'type': type,
    };
  }

  factory OrganisationModel.fromMap(Map<String, dynamic> map, String id) {
    return OrganisationModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? 0,
      type: map['type'] ?? '',
    );
  }
}
