import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:free_wifi_map/syncronize/mark.dart';
import 'package:free_wifi_map/syncronize/controller.dart';
import 'package:free_wifi_map/syncronize/databasehelper.dart';
import 'package:free_wifi_map/syncronize/syncronize.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'loginscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SqfliteDatabaseHelper.instance.db;
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      routes: {
        '/': (context) => YandexMapTest(),
        '/login': (context) => LoginScreen()
      },
      initialRoute: '/',
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

class _YandexMapTestState extends State<YandexMapTest> {
  final commentController = TextEditingController();
  final complainController = TextEditingController();
  late YandexMapController controller;
  final List<MapObject> mapObjects = [];
  MapObjectId mapObjectId = const MapObjectId('selPoint');
  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);
  static const Point _startPoint =
      Point(latitude: 56.129057, longitude: 40.406635);

  String baseUrl = '192.168.0.102';
  // Логика для создания нового id для метки
  int counter = 1;
  void counterPlus() {
    counter++;
  }

  Position? _currentLocation;
  late bool servisePermisson = false;
  late LocationPermission permission;

  Future<Position> _getCurrentLocation() async {
    servisePermisson = await Geolocator.isLocationServiceEnabled();
    if (!servisePermisson) {
      permission == Geolocator.checkPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  // Рисовалка кружков
  Future<Uint8List> _rawPlacemarkImage() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(50, 50);
    final fillPaint = Paint();
    fillPaint.color = Colors.white;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const radius = 20.0;

    final circleOffset = Offset(size.height / 2, size.width / 2);

    canvas.drawCircle(circleOffset, radius, fillPaint);
    canvas.drawCircle(circleOffset, radius, strokePaint);

    final image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  // Добавление меток с бд
  void loaderTest() async {
    List jsonList;
    var response;
    try {
      response = await Dio().get("http://$baseUrl:8080/mark");
    } on DioException catch (_) {
      print(_.message);
    }
    setState(() {
      jsonList = response.data as List;
      print(jsonList);
      jsonList.length;

      jsonList.forEach((item) async {
        print("----------------------------------------------------");
        print("----------------------------------------------------");
        print(jsonList[jsonList.indexOf(item)]['id']);

        mapObjectId = MapObjectId(jsonList[jsonList.indexOf(item)]['latitude']);
        var placemark = PlacemarkMapObject(
            mapId: mapObjectId,
            point: Point(
                latitude:
                    double.parse(jsonList[jsonList.indexOf(item)]['latitude']),
                longitude: double.parse(
                    jsonList[jsonList.indexOf(item)]['longitude'])),
            opacity: 200,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                  image:
                      BitmapDescriptor.fromBytes(await _rawPlacemarkImage())),
            ),
            onTap: (PlacemarkMapObject self, Point point) {
              Point newPoint = self.point;
              print('Tapped me at $newPoint');
              _showToast(newPoint);
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
                  var response = await dio.post("http://$baseUrl:8080/comment",
                      data: {
                        'comment': commentController.text,
                        'latitude': point.latitude.toString()
                      });
                      print(response);
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/'),
                  );
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
                        title: Text(jsonComments[index]['comment']),
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

  // Всплывающее меню (само меню)
  Column _buildBottomNavMenu(Point point, String mark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 10, left: 0),
          child: Column(
            children: [
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
                          title: Text(mark, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.people_alt_outlined),
                      title: Text('Added by'),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                        title: Text('Beltok', textAlign: TextAlign.right)),
                  ),
                ],
              ),
              InkWell(
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
              InkWell(
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
              )
            ],
          ),
        ),
      ],
    );
    //setState(() {});
  }

  // Всплывающее меню (вызов меню)
  void _showToast(Point point) {
    var arr = [1, 2, 3, 4];
    var mark = (arr.reduce((a, b) => a + b) / arr.length).toString();
    showModalBottomSheet(
        context: context,
        shape: (const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ))),
        builder: (context) {
          return Container(
            height: 300,
            child: _buildBottomNavMenu(point, mark),
          );
        });
  }

  Timer? _timer;
  List? list;
  bool loading = true;
  Future userList() async {
    list = await Controller().fetchData();
    setState(() {
      loading = false;
    });
    //print(list);
  }

  @override
  initState() {
    super.initState();
    loaderTest();
    userList();
    isInteret();
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
  }

  Future syncToMysql() async {
    await SyncronizationData().fetchAllInfo().then((userList) async {
      EasyLoading.show(status: 'Dont close app. we are sync...');
      await SyncronizationData().saveToMysqlWith(userList);
      EasyLoading.showSuccess('Successfully save to mysql');
    });
  }

  Future isInteret() async {
    await SyncronizationData.isInternet().then((connection) {
      if (connection) {
        print("Internet connection abailale");
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("No Internet")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          onMapTap: (Point selectedPoint) async {
            if (addingButtonStatus == true) {
              // Задание нового id для метки
              counterPlus();
              mapObjectId = MapObjectId("$mapObjectId + $counter");

              // Создание метки при нажатии на карту + Вывод информации о метке
              print('Tapped map at $selectedPoint'); // для проверки
              final placemark = PlacemarkMapObject(
                  mapId: mapObjectId,
                  point: selectedPoint,
                  opacity: 200,
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                        image: BitmapDescriptor.fromBytes(
                            await _rawPlacemarkImage())),
                  ),
                  onTap: (PlacemarkMapObject self, Point point) async {
                    Point newPoint = self.point;
                    print('Tapped me at $newPoint');
                    _showToast(newPoint);
                    Mark mark = Mark(
                        id: null,
                        latitude: newPoint.latitude,
                        longitude: newPoint.longitude);
                    await Controller().addData(mark).then((value) {
                      if (value! > 0) {
                        print("Success");
                        userList();
                      } else {
                        print("Fail");
                      }
                    });
                  });
              var response = await Dio().post('http://$baseUrl:8080/mark',
                  data: {
                    'latitude': selectedPoint.latitude,
                    'longitude': selectedPoint.longitude
                  });
              print(response);
              // Добавление метки на карту (в массив меток)
              setState(() {
                mapObjects.add(placemark);
              });
            }
          }),
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
                icon: const Icon(Icons.person),
                onPressed: () {
                  if (true) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  }
                }),
          ),
        ),
        IconButton(
            icon: Icon(Icons.refresh_sharp),
            onPressed: () async {
              await SyncronizationData.isInternet().then((connection) {
                if (connection) {
                  syncToMysql();
                  print("Internet connection abailale");
                } else {
                  ScaffoldMessenger
                  .of(context)
                  .showSnackBar(SnackBar(content: Text("No Internet")));
                }
              });
            }),
        Spacer(
          flex: 5,
        ),
        Expanded(
          flex: 1,
          child: FloatingActionButton(
              backgroundColor: Colors.black87,
              onPressed: () async {
                _currentLocation = await _getCurrentLocation();
                setState(() {
                  // Перемещение камеры на заданный startPoint
                  // при запуске приложения
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
              },
              child: const Icon(Icons.gps_fixed)),
        ),
        Expanded(
          flex: 0,
          child: FloatingActionButton(
              backgroundColor: Colors.black87,
              onPressed: () {
                addingButtonStatus = true;
              },
              child: const Icon(Icons.place)),
        )
      ]),
    );
  }
}
