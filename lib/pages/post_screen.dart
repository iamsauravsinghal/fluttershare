import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';

class PostScreen extends StatelessWidget {
  final String postId;
  final String userId;
  PostScreen({this.postId, this.userId});

  handlePost() {
    return FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        Post post = Post.fromDocument(snapshot.data);
        return Scaffold(
          appBar: header(context, title: "Photo"),
          body: post,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return handlePost();
  }
}
