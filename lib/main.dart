import 'dart:async';
import 'dart:ui';

import 'package:android_flutter_wifi/android_flutter_wifi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:free_wifi_map/firebase/account_screen.dart';
import 'package:free_wifi_map/firebase/services/firebase_stream.dart';
import 'package:free_wifi_map/firebase/signup_screen.dart';
import 'package:free_wifi_map/firebase_options.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart' as iot;
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'firebase/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      routes: {
        '/': (context) => const YandexMapTest(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/account': (context) => const AccountScreen(),
        '/home': (context) => const FirebaseStream()
      },
      initialRoute: '/home',
    ),
  );
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
  //..customAnimation = CustomAnimation();
}

class YandexMapTest extends StatefulWidget {
  const YandexMapTest({super.key});

  @override
  State<YandexMapTest> createState() => _YandexMapTestState();
}

const iot.NetworkSecurity STA_DEFAULT_SECURITY = iot.NetworkSecurity.WPA;

class _YandexMapTestState extends State<YandexMapTest> {
  var user = FirebaseAuth.instance.currentUser;
  final commentController = TextEditingController();
  final complainController = TextEditingController();
  late YandexMapController controller;
  final List<MapObject> mapObjects = [];
  MapObjectId mapObjectId = const MapObjectId('selPoint');
  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 1.3);
  static const Point _startPoint =
      Point(latitude: 56.129057, longitude: 40.406635);
  final permissionLocation = Permission.location;
  String baseUrl = '192.168.1.15';

  // Логика для создания нового id для метки
  int counter = 1;
  bool isVisible = true;
  List<WifiNetwork?>? _htResultNetwork;
  final TextStyle textStyle = TextStyle(color: Colors.white);

  bool isMeAdmin = false;

  void counterPlus() {
    counter++;
  }

  Position? _currentLocation;

  var ssid = 'NO INFO';
  var signalLevel = 'NO INFO';
  var frequency = 'NO INFO';
  var level = 'NO INFO';

  // Рисовалка кружков
  Future<Uint8List> _rawPlacemarkImage(String level) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(50, 50);
    final fillPaint = Paint();


    if(level == "FAST"){
      fillPaint.color = Colors.green;
      final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

      const radius = 20.0;

      final circleOffset = Offset(size.height / 2, size.width / 2);

      canvas.drawCircle(circleOffset, radius, fillPaint);
      canvas.drawCircle(circleOffset, radius, strokePaint);
    } else {
      fillPaint.color = Colors.red;
      final strokePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      const radius = 20.0;

      final circleOffset = Offset(size.height / 2, size.width / 2);

      canvas.drawCircle(circleOffset, radius, fillPaint);
      canvas.drawCircle(circleOffset, radius, strokePaint);
    }




    final image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  String ssidByIot = 'ur wifi null';

  getWifiList() async {
    DhcpInfo dhcpInfo = await AndroidFlutterWifi.getDhcpInfo();
    print('ip: ${dhcpInfo.serverAddress}');
    print(ssidByIot);
    List<WifiNetwork> wifiList = await AndroidFlutterWifi.getWifiScanResult();
    for (int i = 0; i < wifiList.length; i++)
      if (wifiList.isNotEmpty) {
        WifiNetwork wifiNetwork = wifiList[i];
        print('ssid: ${wifiNetwork.ssid}');
        print('signalLevel: ${wifiNetwork.signalLevel}');
        print('bssid: ${wifiNetwork.bssid}');
        print('frequency: ${wifiNetwork.frequency}');
        print('level: ${wifiNetwork.level}');
        print('security: ${wifiNetwork.security}');
        print('Name:---------------------------');
      } else {
        print("empty");
        print("empty");
        print("empty");
        print("empty");
        print("empty");
        print("empty");
        print("empty");
        print("empty");
      }
    print("before CONNECTION");
    print("before CONNECTION");
  }

  init() async {
    await AndroidFlutterWifi.init();
  }

  Color setColor(String level){
    if (level == "FAST")
      return Colors.green;
    else
      return Colors.red;
  }

  bool consumeTapEventsPoint = false;
  bool consumeTapEventsMethod(){
    print(consumeTapEventsPoint.toString());
    return !consumeTapEventsPoint;
  }

  // Добавление меток с бд
  void loaderTest() async {
    List jsonList;
    var response;
    try {
      response = await Dio().get("http://$baseUrl:8080/mark",
          options: Options(
              sendTimeout: const Duration(minutes: 1),
              receiveTimeout: const Duration(minutes: 1),
              receiveDataWhenStatusError: true));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection  Timeout Exception");
      }
      throw Exception(e.message);
    }
    setState(() {
      jsonList = response.data as List;
      print(jsonList);
      jsonList.length;

      jsonList.forEach((item) async {
        print("----------------------------------------------------");
        print("----------------------------------------------------");
        print(jsonList[jsonList.indexOf(item)]['id']);

        if (jsonList[jsonList.indexOf(item)]['level'] == null || jsonList[jsonList.indexOf(item)]['level'] == "SLOW")
          jsonList[jsonList.indexOf(item)]['level'] = "SLOW";
        else
          jsonList[jsonList.indexOf(item)]['level'] = "FAST";


        mapObjectId = MapObjectId(jsonList[jsonList.indexOf(item)]['latitude']);
        var placemark = PlacemarkMapObject(
            //icon: PlacemarkIcon.single(PlacemarkIconStyle(image: BitmapDescriptor.fromAssetImage("assets/img.png"), isVisible: true)),
            text: PlacemarkText(text: "${jsonList[jsonList.indexOf(item)]['level']}", style: PlacemarkTextStyle(color: (setColor(jsonList[jsonList.indexOf(item)]['level'])), offsetFromIcon: false, offset: 3, placement: TextStylePlacement.top)),
            mapId: mapObjectId,
            consumeTapEvents: consumeTapEventsMethod(),
            point: Point(
                latitude:
                    double.parse(jsonList[jsonList.indexOf(item)]['latitude']),
                longitude: double.parse(
                    jsonList[jsonList.indexOf(item)]['longitude'])),
            opacity: 1,
            // icon: PlacemarkIcon.single(PlacemarkIconStyle(image: BitmapDescriptor.fromAssetImage("assets/1.bmp"), isVisible: true)),
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                  image:
                      BitmapDescriptor.fromBytes(await _rawPlacemarkImage(jsonList[jsonList.indexOf(item)]['level']))),
            ),
            onTap: (PlacemarkMapObject self, Point point) {
              Point newPoint = self.point;
              print('Tapped me at $newPoint');
              //_getVisible(newPoint.longitude, jsonList[jsonList.indexOf(item)]['client']['displayName']);
              _showToast(newPoint,
                  jsonList[jsonList.indexOf(item)]['client']['displayName'], jsonList[jsonList.indexOf(item)]['client']['email']);
            });
        // Обновление айдишника на новый
        setState(() {
          counterPlus();
          mapObjects.add(placemark);
        });
      });
    });
  }

  // Пост нового коммента
  void addComment(Point point) {
    showModalBottomSheet(
        context: context,
        shape: (const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 10),
              FloatingActionButton(
                child: const Text('SEND',
                    textAlign: TextAlign.center, textScaleFactor: 0.9),
                onPressed: () async {
                  var dio = Dio();
                  var response =
                      await dio.post("http://$baseUrl:8080/comment", data: {
                    'comment': commentController.text,
                    'latitude': point.latitude.toString(),
                    'email': user?.email.toString()
                  });
                  print(response);
                  // Navigator.popUntil(
                  //   context,
                  //   ModalRoute.withName('/'),
                  // );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              )
            ]),
          );
        });
  }

  // Виджет для комментариев, если они есть
  void showReviewMenu(Point point, var jsonComments) {
    showModalBottomSheet(
        context: context,
        shape: (const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ))),
        builder: (context) {
          return Column(
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 200),
                      child: TextButton(
                        onPressed: () {
                          addComment(point);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text('Add comment',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () => {Navigator.pop(context)},
                      child: Icon(Icons.close),
                    ),
                  )
                ],
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        title:
                            Text(jsonComments[index]['client']['displayName']),
                        subtitle: Text(jsonComments[index]['comment']),
                      ),
                    );
                  },
                  itemCount: jsonComments.length,
                ),
              ),
            ],
          );
        });
  }

  // Виджет для комментариев, если их нет
  void hasNoComments(Point point) {
    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          20.0,
                        ),
                      ),
                    ),
                    contentPadding: EdgeInsets.only(
                      top: 10.0,
                    ),
                    title: Text(
                      "No comments",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: FloatingActionButton(
                        onPressed: () {
                          addComment(point);
                        },
                        child: const Text('ADD COMMENT',
                            textAlign: TextAlign.center, textScaleFactor: 0.9)),
                  ),
                ]),
          );
        });
  }

  // Всплывающее меню комментариев (Запрос к бд)
  void _buildReviewMenu(Point point) async {
    String latitude = point.latitude.toString();
    var response;
    try {
      response = await Dio().get("http://$baseUrl:8080/comment/$latitude");
    } on DioException catch (_) {
      print(_.message);
    }
    var jsonComments = response.data as List;
    if (jsonComments.isNotEmpty) {
      showReviewMenu(point, jsonComments);
    } else {
      hasNoComments(point);
    }
  }

  // Виджет жалобы
  void _buildComplain(Point point) {
    showModalBottomSheet(
        context: context,
        shape: (const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(children: [
              SizedBox(height: 20),
              TextField(
                controller: complainController,
                decoration: const InputDecoration(
                  labelText: 'Complain',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20),
              FloatingActionButton(
                child: const Text('SEND',
                    textAlign: TextAlign.center, textScaleFactor: 0.9),
                onPressed: () async {
                  var response = await Dio()
                      .post("http://$baseUrl:8080/complain", data: {
                    'complain': complainController.text,
                    'latitude': point.latitude.toString()
                  });
                  print(response);
                  Navigator.pop(context);
                },
              )
            ]),
          );
        });
  }

  Future<String> _setGrade(
      double rating_glob, Point point, String grade) async {
    var middlegrade = grade;
    Dio().post('http://$baseUrl:8080/grade', data: {
      'grade': rating_glob,
      'latitude': point.latitude,
      "email": user!.email.toString()
    });
    var response;
    try {
      response =
          await Dio().get("http://$baseUrl:8080/grade/${point.latitude}/avg");
    } on DioException catch (_) {
      print(_.message);
    }
    setState(() {
      middlegrade = response.data;
    });
    return middlegrade;
  }

  // Всплывающее меню (само меню)
  SingleChildScrollView _buildBottomNavMenu(
      Point point, String grade, String displayname, String adress, String email) {
    double rating_glob = 0;
    String displaygrade = '0.0';
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        ssid,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Container(height: 20),
                      Text(adress)
                    ],
                  ),
                ),
              ),
            ),
          ]),
          Row(
            children: <Widget>[
              const Expanded(
                child: ListTile(
                    leading: Icon(Icons.star_border_sharp),
                    title: Text('Rating')),
              ),
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                          double.tryParse(grade)!.isNaN
                              ? '0.0'
                              : grade.toString().substring(0, 3),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Visibility(
            visible: isLogin(),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 23.0),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white)),
                        width: 200,
                        alignment: Alignment.center,
                        child: RatingBar.builder(
                          minRating: 1,
                          maxRating: 5,
                          itemSize: 25,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          updateOnDrag: true,
                          onRatingUpdate: (rating) => setState(() {
                            rating_glob = rating;
                          }),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            displaygrade =
                                await _setGrade(rating_glob, point, grade);
                            Navigator.pop(context);
                            EasyLoading.showSuccess('Оценка отправлена');
                            setState(() {
                              grade = displaygrade;
                            });
                          },
                          child: const Text('SEND'),
                        )),
                  ),
                ]),
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: ListTile(
                    leading: Icon(Icons.signal_cellular_alt_sharp),
                    title: Text('Signal level, range [1-5]')),
              ),
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(signalLevel, textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child:
                    ListTile(leading: Icon(Icons.speed), title: Text('Speed')),
              ),
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(level, textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Visibility(
            visible: isLogin(),
            child: InkWell(
              onTap: () => {_buildReviewMenu(point)},
              child: const Row(
                children: <Widget>[
                  Expanded(
                      flex: 5,
                      child: ListTile(
                        leading: Icon(Icons.comment),
                        title: Text('Comments'),
                      )),
                  Expanded(
                    flex: 1,
                    child: ListTile(
                      leading: Icon(Icons.arrow_forward_ios_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isLogin(),
            child: InkWell(
              onTap: () => {_buildComplain(point)}, // Пожаловаться
              child: const Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: ListTile(
                      leading: Icon(Icons.error_outline),
                      title: Text('Complain'),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListTile(
                        leading: Icon(Icons.arrow_forward_ios_rounded)),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: ListTile(
                  leading: Icon(Icons.people_alt_outlined),
                  title: Text('Added by'),
                ),
              ),
              Expanded(
                child: ListTile(
                    title: Text(displayname, textAlign: TextAlign.right)),
              ),
            ],
          ),
          InkWell(
            onTap: () {}, // Удалить свою метку
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: TextButton(
                    onPressed: () async {
                      setState(() {
                        final placemarkToDelete = PlacemarkMapObject(
                            mapId: mapObjectId, point: point);
                        mapObjects.remove(placemarkToDelete);
                        showDialog(
                            context: context,
                            builder: (context) {
                              Future.delayed(const Duration(seconds: 2), () {
                                Navigator.of(context).pop(true);
                              });
                              return AlertDialog(
                                  title: Text("Информация"),
                                  content: FutureBuilder(
                                      future: deleteMark(point),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<String> snapshot) {
                                        if (snapshot.data.toString() ==
                                            "Success")
                                          return Container(
                                              child:
                                                  Text("Точка будет удалена"));
                                        else
                                          return Container(
                                              child: Text("Это не ваша точка"));
                                      }));
                            });
                      });
                    },
                    child: Visibility(
                        visible: isCreator(email) || isMeAdmin,
                        child: const Text(
                          "DELETE",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                    replacement: Container(
                      height: 10,
                    ),),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    //setState(() {});
  }

  Future<String> deleteMark(Point point) async {
    var response = await Dio().delete(
        "http://$baseUrl:8080/mark/${point.longitude}/${FirebaseAuth.instance.currentUser?.email}");
    return response.data.toString();
  }

  // Всплывающее меню (вызов меню)
  Future<void> _showToast(Point point, String? displayname, String? email) async {
    String adress = '';
    List<Placemark> placemarks =
        await placemarkFromCoordinates(point.latitude, point.longitude);
    if (placemarks != null && placemarks.isNotEmpty) {
      print(placemarks[0].thoroughfare);
      print('____________');
      print(placemarks[0].subThoroughfare);
      print('____________');
      print(placemarks[0].street);
      adress =
          'Адрес: ${placemarks[0].thoroughfare} дом: ${placemarks[0].subThoroughfare}';
    } else {
      print('go away');
    }
    getOpeningMarkInfo(point);
    var grade =
        await Dio().get("http://$baseUrl:8080/grade/${point.latitude}/avg");
    showModalBottomSheet(
        context: context,
        shape: (const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ))),
        builder: (context) {
          return Container(
            height: 330,
            child: _buildBottomNavMenu(
                point, grade.data.toString(), displayname!, adress, email!),
          );
        }).whenComplete(() {
      ssid = 'NO INFO';
      signalLevel = 'NO INFO';
      frequency = 'NO INFO';
      level = 'NO INFO';
      isVisible = true;
    });
  }

  getSSID() async {
    ssidByIot = await iot.WiFiForIoTPlugin.getSSID() as String;
  }

  @override
  initState() {
    super.initState();
    getSSID();
    init();
    loaderTest();
  }

  bool isLogin() {
    if ((user == null)) {
      return false;
    } else {
      return true;
    }
  }

  isAdmin() async{
    var response = await Dio().get("http://$baseUrl:8080/client/${FirebaseAuth.instance.currentUser?.email}");
    setState(() {
      if (response.data["role"].toString() == "ADMIN"){
        isMeAdmin = true;
      } else {
        isMeAdmin = false;
      }
    });
  }

  isCreator(String email){
    if(email == user?.email.toString()){
      return true;
    }
    else{
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool addingButtonStatus = false;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: YandexMap(
        mapObjects: mapObjects,
        onMapCreated: (YandexMapController yandexMapController) async {
          setState(() {
            // Перемещение камеры на заданный startPoint
            // при запуске приложения
            controller = yandexMapController;
            controller.moveCamera(
              CameraUpdate.newCameraPosition(
                const CameraPosition(
                  target: _startPoint,
                  zoom: 10,
                ),
              ),
              animation: animation,
            );
          });
        },
        // onMapTap: (Point selectedPoint) async {
        //   if (addingButtonStatus == true) {
        //     // Задание нового id для метки
        //     counterPlus();
        //     mapObjectId = MapObjectId("$mapObjectId + $counter");
        //
        //     // Создание метки при нажатии на карту + Вывод информации о метке
        //     print('Tapped map at $selectedPoint'); // для проверки
        //     final placemark = PlacemarkMapObject(
        //         mapId: mapObjectId,
        //         point: selectedPoint,
        //         opacity: 200,
        //         icon: PlacemarkIcon.single(
        //           PlacemarkIconStyle(
        //               image: BitmapDescriptor.fromBytes(
        //                   await _rawPlacemarkImage())),
        //         ),
        //         onTap: (PlacemarkMapObject self, Point point) async {
        //           Point newPoint = self.point;
        //           print('Tapped me at $newPoint');
        //           var response = await Dio()
        //               .get("http://$baseUrl:8080/mark/${newPoint.longitude}");
        //           _showToast(
        //               newPoint, response.data['client']['displayName']);
        //         });
        //     try {
        //       var response =
        //           await Dio().post('http://$baseUrl:8080/mark', data: {
        //         "mark": {
        //           'latitude': selectedPoint.latitude,
        //           'longitude': selectedPoint.longitude
        //         },
        //         "email": user!.email.toString()
        //       });
        //       print(response);
        //     } on DioException catch (e) {
        //       print(e.message);
        //     }
        //
        //     // Добавление метки на карту (в массив меток)
        //     setState(() {
        //       mapObjects.add(placemark);
        //     });
        //   }
        // }
      ),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: const ShapeDecoration(
              color: Colors.black45,
              shape: CircleBorder(),
            ),
            child: IconButton(
              onPressed: () {
                if ((user == null)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AccountScreen()),
                  );
                }
              },
              icon: Icon(
                Icons.person,
                color: (user == null) ? Colors.white : Colors.yellow,
              ),
            ),
          ),
        ),
        SizedBox(height: 400),
        Visibility(
          visible: isLogin(),
          replacement: const SizedBox(
            height: 90,
            width: 0,
          ),
          child: Expanded(
            flex: 1,
            child: FloatingActionButton(
                heroTag: "location",
                backgroundColor: Colors.black87,
                onPressed: () async {
                  final status = await permissionLocation.request();
                  if (status == PermissionStatus.granted) {
                    _currentLocation = await Geolocator.getCurrentPosition();
                    setState(() {
                      // Перемещение камеры на заданный startPoint при запуске приложения
                      controller.moveCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                              target: Point(
                                  latitude: _currentLocation!.latitude,
                                  longitude: _currentLocation!.longitude),
                              zoom: 20),
                        ),
                        animation: animation,
                      );
                    });
                  } else {
                    print('Location permission denied.');
                  }

                  //Данные для создания точки
                  getServerSSID();
                  print(serverSSID);
                  print(serverPASS);
                  getLevelSpeed();

                  List<WifiNetwork> wifiList =
                      await AndroidFlutterWifi.getWifiScanResult();
                  for (int i = 0; i < wifiList.length; i++) {
                    if (wifiList.isNotEmpty) {
                      WifiNetwork wifiNetwork = wifiList[i];
                      //Установка данных со списка всех сетей
                      if (wifiNetwork.ssid == serverSSID) {
                        ssid = wifiNetwork.ssid!;
                        signalLevel = wifiNetwork.signalLevel!;
                        frequency = wifiNetwork.frequency!;
                        // var response = AndroidFlutterWifi.isConnectionFast();
                        // if (response){
                        //
                        // }
                        level = wifiNetwork.level!;
                      }
                      print('ssid: ${wifiNetwork.ssid}');
                      print('signalLevel: ${wifiNetwork.signalLevel}');
                      print('bssid: ${wifiNetwork.bssid}');
                      print('frequency: ${wifiNetwork.frequency}');
                      print('level: ${wifiNetwork.level}');
                      print('security: ${wifiNetwork.security}');
                      print('Name:---------------------------');
                    } else {
                      print("empty");
                      print("empty");
                    }
                  }
                  addingButtonStatus = true;

                  if (addingButtonStatus == true) {
                    // Задание нового id для метки
                    counterPlus();
                    mapObjectId = MapObjectId("$mapObjectId + $counter");
                    Point selectedPoint = new Point(
                        latitude: _currentLocation!.latitude,
                        longitude: _currentLocation!.longitude);
                    // Создание метки при нажатии на карту + Вывод информации о метке
                    print('Tapped map at $selectedPoint'); // для проверки
                    final placemark = PlacemarkMapObject(
                        mapId: mapObjectId,
                        point: selectedPoint,
                        opacity: 200,
                        icon: PlacemarkIcon.single(
                          PlacemarkIconStyle(
                              image: BitmapDescriptor.fromBytes(
                                  await _rawPlacemarkImage(level))),
                        ),
                        onTap: (PlacemarkMapObject self, Point point) async {
                          Point newPoint = self.point;
                          print('Tapped me at $selectedPoint');
                          var response = await Dio().get(
                              "http://$baseUrl:8080/mark/${selectedPoint.longitude}");
                          _showToast(selectedPoint,
                              response.data['client']['displayName'], response.data['client']['email']);
                        });
                    try {
                      if (levelSpeed == 'true') {
                        var response = await Dio()
                            .post('http://$baseUrl:8080/mark', data: {
                          "mark": {
                            'latitude': selectedPoint.latitude,
                            'longitude': selectedPoint.longitude,
                            'ssid': ssid,
                            'signalLevel': signalLevel,
                            'frequency': frequency,
                            'level': "FAST",
                          },
                          "email": user!.email.toString()
                        });
                        print(response);
                      } else {
                        var response = await Dio()
                            .post('http://$baseUrl:8080/mark', data: {
                          "mark": {
                            'latitude': selectedPoint.latitude,
                            'longitude': selectedPoint.longitude,
                            'ssid': ssid,
                            'signalLevel': signalLevel,
                            'frequency': frequency,
                            'level': "SLOW",
                          },
                          "email": user!.email.toString()
                        });
                        print(response);
                      }
                    } on DioException catch (e) {
                      print(e.message);
                    }

                    // Добавление метки на карту (в массив меток)
                    setState(() {
                      mapObjects.add(placemark);
                      counterPlus();
                    });
                  }
                },
                child: const Icon(Icons.gps_fixed)),
          ),
        ),
        Expanded(
          flex: 0,
          child: FloatingActionButton(
              heroTag: "place",
              backgroundColor: Colors.black87,
              onPressed: () async {
                final status = await permissionLocation.request();
                if (status == PermissionStatus.granted) {
                  _currentLocation = await Geolocator.getCurrentPosition();
                  setState(() {
                    controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                            target: Point(
                                latitude: _currentLocation!.latitude,
                                longitude: _currentLocation!.longitude),
                            zoom: 20),
                      ),
                      animation: animation,
                    );
                  });
                } else {
                  print('Location permission denied.');
                }
              },
              child: const Icon(Icons.place)),
        ),
      ]),
    );
  }

  String serverSSID = '';
  String serverPASS = '';

  getServerSSID() async {
    serverSSID = await iot.WiFiForIoTPlugin.getSSID() as String;
    serverPASS = await iot.WiFiForIoTPlugin.getWiFiAPPreSharedKey() as String;
    print("sdfsduifhoifuheoirf");
    print(serverPASS);
  }

  var gettedSignal;
  var gettedLevel;
  var gettedSsid;

  Future<void> getOpeningMarkInfo(Point point) async {
    var response =
        await Dio().get("http://$baseUrl:8080/mark/${point.longitude}");
    setState(() {
      ssid = response.data["ssid"];
      signalLevel = response.data["signalLevel"];
      level = response.data["level"];
      frequency = response.data["frequency"];
      print(response.data["ssid"]);
    });
  }

  var levelSpeed = '';
  void getLevelSpeed() async {
    var result = await AndroidFlutterWifi.isConnectionFast()
        .then((value) => {levelSpeed = value.toString()});
  }
}
