import 'dart:async';

import 'package:flutter/services.dart';
// import 'package:charcode/ascii.dart' as Ascii;
import 'package:charcode/html_entity.dart' as HtmlEntity;

class CompassEvent {
  // 设备围绕其 Z 轴或设备顶部指向的方向（以度为单位）的航向。
  final double? heading;

  // 设备围绕其 X 轴的方向（以度为单位）或设备背面指向的位置。
  final double? headingForCameraMode;

  // 偏离航向的误差，以度为单位，正负。注意：对于 iOS，这是由平台计算的并且是可靠的。
  // 对于 Android，有几个值是硬编码的，真正的错误可能大于或小于此处的值。
  final double? accuracy;

  // 纬度
  final double? latitude;
  // 经度
  final double? longitude;
  // 海拔
  final double? altitude;
  // 真北方向文本,exp: 东南西北
  final String? headingText;
  // 真本方向值,exp:S,N,E,W
  final String? trueHeadingValue;
  // 磁北
  final double? magneticHeading;
  // 经纬度转度分秒
  final String? latitudeDMS;
  final String? longitudeDMS;

  // 北纬或南纬 返回的是N或S
  final String? latitudeCoordinateDirection;
  // 东经或西经 返回的是E或W
  final String? longitudeCoordinateDirection;
  CompassEvent(
      {this.heading,
      this.headingForCameraMode,
      this.accuracy,
      this.latitude,
      this.longitude,
      this.altitude,
      this.headingText,
      this.trueHeadingValue,
      this.magneticHeading,
      this.latitudeDMS,
      this.longitudeDMS,
      this.latitudeCoordinateDirection,
      this.longitudeCoordinateDirection});
  factory CompassEvent.fromData(
    data,
  ) {
    return CompassEvent(
        heading: data["trueHeading"] ?? null,
        headingForCameraMode: data["headingForCameraMode"] ?? null,
        accuracy: data["headingAccuracy"] ?? null,
        latitude: data["latitude"] ?? null,
        longitude: data["longitude"] ?? null,
        altitude: data["altitude"] ?? null,
        headingText: data["trueHeadingText"] ?? null,
        trueHeadingValue: data["trueHeadingValue"] ?? null,
        magneticHeading: data["magneticHeading"] ?? null,
        latitudeDMS: data["latitudeDMS"] ?? null,
        longitudeDMS: data["longitudeDMS"] ?? null,
        latitudeCoordinateDirection:
            data["latitudeCoordinateDirection"] ?? null,
        longitudeCoordinateDirection:
            data["longitudeCoordinateDirection"] ?? null);
  }

  @override
  String toString() {
    var deg = String.fromCharCode(HtmlEntity.$deg);
    var heading = this.heading.toString().split('.').first;
    var latDMS = latitudeCoordinateDirection == 'N' ? '北纬' : '南纬';
    var lngDMS = longitudeCoordinateDirection == 'E' ? '东经' : '西经';
    return 'heading: $heading$deg\n'
        // 'headingForCameraMode: $headingForCameraMode\n'
        'accuracy: $accuracy\n'
        'latitude: $latitude\n'
        'longitude: $longitude\n'
        'altitude: $altitude\n'
        'headingText: $headingText\n'
        'latitudeDMS: $latDMS $latitudeDMS\n'
        'longitudeDMS: $lngDMS $longitudeDMS';
  }
}

/// [FlutterCompass] is a singleton class that provides assess to compass events
/// The heading varies from 0-360, 0 being north.
class FlutterCompass {
  static final FlutterCompass _instance = FlutterCompass._();

  factory FlutterCompass() {
    return _instance;
  }

  FlutterCompass._();

  static const EventChannel _compassChannel =
      const EventChannel('soer/flutter_compass');
  static Stream<CompassEvent>? _stream;

  /// Provides a [Stream] of compass events that can be listened to.
  static Stream<CompassEvent>? get events {
    _stream ??= _compassChannel
        .receiveBroadcastStream()
        .map((dynamic data) => CompassEvent.fromData(data));
    return _stream;
  }
}
