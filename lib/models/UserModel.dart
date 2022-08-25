class UserModel {
  String? uid;
  String? fullname;
  String? email;
  String? profilepic;
  String? fcmkey;

  UserModel(this.uid, this.fullname, this.email, this.profilepic, this.fcmkey);

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    fullname = map["fullname"];
    email = map["email"];
    profilepic = map["profilepic"];
    fcmkey = map["fcmkey"];
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullname": fullname,
      "email": email,
      "profilepic": profilepic,
      "fcmkey": fcmkey,
    };
  }
}
