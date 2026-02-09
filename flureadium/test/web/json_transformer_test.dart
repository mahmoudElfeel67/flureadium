import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium/src/web/json_transformer.dart';

void main() {
  group('PublicationJsonTransformer', () {
    group('transform', () {
      test('unwraps items wrapper from links', () {
        final json = <String, dynamic>{
          'links': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'link1.html'},
              <String, dynamic>{'href': 'link2.html'},
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['links'], isList);
        expect(result['links'], hasLength(2));
        expect(result['links'][0]['href'], equals('link1.html'));
      });

      test('unwraps items wrapper from readingOrder', () {
        final json = <String, dynamic>{
          'readingOrder': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'chapter1.html'},
              <String, dynamic>{'href': 'chapter2.html'},
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['readingOrder'], isList);
        expect(result['readingOrder'], hasLength(2));
      });

      test('unwraps items wrapper from resources', () {
        final json = <String, dynamic>{
          'resources': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'style.css'},
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['resources'], isList);
        expect(result['resources'], hasLength(1));
      });

      test('renames tableOfContents to toc', () {
        final json = <String, dynamic>{
          'tableOfContents': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'chapter1.html', 'title': 'Chapter 1'},
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result.containsKey('tableOfContents'), isFalse);
        expect(result.containsKey('toc'), isTrue);
        expect(result['toc'], isList);
      });

      test('transforms children in toc', () {
        final json = <String, dynamic>{
          'tableOfContents': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{
                'href': 'chapter1.html',
                'title': 'Chapter 1',
                'children': <String, dynamic>{
                  'items': <dynamic>[
                    <String, dynamic>{
                      'href': 'section1.html',
                      'title': 'Section 1',
                    },
                  ],
                },
              },
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['toc'][0]['children'], isList);
        expect(result['toc'][0]['children'], hasLength(1));
      });

      test('transforms nested children recursively', () {
        final json = <String, dynamic>{
          'tableOfContents': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{
                'href': 'chapter1.html',
                'children': <String, dynamic>{
                  'items': <dynamic>[
                    <String, dynamic>{
                      'href': 'section1.html',
                      'children': <String, dynamic>{
                        'items': <dynamic>[
                          <String, dynamic>{'href': 'subsection1.html'},
                        ],
                      },
                    },
                  ],
                },
              },
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['toc'][0]['children'][0]['children'], isList);
        expect(result['toc'][0]['children'][0]['children'], hasLength(1));
      });

      test('renames authors to author in metadata', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'authors': <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{'name': 'Author Name'},
              ],
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata'].containsKey('authors'), isFalse);
        expect(result['metadata'].containsKey('author'), isTrue);
        expect(result['metadata']['author'], isList);
      });

      test('transforms author name translations', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'authors': <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{
                  'name': <String, dynamic>{
                    'translations': <String, dynamic>{
                      'en': 'English Name',
                      'fr': 'French Name',
                    },
                  },
                },
              ],
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['author'][0]['name'], isMap);
        expect(
          result['metadata']['author'][0]['name']['en'],
          equals('English Name'),
        );
        expect(
          result['metadata']['author'][0]['name']['fr'],
          equals('French Name'),
        );
      });

      test('transforms title translations', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'title': <String, dynamic>{
              'translations': <String, dynamic>{
                'en': 'English Title',
                'de': 'German Title',
              },
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['title'], isMap);
        expect(result['metadata']['title']['en'], equals('English Title'));
        expect(result['metadata']['title']['de'], equals('German Title'));
      });

      test('converts undefined language to und', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'title': <String, dynamic>{
              'translations': <String, dynamic>{
                'undefined': 'Unknown Language Title',
              },
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['title'].containsKey('undefined'), isFalse);
        expect(
          result['metadata']['title']['und'],
          equals('Unknown Language Title'),
        );
      });

      test('transforms sortAs with translations to first value', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'sortAs': <String, dynamic>{
              'translations': <String, dynamic>{'en': 'Sort Value'},
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['sortAs'], equals('Sort Value'));
      });

      test('sets sortAs to null for empty translations', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{
            'sortAs': <String, dynamic>{'translations': <String, dynamic>{}},
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['sortAs'], isNull);
      });

      test('preserves string sortAs', () {
        final json = <String, dynamic>{
          'metadata': <String, dynamic>{'sortAs': 'Direct Sort Value'},
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['metadata']['sortAs'], equals('Direct Sort Value'));
      });

      test('handles empty publication json', () {
        final json = <String, dynamic>{};

        final result = PublicationJsonTransformer.transform(json);

        expect(result, isMap);
        expect(result, isEmpty);
      });

      test('handles publication without metadata', () {
        final json = <String, dynamic>{
          'links': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'link.html'},
            ],
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['links'], isList);
        expect(result.containsKey('metadata'), isFalse);
      });

      test('transforms complete publication json', () {
        final json = <String, dynamic>{
          'links': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'self.json'},
            ],
          },
          'readingOrder': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'chapter1.html'},
              <String, dynamic>{'href': 'chapter2.html'},
            ],
          },
          'resources': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'href': 'style.css'},
            ],
          },
          'tableOfContents': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{
                'href': 'chapter1.html',
                'title': 'Chapter 1',
                'children': <String, dynamic>{
                  'items': <dynamic>[
                    <String, dynamic>{
                      'href': 'section1.html',
                      'title': 'Section 1',
                    },
                  ],
                },
              },
            ],
          },
          'metadata': <String, dynamic>{
            'title': <String, dynamic>{
              'translations': <String, dynamic>{'en': 'Test Book'},
            },
            'authors': <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{
                  'name': <String, dynamic>{
                    'translations': <String, dynamic>{'en': 'Test Author'},
                  },
                },
              ],
            },
          },
        };

        final result = PublicationJsonTransformer.transform(json);

        expect(result['links'], isList);
        expect(result['readingOrder'], isList);
        expect(result['resources'], isList);
        expect(result['toc'], isList);
        expect(result['toc'][0]['children'], isList);
        expect(result['metadata']['title']['en'], equals('Test Book'));
        expect(
          result['metadata']['author'][0]['name']['en'],
          equals('Test Author'),
        );
      });
    });
  });
}
