import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

import '../widgets/header.dart';

class Profile extends StatefulWidget {
  final String profileId;
  final User currentUser;
  Profile({this.profileId, this.currentUser});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<Post> posts = [];
  bool isLoading = false;
  int postCount = 0;
  String postOrientation = "grid";
  bool isFollowing = false;
  int followersCount = 0;
  int followingsCount = 0;
  @override
  void initState() {
    super.initState();
    getUserPosts();
    getFollowers();
    getFollowings();
    checkIfFollowing();
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowings() async {
    QuerySnapshot snapshot = await followingsRef
        .document(widget.profileId)
        .collection("userFollowings")
        .getDocuments();
    setState(() {
      followingsCount = snapshot.documents.length;
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUser.id)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getUserPosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      posts = snapshot.documents.map((e) => Post.fromDocument(e)).toList();
      isLoading = false;
      postCount = snapshot.documents.length;
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EditProfile(currentUserId: widget.currentUser?.id),
        ));
  }

  buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  unFollowUser() {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    followingsRef
        .document(currentUser.id)
        .collection('userFollowings')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //delete activity feed item
    feedsRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  followUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUser.id)
        .setData({});
    followingsRef
        .document(currentUser.id)
        .collection('userFollowings')
        .document(widget.profileId)
        .setData({});
    //activity feed notification
    feedsRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUser.id)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": DateTime.now()
    });
  }

  buildProfileButton() {
    bool isOwnerOfProfile = widget.currentUser?.id == widget.profileId;
    if (isOwnerOfProfile) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(text: "Unfollow", function: unFollowUser);
    } else if (!isFollowing) {
      return buildButton(text: "Follow", function: followUser);
    }
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingsCount),
                          ],
                        ),
                        buildProfileButton(),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(top: 12.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 4.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 4.0),
                alignment: Alignment.centerLeft,
                child: Text(user.bio),
              ),
            ],
          ),
        );
      },
    );
  }

  buildPostList() {
    if (isLoading) {
      return circularProgress();
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(
          GridTile(
            child: PostTile(
              post: post,
            ),
          ),
        );
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  togglePostOrientation({String orientation}) {
    if (postOrientation != orientation) {
      setState(() {
        postOrientation = orientation;
      });
    }
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          onPressed: () => togglePostOrientation(orientation: "grid"),
          color: postOrientation == "grid"
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          icon: Icon(Icons.list),
          onPressed: () => togglePostOrientation(orientation: "list"),
          color: postOrientation == "list"
              ? Theme.of(context).primaryColor
              : Colors.grey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(),
          buildPostList(),
        ],
      ),
    );
  }
}
