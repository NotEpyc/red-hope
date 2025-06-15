enum UserRole {
  person,
  organisation
}

class UserModel {
  final String? id;  // Optional because it might be auto-generated
  final String name;
  final String email;
  final String address;
  final int phone;
  final String gender;
  final String bloodGroup;
  final int age;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.phone = 0,
    this.gender = '',
    this.bloodGroup = '',
    this.age = 0,
  });  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'age': age,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? 0,
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      age: map['age'] ?? 0,
    );
  }
}
