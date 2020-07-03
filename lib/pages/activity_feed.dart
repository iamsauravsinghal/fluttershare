import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await feedsRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> activites = [];
    snapshot.documents.forEach((element) {
      activites.add(ActivityFeedItem.fromDocument(element));
    });
    return activites;
  }

  buildActivityFeed() {
    return FutureBuilder(
      future: getActivityFeed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        return ListView(
          children: snapshot.data,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: header(context, title: "Activity Feed", hasBackButton: false),
      body: buildActivityFeed(),
    );
  }
}

class ActivityFeedItem extends StatelessWidget {
  final String type;
  final String username;
  final String userId;
  final String userProfileImg;
  final String postId;
  final String mediaUrl;
  final String commentData;
  final Timestamp timestamp;
  Widget mediaPreview;
  String activityItemText;

  ActivityFeedItem(
      {this.commentData,
      this.mediaUrl,
      this.postId,
      this.timestamp,
      this.type,
      this.userId,
      this.userProfileImg,
      this.username});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      commentData: doc['commentData'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      timestamp: doc['timestamp'],
      type: doc['type'],
      userId: doc['userId'],
      userProfileImg: doc['userProfileImg'],
      username: doc['username'],
    );
  }
  navigateToPost(context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => navigateToPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: CachedNetworkImageProvider(mediaUrl),
                fit: BoxFit.cover,
              )),
            ),
          ),
        ),
      );
    } else {
      Text('');
    }
    if (type == 'like')
      activityItemText = "liked your post";
    else if (type == 'comment')
      activityItemText = "replied: $commentData";
    else if (type == 'follow')
      activityItemText = "is following you";
    else
      activityItemText = "Unknown type '$type'";
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, userId),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: username,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15.0)),
                TextSpan(
                  text: ' $activityItemText',
                  style: TextStyle(color: Colors.black, fontSize: 15.0),
                ),
              ]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: mediaPreview,
          subtitle: Text(
            timeago.format(
              timestamp.toDate(),
            ),
          ),
        ),
      ),
    );
  }

  showProfile(context, String userId) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Profile(
            currentUser: currentUser,
            profileId: userId,
          ),
        ));
  }
}
