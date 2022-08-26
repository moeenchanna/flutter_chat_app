import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat/helper/UIHelper.dart';
import 'package:flutter_firebase_chat/models/UserModel.dart';
import 'package:flutter_firebase_chat/pages/HomePage.dart';
import 'package:flutter_firebase_chat/pages/NotificationsPage.dart';
import 'package:flutter_firebase_chat/pages/SignUpPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void checkValues() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if(email == "" || password == "") {
      UIHelper.showAlertDialog(context, "Incomplete Data", "Please fill all the fields");
    }
    else {
      logIn(email, password);
    }
  }

  void logIn(String email, String password) async {
    UserCredential? credential;

    UIHelper.showLoadingDialog(context, "Logging In..");

    try {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch(ex) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show Alert Dialog
      UIHelper.showAlertDialog(context, "An error occured", ex.message.toString());
    }

    if(credential != null) {
      String uid = credential.user!.uid;

      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      UserModel userModel = UserModel.fromMap(userData.data() as Map<String, dynamic>);
      // Go to HomePage
      print("Log In Successful!");
      // ignore: use_build_context_synchronously
      Navigator.popUntil(context, (route) => route.isFirst);
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) {
              return HomePage(userModel: userModel, firebaseUser: credential!.user!);
            }
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [

              Text("Chat App", style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 45,
                fontWeight: FontWeight.bold
            ),),

            const SizedBox(height: 10,),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                  labelText: "Email Address"
              ),
            ),

            const SizedBox(height: 10,),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Password"
              ),
            ),

            const SizedBox(height: 20,),

            CupertinoButton(
              onPressed: () {
                checkValues();
              },
              color: Theme.of(context).colorScheme.secondary,
              child: const Text("Log In"),
            ),

                const SizedBox(height: 10,),

                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) {
                            return const NotificationsPage();
                          }
                      ),
                    );
                  },
                  color: Theme.of(context).colorScheme.secondary,
                  child: const Text("Notification"),
                ),

            ],
            ),
          ),
        ),
      )),
   bottomNavigationBar: Row(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [

       const Text("Don't have an account?", style: TextStyle(
           fontSize: 16
       ),),

       CupertinoButton(
         onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(
                 builder: (context) {
                   return const SignUpPage();
                 }
             ),
           );
         },
         child: const Text("Sign Up", style:  TextStyle(
             fontSize: 16
         ),),
       ),

     ],
   ),
    );
  }
}
