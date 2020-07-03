const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { error } = require('firebase-functions/lib/logger');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore.
    document("/followers/{userId}/userFollowers/{followerId}").
    onCreate(async (snapshot, context) => {
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        //Create followed users posRef
        const followedUserPostRef = admin.firestore().collection("posts").doc(userId).collection("userPosts");
        //Create following user's timeline ref
        const timelineUserRef = admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts");

        const querySnapshot = await followedUserPostRef.get()
        querySnapshot.forEach((doc) => {
            const postId = doc.id;
            const postData = doc.data();
            timelineUserRef.doc(postId).set(postData);
        });
    });

exports.onDeleteFollower = functions.firestore.
    document("/followers/{userId}/userFollowers/{followerId}").
    onDelete(async (snapshot, context) => {
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        //Create following user's timeline ref
        const timelineUserRef = admin.firestore().collection("timeline").
            doc(followerId).collection("timelinePosts").where("ownerId", "==", userId);

        //delete posts
        const querySnapshot = timelineUserRef.get();
        (await querySnapshot).forEach((doc) => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });



    });

exports.onCreatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        //get all the followers
        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = userFollowersRef.get();

        (await querySnapshot).forEach((doc) => {
            const followerId = doc.id;

            admin.firestore().collection("timeline").doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated);
        });
    });

exports.onUpdatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {
        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        //get all the followers
        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = userFollowersRef.get();

        (await querySnapshot).forEach((doc) => {
            const followerId = doc.id;

            admin.firestore().collection("timeline").doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then((doc) => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
    });

exports.onDeletePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;

        //get all the followers
        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = userFollowersRef.get();

        (await querySnapshot).forEach((doc) => {
            const followerId = doc.id;

            admin.firestore().collection("timeline").doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then((doc) => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
    });

exports.onCreateActivityFeedItem = functions.firestore
    .document("/feeds/{userId}/feedItems/{activityFeedItem}")
    .onCreate(async (snapshot, context) => {
        console.log("Activity feed item created: ", snapshot.data());

        //get the user connected to the feed
        const userId = context.params.userId;
        const activityFeedItemData = snapshot.data();

        const userRef = admin.firestore().collection('users').doc(userId);
        const doc = await userRef.get();

        const androidNotificationToken = doc.data().androidNotificationToken;

        //check if the user has notification token. Send notification if they have the token
        if (androidNotificationToken) {
            //send notification
            sendNotification(androidNotificationToken, activityFeedItemData);
        } else {
            console.log('No token for the user');
        }

        function sendNotification(androidNotificationToken, activityFeedItemData) {
            let body;
            switch (activityFeedItemData.type) {
                case "comment":
                    body = `${activityFeedItemData.username} replied: ${activityFeedItemData.commentData}`;
                    break;
                case "like":
                    body = `${activityFeedItemData.username} liked your post`;
                    break;
                case "follow":
                    body = `${activityFeedItemData.username} started following you`;
                    break;
                default:
                    break;
            }

            //create message to send push notification
            const message = {
                notification: { body: body },
                // token: androidNotificationToken,
                data: { recipient: userId }
            }

            admin.messaging().sendToDevice(androidNotificationToken,message).then(
                (response) => console.log("Message sent successfully: ", response)
            ).catch(
                (error) => console.log("Error sending push notification: ", error)
            );
        }
    });