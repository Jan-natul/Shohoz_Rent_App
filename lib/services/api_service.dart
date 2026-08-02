import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final cloudinary = CloudinaryPublic('dz5ejkrht', 'Shohoz-rent', cache: false);

  static Future<Map<String, dynamic>> login(String email, String password) async {
    UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    DocumentSnapshot userDoc = await _db.collection('users').doc(res.user!.uid).get();
    if (!userDoc.exists) throw Exception("User not found in Database");

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', res.user!.uid);
    await prefs.setBool('isAdmin', userData['isAdmin'] ?? false);

    return userData;
  }

  static Future<void> register(String username, String email, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await _db.collection('users').doc(res.user!.uid).set({
      'uid': res.user!.uid,
      'username': username,
      'email': email,
      'isAdmin': false,
      'createdAt': DateTime.now(),
    });
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<List<String>> _uploadImages(List<XFile> images) async {
    List<String> imageUrls = [];
    for (var image in images) {
      Uint8List data = await image.readAsBytes();
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          data,
          identifier: DateTime.now().millisecondsSinceEpoch.toString(),
          folder: 'house_posts',
        ),
      );
      imageUrls.add(response.secureUrl);
    }
    return imageUrls;
  }

  static Future<String> uploadSingleImage(XFile image) async {
    Uint8List data = await image.readAsBytes();
    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromBytesData(
        data,
        identifier: DateTime.now().millisecondsSinceEpoch.toString(),
        folder: 'profile_pics',
      ),
    );
    return response.secureUrl;
  }

  static Future<Map<String, dynamic>> createPost(Map<String, dynamic> data, List<XFile> images) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Please login first");

    List<String> imageUrls = await _uploadImages(images);

    final postData = {
      ...Map<String, dynamic>.from(data['postData']),
      'userId': user.uid,
      'images': imageUrls,
      'isHidden': false,
      'createdAt': DateTime.now(),
    };

    DocumentReference docRef = await _db.collection('posts').add(postData);
    await _db.collection('postDetails').doc(docRef.id).set(
        Map<String, dynamic>.from(data['postDetail']));

    return {'id': docRef.id};
  }

  static Future<List<DocumentSnapshot>> getPosts({
    String city = '',
    String property = 'all',
    double? minPrice,
    double? maxPrice,
  }) async {

    Query queryRef = _db.collection('posts');

    queryRef = queryRef.where('isHidden', isEqualTo: false);


    if (city.isNotEmpty) {
      String searchCity = city.trim()[0].toUpperCase() + city.trim().substring(1).toLowerCase();
      queryRef = queryRef.where('city', isEqualTo: searchCity);
    }

    if (property != 'all') {
      queryRef = queryRef.where('property', isEqualTo: property);
    }

    if (minPrice != null && maxPrice != null) {
      queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice.toInt())
          .where('price', isLessThanOrEqualTo: maxPrice.toInt());
    }

    try {
      QuerySnapshot snapshot = await queryRef.get();
      return snapshot.docs;
    } catch (e) {
      print("Error getting posts: $e");
      return [];
    }
  }

  static Future<List<DocumentSnapshot>> getMyPosts() async {
    final user = _auth.currentUser;
    QuerySnapshot snapshot = await _db.collection('posts')
        .where('userId', isEqualTo: user?.uid).get();
    return snapshot.docs;
  }

  static Future<void> deletePost(String id) async {
    await _db.collection('posts').doc(id).delete();
    await _db.collection('postDetails').doc(id).delete();
  }

  static Future<void> sendMessage(String fullName, String email, String message) async {
    await _db.collection('complaints').add({
      'fullName': fullName,
      'email': email,
      'message': message,
      'createdAt': DateTime.now(),
      'status': 'pending'
    });
  }
  static Future<void> sendComplaintWithImages(String message, List<XFile> images) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      imageUrls = await _uploadImages(images);
    }

    await _db.collection('complaints').add({
      'userId': user.uid,
      'fullName': userData['username'] ?? userData['name'] ?? "Anonymous",
      'email': userData['email'] ?? user.email,
      'message': message,
      'images': imageUrls,
      'createdAt': DateTime.now(),
      'status': 'pending',
    });
  }
}