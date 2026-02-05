import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/utils/navigation_helper.dart';

void main() {
  group('decideSkipToNext', () {
    group('normal navigation within TOC', () {
      test('navigates to next chapter when in middle of TOC', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
          Link(href: '/ch3.xhtml', title: 'Chapter 3'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
          Link(href: '/ch3.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch2.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch3.xhtml');
        expect(decision.targetTocIndex, 2);
      });

      test('navigates to second chapter from first', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch1.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch2.xhtml');
        expect(decision.targetTocIndex, 1);
      });
    });

    group('edge case: at last chapter', () {
      test('navigates to epilogue page when at last chapter', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
          Link(href: '/epilogue.xhtml'), // Not in TOC
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch2.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1, // Last chapter
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/epilogue.xhtml');
        expect(decision.targetTocIndex, isNull); // Not a TOC entry
      });

      test('aborts when at last chapter with no pages after', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch2.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1, // Last chapter
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Already at last page');
      });
    });

    group('edge case: before first TOC entry', () {
      test('navigates to first chapter from cover page', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/cover.xhtml'), // Before TOC
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/cover.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });

      test('navigates to first chapter from title page', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
        ];
        final readingOrder = [
          Link(href: '/cover.xhtml'),
          Link(href: '/titlepage.xhtml'),
          Link(href: '/toc.xhtml'),
          Link(href: '/ch1.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/titlepage.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });
    });

    group('edge case: page not in reading order', () {
      test('aborts when current page not found in readingOrder', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/phantom.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1,
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Current page not found in readingOrder');
      });
    });

    group('edge case: between chapters', () {
      test('aborts when on interstitial page after last TOC entry', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
          Link(href: '/interstitial.xhtml'), // After last TOC but before end
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/interstitial.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Page not in TOC and not before first chapter');
      });
    });
  });

  group('decideSkipToPrevious', () {
    group('normal navigation within TOC', () {
      test('navigates to previous chapter when in middle of TOC', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
          Link(href: '/ch3.xhtml', title: 'Chapter 3'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
          Link(href: '/ch3.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch2.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });

      test('navigates to first chapter from second', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch2.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });
    });

    group('edge case: at first chapter', () {
      test('navigates to cover page when at first chapter', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/cover.xhtml'), // Before TOC
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch1.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0, // First chapter
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/cover.xhtml');
        expect(decision.targetTocIndex, isNull); // Not a TOC entry
      });

      test('aborts when at first chapter with no pages before', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/ch1.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0, // First chapter
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Already at first page');
      });
    });

    group('edge case: after last TOC entry', () {
      test('navigates to last chapter from epilogue page', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
          Link(href: '/epilogue.xhtml'), // After TOC
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/epilogue.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch2.xhtml');
        expect(decision.targetTocIndex, 1);
      });

      test('navigates to last chapter from appendix', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/epilogue.xhtml'),
          Link(href: '/appendix.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/appendix.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });
    });

    group('edge case: page not in reading order', () {
      test('aborts when current page not found in readingOrder', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
        ];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/phantom.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1,
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Current page not found in readingOrder');
      });
    });

    group('edge case: between chapters', () {
      test('aborts when on interstitial page before first TOC entry', () {
        final toc = [
          Link(href: '/ch1.xhtml', title: 'Chapter 1'),
          Link(href: '/ch2.xhtml', title: 'Chapter 2'),
        ];
        final readingOrder = [
          Link(href: '/interstitial.xhtml'), // Before first TOC
          Link(href: '/ch1.xhtml'),
          Link(href: '/ch2.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(href: '/interstitial.xhtml', type: 'application/xhtml+xml');

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Page not in TOC and not after last chapter');
      });
    });
  });

  group('NavigationDecision', () {
    test('navigate constructor creates decision with target', () {
      final link = Link(href: '/ch1.xhtml');
      final decision = NavigationDecision.navigate(link, 0);

      expect(decision.canNavigate, isTrue);
      expect(decision.targetLink, link);
      expect(decision.targetTocIndex, 0);
      expect(decision.reason, isNull);
    });

    test('navigate constructor can create decision without TOC index', () {
      final link = Link(href: '/cover.xhtml');
      final decision = NavigationDecision.navigate(link, null);

      expect(decision.canNavigate, isTrue);
      expect(decision.targetLink, link);
      expect(decision.targetTocIndex, isNull);
      expect(decision.reason, isNull);
    });

    test('abort constructor creates decision with reason', () {
      final decision = NavigationDecision.abort('Already at end');

      expect(decision.canNavigate, isFalse);
      expect(decision.targetLink, isNull);
      expect(decision.targetTocIndex, isNull);
      expect(decision.reason, 'Already at end');
    });
  });
}

/// Helper to create a test publication.
Publication _createPublication(List<Link> toc, List<Link> readingOrder) {
  // Ensure all links have type information for locatorFromLink to work
  final readingOrderWithType = readingOrder.map((link) {
    return link.type == null
        ? link.copyWith(type: 'application/xhtml+xml')
        : link;
  }).toList();

  final tocWithType = toc.map((link) {
    return link.type == null
        ? link.copyWith(type: 'application/xhtml+xml')
        : link;
  }).toList();

  return Publication(
    metadata: Metadata(
      localizedTitle: LocalizedString.fromString('Test Book'),
      identifier: 'test-book-id',
    ),
    readingOrder: readingOrderWithType,
    tableOfContents: tocWithType,
  );
}
