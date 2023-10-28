import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'databasehelper.dart';
import 'contactinfomodel.dart';

class SyncronizationData {
  static Future<bool> isInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      try {
        final result = await InternetAddress.lookup('example.com');
        print("Mobile data detected & internet connection confirmed.");
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        print('No internet :( Reason:');
        return false;
      }
    } else if (connectivityResult == ConnectivityResult.wifi) {
      try {
        final result = await InternetAddress.lookup('example.com');
        print("Mobile data detected & internet connection confirmed.");
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        print('No internet :( Reason:');
        return false;
      }
    } else {
      print(
          "Neither mobile data or WIFI detected, not internet connection found.");
      return false;
    }
  }

  final conn = SqfliteDatabaseHelper.instance;

  Future<List<Mark>> fetchAllInfo() async {
    final dbClient = await conn.db;
    List<Mark> contactList = [];
    try {
      final maps =
          await dbClient!.query(SqfliteDatabaseHelper.markTable);
      for (var item in maps) {
        contactList.add(Mark.fromJson(item));
      }
    } catch (e) {
      print(e.toString());
    }
    return contactList;
  }

  Future saveToMysqlWith(List<Mark> contactList) async {
    for (var i = 0; i < contactList.length; i++) {
      Map<String, dynamic> data = {
        "id": contactList[i].id,
        "latitude": contactList[i].latitude,
        "longitude": contactList[i].longitude,

      };
      var dio = Dio();
      final response = await dio.post(
          'http://192.168.0.1:8080/mark',
          data: data);
      if (response.statusCode == 200) {
        print("Saving Data ");
      } else {
        print(response.statusCode);
      }
    }
  }

  Future<List> fetchAllCustoemrInfo() async {
    final dbClient = await conn.db;
    List contactList = [];
    try {
      final maps =
          await dbClient!.query(SqfliteDatabaseHelper.markTable);
      for (var item in maps) {
        contactList.add(item);
      }
    } catch (e) {
      print(e.toString());
    }
    return contactList;
  }

  Future saveToMysql(List contactList) async {
    for (var i = 0; i < contactList.length; i++) {
      Map<String, dynamic> data = {
        "id": contactList[i]['id'],
        "latitude": contactList[i]['latitude'],
        "longitude": contactList[i]['longitude'],
      };
      var dio = Dio();
      final response = await dio.post(
          'http://192.168.0.1:8080/mark',
          data: data);
      if (response.statusCode == 200) {
        print("Saving Data ");
      } else {
        print(response.statusCode);
      }
    }
  }
}
