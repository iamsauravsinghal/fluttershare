import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({this.postId, this.postMediaUrl, this.postOwnerId});
  @override
  CommentsState createState() => CommentsState(
      postId: this.postId,
      postMediaUrl: this.postMediaUrl,
      postOwnerId: this.postOwnerId);
}

class CommentsState extends State<Comments> {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  TextEditingController commentController = TextEditingController();
  CommentsState({this.postId, this.postMediaUrl, this.postOwnerId});

  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection("comments")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        List<Comment> comments = [];
        snapshot.data.documents.forEach((comment) {
          return comments.add(Comment.fromDocument(comment));
        });
        return Column(
          children: comments,
        );
      },
    );
  }

  addComment() {
    commentsRef.document(postId).collection("comments").add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });
    if (postOwnerId != currentUser.id) {
      feedsRef.document(postOwnerId).collection("feedItems").add({
        "type": "comment",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": postMediaUrl,
        "commentData": commentController.text,
        "timestamp": DateTime.now(),
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
              child: ListView(
            children: <Widget>[buildComments()],
          )),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: () => addComment(),
              child: Text("Post"),
              borderSide: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment(
      {this.username,
      this.userId,
      this.avatarUrl,
      this.comment,
      this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '$username ',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    )),
                TextSpan(
                  text: comment,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ),
          // title: Row(
          //   children: <Widget>[
          //     Text(
          //       '$username ',
          //       style: TextStyle(fontWeight: FontWeight.bold),
          //     ),
          //     Text(comment),
          //   ],
          // ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
      ],
    );
  }
}
