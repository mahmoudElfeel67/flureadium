import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/utils/toc_matcher.dart';

Locator _locator(String href) =>
    Locator(href: href, type: 'application/xhtml+xml');

Locator _pdfLocator(
  String href, {
  int? position,
  List<String>? fragments,
  double? progression,
}) => Locator(
  href: href,
  type: 'application/pdf',
  locations: Locations(
    position: position,
    fragments: fragments ?? [],
    progression: progression,
  ),
);

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
      final toc = [Link(href: 'chapter1.xhtml'), Link(href: 'chapter2.xhtml')];
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
      final toc = [Link(href: 'chapter1.xhtml'), Link(href: 'chapter2.xhtml')];
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

  group('isPdfToc', () {
    test('returns true for PDF TOC with page fragments', () {
      final toc = [
        Link(href: 'document.pdf#page=1'),
        Link(href: 'document.pdf#page=5'),
        Link(href: 'document.pdf#page=10'),
      ];

      expect(isPdfToc(toc), true);
    });

    test('returns false for EPUB TOC without page fragments', () {
      final toc = [
        Link(href: 'chapter1.xhtml'),
        Link(href: 'chapter2.xhtml#section1'),
        Link(href: 'chapter3.xhtml'),
      ];

      expect(isPdfToc(toc), false);
    });

    test('returns false for empty TOC', () {
      expect(isPdfToc([]), false);
    });

    test('returns false for EPUB with different file paths', () {
      final toc = [
        Link(href: 'OEBPS/ch1.xhtml'),
        Link(href: 'OEBPS/ch2.xhtml'),
        Link(href: 'OEBPS/ch3.xhtml'),
      ];

      expect(isPdfToc(toc), false);
    });

    test(
      'returns false if first entry has page but others do not share base',
      () {
        final toc = [
          Link(href: 'document.pdf#page=1'),
          Link(href: 'other.pdf#page=5'),
        ];

        expect(isPdfToc(toc), false);
      },
    );
  });

  group('findTocIndexByPage', () {
    test('finds exact page match', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=20'),
      ];
      final locator = _pdfLocator('doc.pdf', position: 10);

      expect(findTocIndexByPage(locator, toc), 1);
    });

    test('finds closest page before current', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=20'),
      ];
      final locator = _pdfLocator('doc.pdf', position: 15);

      // Page 15 is between chapter at page 10 and chapter at page 20
      // Should return index 1 (page 10)
      expect(findTocIndexByPage(locator, toc), 1);
    });

    test('returns first chapter when at page 1', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=20'),
      ];
      final locator = _pdfLocator('doc.pdf', position: 1);

      expect(findTocIndexByPage(locator, toc), 0);
    });

    test('returns last chapter when at last page', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=20'),
      ];
      final locator = _pdfLocator('doc.pdf', position: 50);

      expect(findTocIndexByPage(locator, toc), 2);
    });

    test('returns -1 for empty TOC', () {
      final locator = _pdfLocator('doc.pdf', position: 10);

      expect(findTocIndexByPage(locator, []), -1);
    });

    test('returns -1 when locator has no position and no progression', () {
      final toc = [Link(href: 'doc.pdf#page=1'), Link(href: 'doc.pdf#page=10')];
      final locator = _pdfLocator('doc.pdf');

      expect(findTocIndexByPage(locator, toc), -1);
    });

    test('uses fragments when position is null', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=20'),
      ];
      final locator = _pdfLocator('doc.pdf', fragments: ['page=15']);

      expect(findTocIndexByPage(locator, toc), 1);
    });

    test('returns -1 when page is before first chapter', () {
      final toc = [Link(href: 'doc.pdf#page=5'), Link(href: 'doc.pdf#page=10')];
      final locator = _pdfLocator('doc.pdf', position: 2);

      // Page 2 is before first chapter (page 5)
      expect(findTocIndexByPage(locator, toc), -1);
    });

    test('handles many chapters correctly', () {
      final toc = [
        Link(href: 'doc.pdf#page=1'),
        Link(href: 'doc.pdf#page=5'),
        Link(href: 'doc.pdf#page=10'),
        Link(href: 'doc.pdf#page=15'),
        Link(href: 'doc.pdf#page=20'),
        Link(href: 'doc.pdf#page=25'),
      ];
      final locator = _pdfLocator('doc.pdf', position: 18);

      // Page 18 is between chapter 4 (page 15) and chapter 5 (page 20)
      expect(findTocIndexByPage(locator, toc), 3);
    });

    group('progression fallback', () {
      test('uses progression when position is null', () {
        final toc = [
          Link(href: 'doc.pdf#page=1'),
          Link(href: 'doc.pdf#page=10'),
          Link(href: 'doc.pdf#page=20'),
        ];
        // progression 0.5 with last page 20 = page 10
        final locator = _pdfLocator('doc.pdf', progression: 0.5);

        expect(findTocIndexByPage(locator, toc), 1);
      });

      test('progression at start returns first chapter', () {
        final toc = [
          Link(href: 'doc.pdf#page=1'),
          Link(href: 'doc.pdf#page=10'),
          Link(href: 'doc.pdf#page=20'),
        ];
        // progression 0 = page 1 (clamped to 1)
        final locator = _pdfLocator('doc.pdf', progression: 0.0);

        expect(findTocIndexByPage(locator, toc), 0);
      });

      test('progression at end returns last chapter', () {
        final toc = [
          Link(href: 'doc.pdf#page=1'),
          Link(href: 'doc.pdf#page=10'),
          Link(href: 'doc.pdf#page=20'),
        ];
        // progression 1.0 with last page 20 = page 20
        final locator = _pdfLocator('doc.pdf', progression: 1.0);

        expect(findTocIndexByPage(locator, toc), 2);
      });

      test('progression in middle estimates correct chapter', () {
        final toc = [
          Link(href: 'doc.pdf#page=1'),
          Link(href: 'doc.pdf#page=25'),
          Link(href: 'doc.pdf#page=50'),
          Link(href: 'doc.pdf#page=75'),
          Link(href: 'doc.pdf#page=100'),
        ];
        // progression 0.6 with last page 100 = page 60
        // page 60 is between chapter at page 50 and page 75
        final locator = _pdfLocator('doc.pdf', progression: 0.6);

        expect(findTocIndexByPage(locator, toc), 2);
      });

      test('position takes priority over progression', () {
        final toc = [
          Link(href: 'doc.pdf#page=1'),
          Link(href: 'doc.pdf#page=10'),
          Link(href: 'doc.pdf#page=20'),
        ];
        // position=5 should be used, not progression=0.9
        final locator = _pdfLocator('doc.pdf', position: 5, progression: 0.9);

        // page 5 is between page 1 and page 10, so index 0
        expect(findTocIndexByPage(locator, toc), 0);
      });
    });
  });
}
