import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() {
  runApp(const MaterialApp(home: YandexMapTest()));
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
  final animation = const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);
  static const Point _startPoint = Point(latitude: 56.129057, longitude: 40.406635);

  // Логика для создания нового id для метки
  int counter = 1;
  void counterPlus() {
    counter++;
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

    var response = await Dio().get("http://192.168.0.102:8080/mark");
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
                  var response = await dio
                      .post("http://192.168.0.102:8080/comment", data: {
                    'comment': commentController.text,
                    'latitude': point.latitude.toString()
                  });
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
    var response =
        await Dio().get("http://192.168.0.102:8080/comment/$latitude");
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
                      .post("http://192.168.0.102:8080/complain", data: {
                    'complain': complainController.text,
                    'latitude': point.latitude.toString()
                  });
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
                  Expanded(
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
    var arr = [1,2,3,4];
    var mark = (arr.reduce((a,b)=>a+b)/arr.length).toString();
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

  @override
  initState() {
    super.initState();
    loaderTest();
  }

  @override
  Widget build(BuildContext context) {
    bool addingButtonStatus = false;
    bool userProfileStatus = false;
    return Scaffold(
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
                  onTap: (PlacemarkMapObject self, Point point) {
                    Point newPoint = self.point;
                    print('Tapped me at $newPoint');
                    _showToast(newPoint);
                  });

              var response = await Dio().post("http://192.168.0.102:8080/mark",
                  data: {
                    'latitude': selectedPoint.latitude,
                    'longitude': selectedPoint.longitude
                  });

              // Добавление метки на карту (в массив меток)
              setState(() {
                mapObjects.add(placemark);
              });
            }
          }),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          child: Icon(Icons.person),
          backgroundColor: Colors.black87,
          onPressed: () {
            userProfileStatus = true;
          }
        ),
        SizedBox(
          height: 600,
        ),
        FloatingActionButton(
          backgroundColor: Colors.black87,
            onPressed: () {
              addingButtonStatus = true;
            },
            child: const Icon(Icons.place)),
      ]),
    );
  }
}
