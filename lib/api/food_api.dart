import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:foodlab/model/food.dart';
import 'package:foodlab/notifier/auth_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodlab/model/user.dart';
import 'package:foodlab/screens/login_signup_page.dart';
import 'package:foodlab/screens/navigation_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

//USER PART
login(User user, AuthNotifier authNotifier, BuildContext context) async {
  AuthResult authResult = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: user.email, password: user.password)
      .catchError((error) => print(error));

  if (authResult != null) {
    FirebaseUser firebaseUser = authResult.user;
    if (firebaseUser != null) {
      print("Log In: $firebaseUser");
      authNotifier.setUser(firebaseUser);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (BuildContext context) {
          return NavigationBarPage();
        }),
      );
    }
  }
}

signUp(User user, AuthNotifier authNotifier, BuildContext context) async {
  AuthResult authResult = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(
          email: user.email.trim(), password: user.password)
      .catchError((error) => print(error));

  if (authResult != null) {
    UserUpdateInfo updateInfo = UserUpdateInfo();
    updateInfo.displayName = user.displayName;
    FirebaseUser firebaseUser = authResult.user;

    if (firebaseUser != null) {
      await firebaseUser.updateProfile(updateInfo);
      await firebaseUser.reload();

      print("Sign Up: $firebaseUser");

      FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
      authNotifier.setUser(currentUser);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (BuildContext context) {
          return NavigationBarPage();
        }),
      );
    }
  }
}

signOut(AuthNotifier authNotifier, BuildContext context) async {
  await FirebaseAuth.instance.signOut();

  authNotifier.setUser(null);
  print('log out');
  Navigator.push(
    context,
    MaterialPageRoute(builder: (BuildContext context) {
      return LoginPage();
    }),
  );
}

initializeCurrentUser(AuthNotifier authNotifier, BuildContext context) async {
  FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
  if (firebaseUser != null) {
    authNotifier.setUser(firebaseUser);
  }
}

Future<String> getCurrentUserUuid() async {
  FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
  String uid = firebaseUser.uid;
  print('uid of just now user: $uid');
  return uid;
}

uploadFoodAndImages(Food food, File localFile, BuildContext context) async {
  getCurrentUserUuid();
  if (localFile != null) {
    print('uploading img file');

    var fileExtension = path.extension(localFile.path);
    print(fileExtension);

    var uuid = Uuid().v4();

    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child('images/$uuid$fileExtension');

    StorageUploadTask task = firebaseStorageRef.putFile(localFile);

    StorageTaskSnapshot taskSnapshot = await task.onComplete;

    String url = await taskSnapshot.ref.getDownloadURL();
    print('dw url $url');
    _uploadFood(food, context, imageUrl: url);
  } else {
    print('skipping img upload');
    _uploadFood(food, context);
  }
}

_uploadFood(Food food, BuildContext context, {String imageUrl}) async {
  CollectionReference foodRef = Firestore.instance.collection('foods');
  bool complete = true;
  if (imageUrl != null) {
    print(imageUrl);
    try {
      food.img = imageUrl;
      print(food.img);
    } catch (e) {
      print(e);
    }

    food.createdAt = Timestamp.now();

//    DocumentReference documentRef =
    await foodRef
        .add(food.toMap())
        .catchError((e) => print(e))
        .then((value) => complete = true);

    print('uploaded food successfully');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return NavigationBarPage();
        },
      ),
    );
  }
  return complete;
}