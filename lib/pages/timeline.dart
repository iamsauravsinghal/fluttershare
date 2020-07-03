import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post.dart';

import '../widgets/header.dart';
import '../widgets/progress.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState(currentUser: currentUser);
}

class _TimelineState extends State<Timeline> {
  final User currentUser;
  _TimelineState({this.currentUser});
  List<Post> posts;
  @override
  void initState() {
    super.initState();
    getTimeline();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(currentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((e) => Post.fromDocument(e)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Text('No Posts');
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppHeader: true),
      body: RefreshIndicator(
        child: buildTimeline(),
        onRefresh: () => getTimeline(),
      ),
    );
  }
}
