import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String photoUrl;
  final String email;
  final String displayName;
  final String bio;

  User(
      {this.id,
      this.username,
      this.displayName,
      this.email,
      this.photoUrl,
      this.bio});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      username: doc['username'],
      displayName: doc['displayName'],
      photoUrl: doc['photoUrl'],
      bio: doc['bio'],
      email: doc['email'],
    );
  }
}
