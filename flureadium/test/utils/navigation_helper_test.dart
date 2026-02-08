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
        final currentLocator = Locator(
          href: '/ch2.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch1.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch2.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch2.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/cover.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final toc = [Link(href: '/ch1.xhtml', title: 'Chapter 1')];
        final readingOrder = [
          Link(href: '/cover.xhtml'),
          Link(href: '/titlepage.xhtml'),
          Link(href: '/toc.xhtml'),
          Link(href: '/ch1.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/titlepage.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final toc = [Link(href: '/ch1.xhtml', title: 'Chapter 1')];
        final readingOrder = [Link(href: '/ch1.xhtml')];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/phantom.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/interstitial.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch2.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch2.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch1.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/ch1.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/epilogue.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final toc = [Link(href: '/ch1.xhtml', title: 'Chapter 1')];
        final readingOrder = [
          Link(href: '/ch1.xhtml'),
          Link(href: '/epilogue.xhtml'),
          Link(href: '/appendix.xhtml'),
        ];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/appendix.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final toc = [Link(href: '/ch1.xhtml', title: 'Chapter 1')];
        final readingOrder = [Link(href: '/ch1.xhtml')];
        final publication = _createPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/phantom.xhtml',
          type: 'application/xhtml+xml',
        );

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
        final currentLocator = Locator(
          href: '/interstitial.xhtml',
          type: 'application/xhtml+xml',
        );

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

  group('boundary detection scenarios', () {
    group('skipToNext boundaries', () {
      test(
        'canNavigate is false when at last chapter with no post-TOC pages',
        () {
          // Publication: ch1, ch2, ch3 (ch3 is last file in readingOrder)
          final readingOrder = [
            Link(href: 'ch1.xhtml'),
            Link(href: 'ch2.xhtml'),
            Link(href: 'ch3.xhtml'),
          ];
          final toc = [
            Link(href: 'ch1.xhtml', title: 'Chapter 1'),
            Link(href: 'ch2.xhtml', title: 'Chapter 2'),
            Link(href: 'ch3.xhtml', title: 'Chapter 3'),
          ];
          final publication = _createPublication(toc, readingOrder);

          // At ch3 (last TOC entry, index 2)
          final currentLocator = Locator(
            href: 'ch3.xhtml',
            type: 'application/xhtml+xml',
          );

          final decision = decideSkipToNext(
            currentLocator: currentLocator,
            toc: toc,
            readingOrder: readingOrder,
            currentTocIndex: 2,
            publication: publication,
          );

          expect(decision.canNavigate, isFalse);
          expect(decision.reason, 'Already at last page');
        },
      );

      test('canNavigate is true when at last chapter with post-TOC pages', () {
        // Publication: ch1, ch2, ch3, epilogue (epilogue not in TOC)
        final readingOrder = [
          Link(href: 'ch1.xhtml'),
          Link(href: 'ch2.xhtml'),
          Link(href: 'ch3.xhtml'),
          Link(href: 'epilogue.xhtml'),
        ];
        final toc = [
          Link(href: 'ch1.xhtml', title: 'Chapter 1'),
          Link(href: 'ch2.xhtml', title: 'Chapter 2'),
          Link(href: 'ch3.xhtml', title: 'Chapter 3'),
        ];
        final publication = _createPublication(toc, readingOrder);

        // At ch3 (last TOC entry, but epilogue exists after)
        final currentLocator = Locator(
          href: 'ch3.xhtml',
          type: 'application/xhtml+xml',
        );

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 2,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, 'epilogue.xhtml');
        expect(decision.targetTocIndex, isNull);
      });

      test('canNavigate is true when at second-to-last chapter', () {
        // Publication: ch1, ch2, ch3
        final readingOrder = [
          Link(href: 'ch1.xhtml'),
          Link(href: 'ch2.xhtml'),
          Link(href: 'ch3.xhtml'),
        ];
        final toc = [
          Link(href: 'ch1.xhtml', title: 'Chapter 1'),
          Link(href: 'ch2.xhtml', title: 'Chapter 2'),
          Link(href: 'ch3.xhtml', title: 'Chapter 3'),
        ];
        final publication = _createPublication(toc, readingOrder);

        // At ch2 (second-to-last chapter)
        final currentLocator = Locator(
          href: 'ch2.xhtml',
          type: 'application/xhtml+xml',
        );

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, 'ch3.xhtml');
        expect(decision.targetTocIndex, 2);
      });
    });

    group('skipToPrevious boundaries', () {
      test(
        'canNavigate is false when at first chapter with no pre-TOC pages',
        () {
          // Publication: ch1, ch2, ch3 (ch1 is first file in readingOrder)
          final readingOrder = [
            Link(href: 'ch1.xhtml'),
            Link(href: 'ch2.xhtml'),
            Link(href: 'ch3.xhtml'),
          ];
          final toc = [
            Link(href: 'ch1.xhtml', title: 'Chapter 1'),
            Link(href: 'ch2.xhtml', title: 'Chapter 2'),
            Link(href: 'ch3.xhtml', title: 'Chapter 3'),
          ];
          final publication = _createPublication(toc, readingOrder);

          // At ch1 (first TOC entry, index 0)
          final currentLocator = Locator(
            href: 'ch1.xhtml',
            type: 'application/xhtml+xml',
          );

          final decision = decideSkipToPrevious(
            currentLocator: currentLocator,
            toc: toc,
            readingOrder: readingOrder,
            currentTocIndex: 0,
            publication: publication,
          );

          expect(decision.canNavigate, isFalse);
          expect(decision.reason, 'Already at first page');
        },
      );

      test('canNavigate is true when at first chapter with pre-TOC pages', () {
        // Publication: cover, ch1, ch2, ch3 (cover not in TOC)
        final readingOrder = [
          Link(href: 'cover.xhtml'),
          Link(href: 'ch1.xhtml'),
          Link(href: 'ch2.xhtml'),
          Link(href: 'ch3.xhtml'),
        ];
        final toc = [
          Link(href: 'ch1.xhtml', title: 'Chapter 1'),
          Link(href: 'ch2.xhtml', title: 'Chapter 2'),
          Link(href: 'ch3.xhtml', title: 'Chapter 3'),
        ];
        final publication = _createPublication(toc, readingOrder);

        // At ch1 (first TOC entry, but cover exists before)
        final currentLocator = Locator(
          href: 'ch1.xhtml',
          type: 'application/xhtml+xml',
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, 'cover.xhtml');
        expect(decision.targetTocIndex, isNull);
      });

      test('canNavigate is true when at second chapter', () {
        // Publication: ch1, ch2, ch3
        final readingOrder = [
          Link(href: 'ch1.xhtml'),
          Link(href: 'ch2.xhtml'),
          Link(href: 'ch3.xhtml'),
        ];
        final toc = [
          Link(href: 'ch1.xhtml', title: 'Chapter 1'),
          Link(href: 'ch2.xhtml', title: 'Chapter 2'),
          Link(href: 'ch3.xhtml', title: 'Chapter 3'),
        ];
        final publication = _createPublication(toc, readingOrder);

        // At ch2 (second chapter)
        final currentLocator = Locator(
          href: 'ch2.xhtml',
          type: 'application/xhtml+xml',
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1,
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, 'ch1.xhtml');
        expect(decision.targetTocIndex, 0);
      });
    });
  });

  group('PDF navigation', () {
    group('decideSkipToNext for PDF', () {
      test('navigates to first chapter when before first TOC page', () {
        // PDF with first chapter starting at page 11
        final toc = [
          Link(href: '/publication.pdf#page=11', title: 'Chapter 1'),
          Link(href: '/publication.pdf#page=25', title: 'Chapter 2'),
          Link(href: '/publication.pdf#page=50', title: 'Chapter 3'),
        ];
        final readingOrder = [Link(href: '/publication.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        // Current page is 3 (before first chapter)
        final currentLocator = Locator(
          href: '/publication.pdf',
          type: 'application/pdf',
          locations: Locations(position: 3),
        );

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC (before first chapter)
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/publication.pdf#page=11');
        expect(decision.targetTocIndex, 0);
      });

      test('navigates to next chapter in PDF', () {
        final toc = [
          Link(href: '/doc.pdf#page=11', title: 'Chapter 1'),
          Link(href: '/doc.pdf#page=25', title: 'Chapter 2'),
          Link(href: '/doc.pdf#page=50', title: 'Chapter 3'),
        ];
        final readingOrder = [Link(href: '/doc.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/doc.pdf',
          type: 'application/pdf',
          locations: Locations(position: 15),
        );

        final decision = decideSkipToNext(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0, // At first chapter
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/doc.pdf#page=25');
        expect(decision.targetTocIndex, 1);
      });
    });

    group('decideSkipToPrevious for PDF', () {
      test(
        'navigates to page 1 when at first chapter with pre-chapter pages',
        () {
          // PDF with first chapter starting at page 11 (pages 1-10 are pre-chapter)
          final toc = [
            Link(href: '/publication.pdf#page=11', title: 'Chapter 1'),
            Link(href: '/publication.pdf#page=25', title: 'Chapter 2'),
            Link(href: '/publication.pdf#page=50', title: 'Chapter 3'),
          ];
          final readingOrder = [Link(href: '/publication.pdf')];
          final publication = _createPdfPublication(toc, readingOrder);
          // Current page is 11 (first chapter)
          final currentLocator = Locator(
            href: '/publication.pdf',
            type: 'application/pdf',
            locations: Locations(position: 11),
          );

          final decision = decideSkipToPrevious(
            currentLocator: currentLocator,
            toc: toc,
            readingOrder: readingOrder,
            currentTocIndex: 0, // At first chapter
            publication: publication,
          );

          expect(decision.canNavigate, isTrue);
          expect(decision.targetLink?.href, '/publication.pdf#page=1');
          expect(decision.targetTocIndex, isNull); // Pre-chapter content
        },
      );

      test('aborts when at first chapter with no pre-chapter pages', () {
        // PDF with first chapter starting at page 1 (no pre-chapter content)
        final toc = [
          Link(href: '/doc.pdf#page=1', title: 'Chapter 1'),
          Link(href: '/doc.pdf#page=25', title: 'Chapter 2'),
        ];
        final readingOrder = [Link(href: '/doc.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/doc.pdf',
          type: 'application/pdf',
          locations: Locations(position: 1),
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 0, // At first chapter
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Already at first page');
      });

      test('navigates to previous chapter in PDF', () {
        final toc = [
          Link(href: '/doc.pdf#page=11', title: 'Chapter 1'),
          Link(href: '/doc.pdf#page=25', title: 'Chapter 2'),
          Link(href: '/doc.pdf#page=50', title: 'Chapter 3'),
        ];
        final readingOrder = [Link(href: '/doc.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        final currentLocator = Locator(
          href: '/doc.pdf',
          type: 'application/pdf',
          locations: Locations(position: 30),
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: 1, // At second chapter
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/doc.pdf#page=11');
        expect(decision.targetTocIndex, 0);
      });

      test('aborts when on pre-chapter page (before first TOC entry)', () {
        final toc = [
          Link(href: '/doc.pdf#page=11', title: 'Chapter 1'),
          Link(href: '/doc.pdf#page=25', title: 'Chapter 2'),
        ];
        final readingOrder = [Link(href: '/doc.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        // Current page is 3 (before first chapter)
        final currentLocator = Locator(
          href: '/doc.pdf',
          type: 'application/pdf',
          locations: Locations(position: 3),
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC (before first chapter)
          publication: publication,
        );

        expect(decision.canNavigate, isFalse);
        expect(decision.reason, 'Already at first page');
      });

      test('navigates to last chapter when after last TOC page', () {
        final toc = [
          Link(href: '/doc.pdf#page=11', title: 'Chapter 1'),
          Link(href: '/doc.pdf#page=25', title: 'Chapter 2'),
          Link(href: '/doc.pdf#page=50', title: 'Chapter 3'),
        ];
        final readingOrder = [Link(href: '/doc.pdf')];
        final publication = _createPdfPublication(toc, readingOrder);
        // Current page is 100 (after last chapter)
        final currentLocator = Locator(
          href: '/doc.pdf',
          type: 'application/pdf',
          locations: Locations(position: 100),
        );

        final decision = decideSkipToPrevious(
          currentLocator: currentLocator,
          toc: toc,
          readingOrder: readingOrder,
          currentTocIndex: -1, // Not in TOC (after last chapter)
          publication: publication,
        );

        expect(decision.canNavigate, isTrue);
        expect(decision.targetLink?.href, '/doc.pdf#page=50');
        expect(decision.targetTocIndex, 2);
      });
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

/// Helper to create a PDF test publication.
Publication _createPdfPublication(List<Link> toc, List<Link> readingOrder) {
  // PDF reading order and TOC use application/pdf type
  final readingOrderWithType = readingOrder.map((link) {
    return link.type == null ? link.copyWith(type: 'application/pdf') : link;
  }).toList();

  final tocWithType = toc.map((link) {
    return link.type == null ? link.copyWith(type: 'application/pdf') : link;
  }).toList();

  return Publication(
    metadata: Metadata(
      localizedTitle: LocalizedString.fromString('Test PDF'),
      identifier: 'test-pdf-id',
    ),
    readingOrder: readingOrderWithType,
    tableOfContents: tocWithType,
  );
}
