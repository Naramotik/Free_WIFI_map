import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

Future<void> updateDisplayedName(user, name)async {
  user!.updateDisplayName(name);
  return;
}

class _AccountScreenState extends State<AccountScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final displayNameController = TextEditingController();
  String baseUrl = '192.168.1.15';
  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> signOut() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    navigator.pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 30, 30, 30),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 30, 30, 30),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios, // add custom icons also
          ),
        ),
        title: const Text('Аккаунт'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(),
          ),
        ],
      ),
      body:
      SingleChildScrollView(
        child: LayoutBuilder (builder: (context, constraint){
          return Center(
            child: Column(
              children: [
                SizedBox(height: 50),
                Text("МОИ ДАННЫЕ", style: TextStyle(fontSize: 24, color: Colors.white, letterSpacing: 1)),
                SizedBox(height: 55),
                Text("НИК", style: TextStyle(fontSize: 20, color: Colors.white, letterSpacing: 1)),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                  child: TextFormField(
                    controller: displayNameController,
                    onFieldSubmitted: (text) {
                      setState(() {
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Nickname",
                      fillColor: Colors.black,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                      hintStyle: TextStyle(color: Colors.white),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    sendInfo();
                    EasyLoading.showSuccess('Имя изменено');
                  },
                  child: const Text('Изменить имя', style: TextStyle(fontSize: 17, color: Colors.white, letterSpacing: 1)),
                ),
                SizedBox(height: 290),
                TextButton(
                  onPressed: () => signOut(),
                  child: const Text('Выйти', style: TextStyle(fontSize: 25, color: Colors.white, letterSpacing: 1)),
                ),
              ],
            ),
          );
        })
        ),
      );
  }

  getData() async{
    var response = await Dio().get("http://$baseUrl:8080/client/${FirebaseAuth.instance.currentUser?.email}");
    setState(() {
      displayNameController.text = response.data["displayName"].toString();
      // if (response.data["role"].toString() == "ADMIN"){
      //   isAdmin = true;
      // } else {
      //   isAdmin = false;
      // }
    });
  }

  sendInfo() {
    var displayName = displayNameController.text;
    Dio().put("http://$baseUrl:8080/client/change-name/$displayName/${FirebaseAuth.instance.currentUser?.email}");
  }

}