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
  });
}
