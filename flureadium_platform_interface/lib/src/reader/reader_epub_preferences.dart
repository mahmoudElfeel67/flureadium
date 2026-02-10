// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui' show Color;

import '../index.dart';

class EPUBPreferences {
  EPUBPreferences({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.verticalScroll,
    required this.backgroundColor,
    required this.textColor,
    this.pageMargins,
    this.enableEdgeTapNavigation,
    this.enableSwipeNavigation,
  });

  factory EPUBPreferences.fromJsonMap(final Map<String, dynamic> map) =>
      EPUBPreferences(
        fontFamily: map['fontFamily'] as String,
        fontSize: map['fontSize'] as int,
        fontWeight: map['fontWeight'] as double,
        verticalScroll: map['verticalScroll'] as bool,
        backgroundColor: map['tint'] is int ? Color(map['tint'] as int) : null,
        textColor: map['tint'] is int ? Color(map['tint'] as int) : null,
      );

  String fontFamily;
  int fontSize;
  double? fontWeight;
  bool? verticalScroll;
  Color? backgroundColor;
  Color? textColor;
  double? pageMargins;

  /// Whether edge tap navigation is enabled (iOS only).
  /// When true, tapping on the left/right edges of the screen navigates pages.
  /// Defaults to true (enabled) when null.
  bool? enableEdgeTapNavigation;

  /// Whether swipe gesture navigation is enabled (iOS only).
  /// When true, swiping left/right navigates pages.
  /// Defaults to true (enabled) when null.
  bool? enableSwipeNavigation;

  // TODO: Add more preferences,
  //see https://github.com/readium/swift-toolkit/blob/develop/Sources/Navigator/EPUB/Preferences/EPUBPreferences.swift

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fontFamily': fontFamily,
      'fontSize': '${fontSize / 100}',
      'fontWeight': fontWeight.toString(),
      'verticalScroll': verticalScroll.toString(),
      'backgroundColor': backgroundColor.toCSS(),
      'textColor': textColor.toCSS(),
    };
    if (pageMargins != null) {
      map['pageMargins'] = pageMargins.toString();
    }
    if (enableEdgeTapNavigation != null) {
      map['enableEdgeTapNavigation'] = enableEdgeTapNavigation.toString();
    }
    if (enableSwipeNavigation != null) {
      map['enableSwipeNavigation'] = enableSwipeNavigation.toString();
    }
    return map;
  }
}
