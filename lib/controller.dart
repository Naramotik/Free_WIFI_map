import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:free_wifi_map/mark.dart';

import 'databasehelper.dart';

class Controller {
  final conn = SqfliteDatabaseHelper.instance;

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

  Future<int?> addData(Mark mark) async {
    var dbclient = await conn.db;
    int? result;
    try {
      result = await dbclient!
          .insert(SqfliteDatabaseHelper.markTable, mark.toJson());
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<int?> updateData(Mark mark) async {
    var dbclient = await conn.db;
    int? result;
    try {
      result = await dbclient!.update(
          SqfliteDatabaseHelper.markTable, mark.toJson(),
          where: 'id=?', whereArgs: [mark.id]);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future fetchData() async {
    var dbclient = await conn.db;
    List userList = [];
    try {
      List<Map<String, dynamic>> maps = await dbclient!
          .query(SqfliteDatabaseHelper.markTable, orderBy: 'id DESC');
      for (var item in maps) {
        userList.add(item);
      }
    } catch (e) {
      print(e.toString());
    }
    return userList;
  }
}
