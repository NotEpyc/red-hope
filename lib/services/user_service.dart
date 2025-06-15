import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/organisation_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> createUser(dynamic user, String uid, {bool isOrganisation = false}) async {
    try {
      debugPrint('Starting user/organisation creation process...');
      debugPrint('isOrganisation parameter: $isOrganisation');
      debugPrint('User type: ${user.runtimeType}');
      
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      
      final collection = isOrganisation ? 'organisations' : 'users';
      final data = user.toMap(); // Both models have toMap now
      
      debugPrint('Creating document in $collection with auth UID: $uid');
      debugPrint('Data to be saved: ${data.toString()}');
      
      // Validate data types before saving
      if (data['name'] is! String || data['email'] is! String) {
        throw Exception('Invalid data types for name or email');
      }
      
      // Use the Firebase Auth UID as the document ID
      await _firestore
          .collection(collection)
          .doc(uid)
          .set(data)
          .timeout(Duration(seconds: 10)); // Add timeout
          
      // Verify document was created using the correct collection
      final docSnapshot = await _firestore
          .collection(collection)  // Use the same collection as above
          .doc(uid)
          .get();
          
      if (!docSnapshot.exists) {
        throw Exception('Document creation failed - document does not exist after creation');
      }
      
      debugPrint('✅ Document successfully created in $collection collection');
      debugPrint('✅ Document data: ${docSnapshot.data()}');
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
      throw e;
    }
  }

  Future<dynamic> getUser(String userId, UserRole role) async {
    final collection = role == UserRole.person ? 'users' : 'organisations';
    
    final doc = await _firestore
        .collection(collection)
        .doc(userId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    
    return role == UserRole.person
      ? UserModel.fromMap(doc.data()!, doc.id)
      : OrganisationModel.fromMap(doc.data()!, doc.id);
  }
}
