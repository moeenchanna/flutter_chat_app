import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helper/Constant.dart';
import '../main.dart';
import '../models/ChatRoomModel.dart';
import '../models/MessageModel.dart';
import '../models/UserModel.dart';

class ChatRoomPage extends StatefulWidget {

  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage({Key? key, required this.targetUser, required this.chatroom, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  TextEditingController messageController = TextEditingController();

  void sendMessage() async {
    String msg = messageController.text.trim();
    messageController.clear();

    if(msg != "") {
      // Send Message
      MessageModel newMessage = MessageModel(
          messageid: uuid.v1(),
          sender: widget.userModel.uid,
          createdon: DateTime.now(),
          text: msg,
          seen: false,
      );

      FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).collection("messages").doc(newMessage.messageid).set(newMessage.toMap());

      widget.chatroom.lastMessage = msg;
      FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).set(widget.chatroom.toMap());
      //String? fcm = widget.userModel.fcmkey;
      String? fcm = widget.targetUser.fcmkey;
      String? usernme = widget.userModel.fullname;

     // fcm = await token();
      log("FCM TOKEN $fcm");
      log("usernme $usernme");
      log("msg $msg");

      pushNotificationsSpecificDevice(token: fcm, title: usernme, body: msg);



      log("Message Sent!");
    }
  }

  Future<String> token() async {
    return await FirebaseMessaging.instance.getToken() ?? "";
  }

  Future<bool> pushNotificationsSpecificDevice({
    required String? token,
    required String? title,
    required String? body,
  }) async {
    String dataNotifications = '{ "to" : "$token",'
        ' "notification" : {'
        ' "title":"$title",'
        '"body":"$body"'
        ' }'
        ' }';

    var response = await http.post(
      Uri.parse(Constants.BASE_URL),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key= ${Constants.KEY_SERVER}',
      },
      body: dataNotifications,
    );
    print(dataNotifications);
    print(response.body.toString());

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [

            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(widget.targetUser.profilepic.toString()),
            ),

            const SizedBox(width: 10,),

            Text(widget.targetUser.fullname.toString()),

          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [

              // This is where the chats will go
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10
                  ),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).collection("messages").orderBy("createdon", descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.active) {
                        if(snapshot.hasData) {
                          QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                          return ListView.builder(
                            reverse: true,
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              MessageModel currentMessage = MessageModel.fromMap(dataSnapshot.docs[index].data() as Map<String, dynamic>);

                              return Row(
                                mainAxisAlignment: (currentMessage.sender == widget.userModel.uid) ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (currentMessage.sender == widget.userModel.uid) ? Colors.grey : Theme.of(context).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        currentMessage.text.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        else if(snapshot.hasError) {
                          return const Center(
                            child: Text("An error occured! Please check your internet connection."),
                          );
                        }
                        else {
                          return const Center(
                            child: const Text("Say hi to your new friend"),
                          );
                        }
                      }
                      else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ),

              Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5
                ),
                child: Row(
                  children: [

                    Flexible(
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter message"
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        sendMessage();
                      },
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary,),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}