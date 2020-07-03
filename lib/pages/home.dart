import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'activity_feed.dart';
import 'profile.dart';
import 'search.dart';
import 'timeline.dart';
import 'upload.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final feedsRef = Firestore.instance.collection('feeds');
final followersRef = Firestore.instance.collection('followers');
final followingsRef = Firestore.instance.collection('followings');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    //Detects when user signed in
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (error) {
      print('Error sign in: $error');
    });

    googleSignIn.signInSilently(suppressErrors: false).then((value) {
      handleSignIn(value);
    }, onError: (error) => print('Silent sign in error: $error'));
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotification() {
    _firebaseMessaging.getToken().then((token) {
      userRef
          .document(currentUser.id)
          .updateData({"androidNotificationToken": token});
    });
    if (Platform.isIOS) {
      _firebaseMessaging.requestNotificationPermissions
          .call(IosNotificationSettings(
        alert: true,
        badge: true,
        sound: true,
      ));
    }
    _firebaseMessaging.configure(
        onLaunch: (Map<String, dynamic> message) async {
      print("On Launch PCM: $message");
    }, onResume: (Map<String, dynamic> message) async {
      print("On Resume PCM: $message");
    }, onMessage: (Map<String, dynamic> message) async {
      print("On Message PCM: $message");
      if (message['data']['recipient'] == currentUser.id) {
        SnackBar snackbar =
            SnackBar(content: Text(message['notification']['body']));
        _scaffoldKey.currentState.showSnackBar(snackbar);
      }
    });
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": DateTime.now()
      });
      doc = await usersRef.document(user.id).get();
    }
    setState(() {
      currentUser = User.fromDocument(doc);
    });
    print('Current User: ${currentUser.username}');
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 200),
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(
            currentUser: currentUser,
          ),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id, currentUser: currentUser)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'PixShare',
              style: TextStyle(
                  fontFamily: "Signatra", fontSize: 90.0, color: Colors.white),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image:
                          AssetImage('assets/images/google_signin_button.png'),
                      fit: BoxFit.cover),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
