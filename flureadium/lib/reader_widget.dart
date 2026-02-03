import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'reader_channel.dart';
import 'src/reader/orientation_handler_mixin.dart';
import 'src/reader/reader_lifecycle_mixin.dart';
import 'src/reader/wakelock_manager_mixin.dart';
import 'src/utils/toc_matcher.dart';

const _viewType = 'dev.mulev.flureadium/ReadiumReaderWidget';

/// A ReadiumReaderWidget wraps a native Kotlin/Swift Readium navigator widget.
class ReadiumReaderWidget extends StatefulWidget {
  const ReadiumReaderWidget({
    required this.publication,
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.initialLocator,
    this.onTap,
    this.onGoLeft,
    this.onGoRight,
    this.onSwipe,
    this.onExternalLinkActivated,
    super.key,
  });

  final Publication publication;
  final Widget loadingWidget;
  final Locator? initialLocator;
  final VoidCallback? onTap;
  final VoidCallback? onGoLeft;
  final VoidCallback? onGoRight;
  final VoidCallback? onSwipe;
  final Function(String)? onExternalLinkActivated;

  @override
  State<StatefulWidget> createState() => _ReadiumReaderWidgetState();
}

class _ReadiumReaderWidgetState extends State<ReadiumReaderWidget>
    with WakelockManagerMixin, ReaderLifecycleMixin, OrientationHandlerMixin
    implements ReadiumReaderWidgetInterface {
  ReadiumReaderChannel? _channel;
  bool wasDestroyed = false;
  bool isReady = false;

  final _isReadyCompleter = Completer<Locator>();

  late Widget _readerWidget;

  EPUBPreferences? get _defaultPreferences {
    return readium.defaultPreferences;
  }

  @override
  void initState() {
    super.initState();
    R2Log.d('ReadiumReaderWidget initiated');

    _readerWidget = _buildNativeReader();
    enableWakelock();
    setCurrentWidgetInterface(this);
  }

  @override
  void dispose() {
    R2Log.d('ReadiumReaderWidget disposed');
    cleanupWidgetInterface(_channel?.name);
    _channel?.dispose();
    _channel = null;
    lastOrientation = null;

    disableWakelock();
    wasDestroyed = true;

    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    handleOrientationChange(
      currentOrientation: MediaQuery.orientationOf(context),
      isReady: isReady,
      currentLocator: _currentLocator,
      channel: _channel,
    );

    return Listener(
      onPointerDown: (final event) {
        R2Log.d('[TAP-DEBUG] Listener onPointerDown at ${event.position}');
        enableWakelock();
      },
      onPointerUp: (final event) {
        R2Log.d('[TAP-DEBUG] Listener onPointerUp at ${event.position}');
      },
      child: _readerWidget,
    );
  }

  @override
  Future<void> go(
    final Locator locator, {
    required final bool isAudioBookWithText,
    final bool animated = false,
  }) async {
    R2Log.d(() => 'Go to $locator');

    await _channel?.go(
      locator,
      animated: animated,
      isAudioBookWithText: isAudioBookWithText,
    );

    R2Log.d('Done');
  }

  @override
  Future<void> goLeft({final bool animated = true}) async => _channel?.goLeft();

  @override
  Future<void> goRight({final bool animated = true}) async =>
      _channel?.goRight();

  @override
  Future<void> skipToNext({final bool animated = true}) async {
    final toc = widget.publication.toc;
    if (toc.isEmpty || _currentLocator == null) {
      R2Log.d('skipToNext: no TOC or no current locator');
      return;
    }

    // Primary path: toc= fragment matching (sub-chapter granularity)
    int curIndex = -1;
    String? currentHref = getTextLocatorHrefWithTocFragment(_currentLocator);

    if (currentHref != null) {
      // Ensure we are at least 1 page into the current chapter, if not in scroll mode.
      if (readium.defaultPreferences?.verticalScroll != true) {
        await _channel?.goRight(animated: false);
        final loc = await _channel?.getCurrentLocator();
        currentHref = getTextLocatorHrefWithTocFragment(loc);
      }
      if (currentHref != null) {
        curIndex = toc.indexWhere((l) => l.href == currentHref);
      }
    }

    // Fallback: path-based matching (file-level granularity)
    if (curIndex == -1) {
      R2Log.d('skipToNext: toc= fragment matching failed, using path fallback');
      curIndex = findTocIndexByPath(_currentLocator!, toc, lastMatch: true);
    }

    R2Log.d('skipToNext: curIndex=$curIndex, tocLength=${toc.length}');

    if (curIndex == -1 || curIndex >= toc.length - 1) {
      R2Log.d('skipToNext: cannot advance (not found or at last chapter)');
      return;
    }

    final newIndex = curIndex + 1;
    final nextChapter = widget.publication.locatorFromLink(toc[newIndex]);
    R2Log.d('skipToNext: navigating to index $newIndex: ${toc[newIndex].href}');
    if (nextChapter != null) {
      await _channel?.go(
        nextChapter,
        isAudioBookWithText: false,
        animated: true,
      );
    }
  }

  @override
  Future<void> skipToPrevious({final bool animated = true}) async {
    final toc = widget.publication.toc;
    if (toc.isEmpty || _currentLocator == null) {
      R2Log.d('skipToPrevious: no TOC or no current locator');
      return;
    }

    // Primary path: toc= fragment matching (sub-chapter granularity)
    int curIndex = -1;
    final currentHref = getTextLocatorHrefWithTocFragment(_currentLocator);
    if (currentHref != null) {
      curIndex = toc.indexWhere((l) => l.href == currentHref);
    }

    // Fallback: path-based matching (file-level granularity)
    if (curIndex == -1) {
      R2Log.d(
          'skipToPrevious: toc= fragment matching failed, using path fallback');
      curIndex = findTocIndexByPath(_currentLocator!, toc, lastMatch: false);
    }

    R2Log.d('skipToPrevious: curIndex=$curIndex, tocLength=${toc.length}');

    if (curIndex <= 0) {
      R2Log.d('skipToPrevious: cannot go back (not found or at first chapter)');
      return;
    }

    final newIndex = curIndex - 1;
    final previousChapter = widget.publication.locatorFromLink(toc[newIndex]);
    R2Log.d(
        'skipToPrevious: navigating to index $newIndex: ${toc[newIndex].href}');
    if (previousChapter != null) {
      await _channel?.go(
        previousChapter,
        isAudioBookWithText: false,
        animated: true,
      );
    }
  }

  @override
  Future<Locator?> getLocatorFragments(final Locator locator) async {
    R2Log.d('getLocatorFragments: $locator');

    await _awaitNativeViewReady();

    return await _channel?.getLocatorFragments(locator);
  }

  @override
  Future<Locator?> getCurrentLocator() async {
    R2Log.d('GetCurrentLocator()');
    return _channel?.getCurrentLocator();
  }

  @override
  Future<void> setEPUBPreferences(EPUBPreferences preferences) async {
    _channel?.setEPUBPreferences(preferences);
  }

  @override
  Future<void> applyDecorations(
    String id,
    List<ReaderDecoration> decorations,
  ) async {
    await _channel?.applyDecorations(id, decorations);
  }

  Widget _buildNativeReader() {
    final publication = widget.publication;

    R2Log.d(publication.identifier);

    final defaultPreferences = _defaultPreferences?.toJson();

    final creationParams = <String, dynamic>{
      'pubIdentifier': publication.identifier,
      'preferences': defaultPreferences,
      'initialLocator': widget.initialLocator == null
          ? null
          : json.encode(widget.initialLocator),
    };

    R2Log.d('creationParams=$creationParams');

    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (final context, final controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const {},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
        onCreatePlatformView: (final params) =>
            PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: _viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: creationParams,
                creationParamsCodec: const StandardMessageCodec(),
              )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
              ..create(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return ColoredBox(
      color: const Color(0xffff00ff),
      child: Center(
        child: Text(
          'TODO — Implement ReadiumReaderWidget on ${Platform.operatingSystem}.',
        ),
      ),
    );
  }

  Locator? _currentLocator;

  void _onPlatformViewCreated(final int id) {
    _channel = ReadiumReaderChannel(
      '$_viewType:$id',
      onPageChanged: (final locator) {
        debugPrint('onPageChanged: ${locator.toJson()}');
        _currentLocator = locator;

        if (isReady == false) {
          setState(() {
            isReady = true;
          });
          _isReadyCompleter.complete(locator);
        }
      },
    );

    R2Log.d('New widget is: ${_channel?.name}');

    // TODO: This is just to demo how to use and debounce the Stream, remove when appropriate.
    final nativeLocatorStream = readium.onTextLocatorChanged
        .debounceTime(const Duration(milliseconds: 50))
        .asBroadcastStream()
        .distinct();

    nativeLocatorStream.listen((locator) {
      R2Log.d('ReaderWidget.LocatorChanged - $locator');
    });
  }

  Future _awaitNativeViewReady() {
    return _isReadyCompleter.future;
  }

  /// Gets a Locator's href with toc fragment appended as identifier
  String? getTextLocatorHrefWithTocFragment(Locator? locator) {
    if (locator == null) {
      return null;
    }

    final txtLoc = locator.toTextLocator();
    final tocFragment = locator.locations?.fragments.firstWhereOrNull(
      (f) => f.startsWith("toc="),
    );
    if (tocFragment == null) {
      return null;
    }
    return '${txtLoc.toTextLocator().hrefPath}#${tocFragment.substring(4)}';
  }
}
