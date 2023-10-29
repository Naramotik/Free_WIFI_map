// To parse this JSON data, do
//
//     final mark = markFromJson(jsonString);

import 'dart:convert';

Mark markFromJson(String str) => Mark.fromJson(json.decode(str));

String markToJson(Mark data) => json.encode(data.toJson());

class Mark {
    int? id;
    double latitude;
    double longitude;

    Mark({
        required this.id,
        required this.latitude,
        required this.longitude,
    });

    factory Mark.fromJson(Map<String, dynamic> json) => Mark(
        id: json["id"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "latitude": latitude,
        "longitude": longitude,
    };
}
