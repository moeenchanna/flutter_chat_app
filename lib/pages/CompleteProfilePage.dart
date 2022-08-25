import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat/models/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../helper/UIHelper.dart';
import 'HomePage.dart';

class CompleteProfilePage extends StatefulWidget {

  final UserModel userModel;
  final User firebaseUser;

  const CompleteProfilePage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  File? imageFile;
  TextEditingController fullNameController = TextEditingController();


  void selectImage(ImageSource source) async {
    XFile? _imageFile = await ImagePicker().pickImage(source: source);

    if (_imageFile != null) {
      cropImage(_imageFile);
    }
  }

  void cropImage(XFile file) async {
    File? croppedImage = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 20
    );



    if(croppedImage != null) {
    setState(() {
    imageFile = croppedImage;
    });
    }
  }

  void showPhotoOptions() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("Upload Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.gallery);
              },
              leading: const Icon(Icons.photo_album),
              title: const Text("Select from Gallery"),
            ),

            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.camera);
              },
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a photo"),
            ),

          ],
        ),
      );
    });
  }

  void checkValues() {
    String fullname = fullNameController.text.trim();

    if (fullname == "" || imageFile == null) {
      print("Please fill all the fields");
      UIHelper.showAlertDialog(context, "Incomplete Data",
          "Please fill all the fields and upload a profile picture");
    }
    else {
      log("Uploading data..");
      uploadData();
    }
  }

  void uploadData() async {
   // UIHelper.showLoadingDialog(context, "Uploading image..");

    UploadTask uploadTask = FirebaseStorage.instance.ref("profilepictures")
        .child(widget.userModel.uid.toString())
        .putFile(imageFile!);

    TaskSnapshot snapshot = await uploadTask;

    String? imageUrl = await snapshot.ref.getDownloadURL();
    String? fullname = fullNameController.text.trim();
    String? token = await FirebaseMessaging.instance.getToken();

    widget.userModel.fullname = fullname;
    widget.userModel.profilepic = imageUrl;
    widget.userModel.fcmkey = token;

    log("fcm token ${token!}");



    await FirebaseFirestore.instance.collection("users").doc(
        widget.userModel.uid).set(widget.userModel.toMap()).then((value) {
      log("Data uploaded!");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return HomePage(
              userModel: widget.userModel, firebaseUser: widget.firebaseUser);
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Complete Profile"),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 40
          ),
          child: ListView(
            children: [

              const SizedBox(height: 20,),

              CupertinoButton(
                onPressed: () {
                   showPhotoOptions();
                },
                padding: const EdgeInsets.all(0),
                child: const CircleAvatar(
                  radius: 60,
                  // backgroundImage: (imageFile != null) ? FileImage(imageFile!) : null,
                  // child: (imageFile == null) ? Icon(Icons.person, size: 60,) : null,
                ),
              ),

              const SizedBox(height: 20,),

              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                ),
              ),

              const SizedBox(height: 20,),

              CupertinoButton(
                onPressed: () {
                   checkValues();
                },
                color: Theme
                    .of(context)
                    .colorScheme
                    .secondary,
                child: const Text("Submit"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
