import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/utils/toc_matcher.dart';

Locator _locator(String href) => Locator(href: href, type: 'application/xhtml+xml');

void main() {
  group('normalizePath', () {
    test('strips leading slash', () {
      expect(normalizePath('/OEBPS/chapter1.xhtml'), 'OEBPS/chapter1.xhtml');
    });

    test('returns unchanged if no leading slash', () {
      expect(normalizePath('chapter1.xhtml'), 'chapter1.xhtml');
    });

    test('handles empty string', () {
      expect(normalizePath(''), '');
    });

    test('strips only the first slash', () {
      expect(normalizePath('//double.xhtml'), '/double.xhtml');
    });
  });

  group('findTocIndexByPath', () {
    test('matches locator href against TOC entry - exact path', () {
      final toc = [
        Link(href: 'OEBPS/ch1.xhtml'),
        Link(href: 'OEBPS/ch2.xhtml'),
        Link(href: 'OEBPS/ch3.xhtml'),
      ];
      final locator = _locator('/OEBPS/ch2.xhtml');

      expect(findTocIndexByPath(locator, toc), 1);
    });

    test('matches locator with leading slash against TOC without', () {
      final toc = [
        Link(href: 'chapter1.xhtml'),
        Link(href: 'chapter2.xhtml'),
      ];
      final locator = _locator('/chapter2.xhtml');

      expect(findTocIndexByPath(locator, toc), 1);
    });

    test('matches TOC with leading slash against locator without', () {
      final toc = [
        Link(href: '/chapter1.xhtml'),
        Link(href: '/chapter2.xhtml'),
      ];
      // Locator.hrefPath strips query/fragment but preserves leading slash,
      // so this tests the normalization in both directions
      final locator = _locator('chapter2.xhtml');

      expect(findTocIndexByPath(locator, toc), 1);
    });

    test('strips fragment from TOC href when matching', () {
      final toc = [
        Link(href: 'chapter1.xhtml#section1'),
        Link(href: 'chapter1.xhtml#section2'),
        Link(href: 'chapter2.xhtml'),
      ];
      final locator = _locator('/chapter1.xhtml');

      // firstMatch (default) returns first matching index
      expect(findTocIndexByPath(locator, toc), 0);
    });

    test('returns -1 for empty TOC', () {
      final locator = _locator('/chapter1.xhtml');

      expect(findTocIndexByPath(locator, []), -1);
    });

    test('returns -1 when no match found', () {
      final toc = [
        Link(href: 'chapter1.xhtml'),
        Link(href: 'chapter2.xhtml'),
      ];
      final locator = _locator('/chapter99.xhtml');

      expect(findTocIndexByPath(locator, toc), -1);
    });

    test('fallback matches by filename only when paths differ', () {
      final toc = [
        Link(href: 'Text/chapter1.xhtml'),
        Link(href: 'Text/chapter2.xhtml'),
      ];
      // Locator has a different directory structure
      final locator = _locator('/OEBPS/Text/chapter2.xhtml');

      // Full path won't match (Text/chapter2.xhtml != OEBPS/Text/chapter2.xhtml)
      // but filename fallback should match
      expect(findTocIndexByPath(locator, toc), 1);
    });

    group('lastMatch parameter', () {
      test('lastMatch=false returns first matching index', () {
        final toc = [
          Link(href: 'chapter1.xhtml#part1'),
          Link(href: 'chapter1.xhtml#part2'),
          Link(href: 'chapter1.xhtml#part3'),
          Link(href: 'chapter2.xhtml'),
        ];
        final locator = _locator('/chapter1.xhtml');

        expect(findTocIndexByPath(locator, toc, lastMatch: false), 0);
      });

      test('lastMatch=true returns last matching index', () {
        final toc = [
          Link(href: 'chapter1.xhtml#part1'),
          Link(href: 'chapter1.xhtml#part2'),
          Link(href: 'chapter1.xhtml#part3'),
          Link(href: 'chapter2.xhtml'),
        ];
        final locator = _locator('/chapter1.xhtml');

        expect(findTocIndexByPath(locator, toc, lastMatch: true), 2);
      });

      test('lastMatch with single match returns same index either way', () {
        final toc = [
          Link(href: 'chapter1.xhtml'),
          Link(href: 'chapter2.xhtml'),
          Link(href: 'chapter3.xhtml'),
        ];
        final locator = _locator('/chapter2.xhtml');

        expect(findTocIndexByPath(locator, toc, lastMatch: false), 1);
        expect(findTocIndexByPath(locator, toc, lastMatch: true), 1);
      });
    });

    group('filename fallback with lastMatch', () {
      test('fallback also respects lastMatch=true', () {
        final toc = [
          Link(href: 'Text/chapter1.xhtml#s1'),
          Link(href: 'Text/chapter1.xhtml#s2'),
          Link(href: 'Text/chapter2.xhtml'),
        ];
        final locator = _locator('/OEBPS/Text/chapter1.xhtml');

        expect(findTocIndexByPath(locator, toc, lastMatch: true), 1);
      });

      test('fallback also respects lastMatch=false', () {
        final toc = [
          Link(href: 'Text/chapter1.xhtml#s1'),
          Link(href: 'Text/chapter1.xhtml#s2'),
          Link(href: 'Text/chapter2.xhtml'),
        ];
        final locator = _locator('/OEBPS/Text/chapter1.xhtml');

        expect(findTocIndexByPath(locator, toc, lastMatch: false), 0);
      });
    });
  });
}
