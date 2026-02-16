// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';

void main() {
  group('PDFPreferences', () {
    group('disableTextSelectionMenu', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.disableTextSelectionMenu, isNull);
      });

      test('can be set to true', () {
        final prefs = PDFPreferences(disableTextSelectionMenu: true);
        expect(prefs.disableTextSelectionMenu, true);
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(disableTextSelectionMenu: true);
        final json = prefs.toJson();
        expect(json['disableTextSelectionMenu'], true);
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('disableTextSelectionMenu'), false);
      });

      test('copyWith preserves disableTextSelectionMenu', () {
        final prefs1 = PDFPreferences(disableTextSelectionMenu: true);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.disableTextSelectionMenu, true);
      });

      test('copyWith can override disableTextSelectionMenu', () {
        final prefs1 = PDFPreferences(disableTextSelectionMenu: true);
        final prefs2 = prefs1.copyWith(disableTextSelectionMenu: false);
        expect(prefs2.disableTextSelectionMenu, false);
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

    group('edgeTapAreaPercent', () {
      test('defaults to null', () {
        final prefs = PDFPreferences();
        expect(prefs.edgeTapAreaPercent, isNull);
      });

      test('can be set via constructor', () {
        final prefs = PDFPreferences(edgeTapAreaPercent: 15.0);
        expect(prefs.edgeTapAreaPercent, equals(15.0));
      });

      test('serializes correctly', () {
        final prefs = PDFPreferences(edgeTapAreaPercent: 20.0);
        final json = prefs.toJson();
        expect(json['edgeTapAreaPercent'], equals(20.0));
      });

      test('not included when null', () {
        final prefs = PDFPreferences();
        final json = prefs.toJson();
        expect(json.containsKey('edgeTapAreaPercent'), false);
      });

      test('fromJsonMap parses edgeTapAreaPercent', () {
        final json = {'edgeTapAreaPercent': 18.0};
        final prefs = PDFPreferences.fromJsonMap(json);
        expect(prefs.edgeTapAreaPercent, equals(18.0));
      });

      test('fromJsonMap parses edgeTapAreaPercent from int', () {
        final json = {'edgeTapAreaPercent': 15};
        final prefs = PDFPreferences.fromJsonMap(json);
        expect(prefs.edgeTapAreaPercent, equals(15.0));
      });

      test('copyWith preserves edgeTapAreaPercent', () {
        final prefs1 = PDFPreferences(edgeTapAreaPercent: 20.0);
        final prefs2 = prefs1.copyWith();
        expect(prefs2.edgeTapAreaPercent, equals(20.0));
      });

      test('copyWith can override edgeTapAreaPercent', () {
        final prefs1 = PDFPreferences(edgeTapAreaPercent: 20.0);
        final prefs2 = prefs1.copyWith(edgeTapAreaPercent: 10.0);
        expect(prefs2.edgeTapAreaPercent, equals(10.0));
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
