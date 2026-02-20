// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';

void main() {
  group('PDFPreferences', () {
    group('disableDoubleTapTextSelection', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.disableDoubleTapTextSelection, isNull);
      });

      test('can be set to true', () {
        final prefs = PDFPreferences(disableDoubleTapTextSelection: true);
        expect(prefs.disableDoubleTapTextSelection, true);
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(disableDoubleTapTextSelection: true);
        final json = prefs.toJson();
        expect(json['disableDoubleTapTextSelection'], true);
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('disableDoubleTapTextSelection'), false);
      });

      test('copyWith preserves disableDoubleTapTextSelection', () {
        final prefs1 = PDFPreferences(disableDoubleTapTextSelection: true);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.disableDoubleTapTextSelection, true);
      });

      test('copyWith can override disableDoubleTapTextSelection', () {
        final prefs1 = PDFPreferences(disableDoubleTapTextSelection: true);
        final prefs2 = prefs1.copyWith(disableDoubleTapTextSelection: false);
        expect(prefs2.disableDoubleTapTextSelection, false);
      });
    });

    group('enableEdgeTapNavigation', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.enableEdgeTapNavigation, isNull);
      });

      test('can be set to true', () {
        final prefs = PDFPreferences(enableEdgeTapNavigation: true);
        expect(prefs.enableEdgeTapNavigation, true);
      });

      test('can be set to false', () {
        final prefs = PDFPreferences(enableEdgeTapNavigation: false);
        expect(prefs.enableEdgeTapNavigation, false);
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(enableEdgeTapNavigation: true);
        final json = prefs.toJson();
        expect(json['enableEdgeTapNavigation'], true);
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('enableEdgeTapNavigation'), false);
      });

      test('copyWith preserves enableEdgeTapNavigation', () {
        final prefs1 = PDFPreferences(enableEdgeTapNavigation: true);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.enableEdgeTapNavigation, true);
      });

      test('copyWith can override enableEdgeTapNavigation', () {
        final prefs1 = PDFPreferences(enableEdgeTapNavigation: true);
        final prefs2 = prefs1.copyWith(enableEdgeTapNavigation: false);
        expect(prefs2.enableEdgeTapNavigation, false);
      });
    });

    group('edgeTapAreaPoints', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.edgeTapAreaPoints, isNull);
      });

      test('can be set via constructor', () {
        final prefs = PDFPreferences(edgeTapAreaPoints: 60.0);
        expect(prefs.edgeTapAreaPoints, equals(60.0));
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(edgeTapAreaPoints: 80.0);
        final json = prefs.toJson();
        expect(json['edgeTapAreaPoints'], equals(80.0));
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('edgeTapAreaPoints'), false);
      });

      test('fromJsonMap parses edgeTapAreaPoints', () {
        final json = {'edgeTapAreaPoints': 72.0};
        final prefs = PDFPreferences.fromJsonMap(json);
        expect(prefs.edgeTapAreaPoints, equals(72.0));
      });

      test('fromJsonMap parses edgeTapAreaPoints from int', () {
        final json = {'edgeTapAreaPoints': 60};
        final prefs = PDFPreferences.fromJsonMap(json);
        expect(prefs.edgeTapAreaPoints, equals(60.0));
      });

      test('copyWith preserves edgeTapAreaPoints', () {
        final prefs1 = PDFPreferences(edgeTapAreaPoints: 80.0);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.edgeTapAreaPoints, equals(80.0));
      });

      test('copyWith can override edgeTapAreaPoints', () {
        final prefs1 = PDFPreferences(edgeTapAreaPoints: 80.0);
        final prefs2 = prefs1.copyWith(edgeTapAreaPoints: 44.0);
        expect(prefs2.edgeTapAreaPoints, equals(44.0));
      });
    });

    group('enableSwipeNavigation', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.enableSwipeNavigation, isNull);
      });

      test('can be set to true', () {
        final prefs = PDFPreferences(enableSwipeNavigation: true);
        expect(prefs.enableSwipeNavigation, true);
      });

      test('can be set to false', () {
        final prefs = PDFPreferences(enableSwipeNavigation: false);
        expect(prefs.enableSwipeNavigation, false);
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(enableSwipeNavigation: true);
        final json = prefs.toJson();
        expect(json['enableSwipeNavigation'], true);
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('enableSwipeNavigation'), false);
      });

      test('copyWith preserves enableSwipeNavigation', () {
        final prefs1 = PDFPreferences(enableSwipeNavigation: true);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.enableSwipeNavigation, true);
      });

      test('copyWith can override enableSwipeNavigation', () {
        final prefs1 = PDFPreferences(enableSwipeNavigation: true);
        final prefs2 = prefs1.copyWith(enableSwipeNavigation: false);
        expect(prefs2.enableSwipeNavigation, false);
      });
    });
  });
}
