import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flureadium/flureadium.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: ReaderPage());
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _flureadium = Flureadium();
  Publication? _publication;
  Locator? _locator;
  Locator? _savedLocator;
  ReadiumTimebasedState? _timebasedState;
  bool _controlsVisible = true;
  bool _ttsEnabled = false;
  bool _audioEnabled = false;
  bool _audioPaused = false;
  List<ReaderTTSVoice> _voices = [];
  int _voiceIndex = 0;

  late final StreamSubscription<ReadiumReaderStatus> _statusSub;
  late final StreamSubscription<Locator> _locatorSub;
  late final StreamSubscription<ReadiumError> _errorSub;
  late final StreamSubscription<ReadiumTimebasedState> _timebasedSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _flureadium.onReaderStatusChanged.listen(
      (s) => debugPrint('ReaderStatus: $s'),
    );
    _locatorSub = _flureadium.onTextLocatorChanged.listen(
      (l) => setState(() {
        _locator = l;
        _savedLocator = l;
      }),
    );
    _errorSub = _flureadium.onErrorEvent.listen(
      (e) => debugPrint('FlureadiumError: $e'),
    );
    _timebasedSub = _flureadium.onTimebasedPlayerStateChanged.listen(
      (s) => setState(() => _timebasedState = s),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _openEpub());
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _locatorSub.cancel();
    _errorSub.cancel();
    _timebasedSub.cancel();
    super.dispose();
  }

  Future<void> _openEpub() async {
    try {
      final path = await _extractAsset('assets/pubs/moby_dick.epub');
      final pub = await _flureadium.openPublication(path);
      setState(() {
        _publication = pub;
        _ttsEnabled = false;
        _audioEnabled = false;
        _audioPaused = false;
        _voices = [];
        _voiceIndex = 0;
      });
    } catch (e) {
      debugPrint('openEpub error: $e');
    }
  }

  Future<void> _openAudiobook() async {
    try {
      final path = await _extractAsset('assets/pubs/38533.audiobook');
      final pub = await _flureadium.openPublication(path);
      setState(() {
        _publication = pub;
        _ttsEnabled = false;
        _audioEnabled = false;
        _audioPaused = false;
        _voices = [];
        _voiceIndex = 0;
      });
    } catch (e) {
      debugPrint('openAudiobook error: $e');
    }
  }

  Future<void> _openWebPub() async {
    try {
      await _flureadium.setCustomHeaders({'X-Example': 'flureadium-demo'});
      const url =
          'https://readium.org/webpub-manifest/examples/MobyDick/manifest.json';
      final pub = await _flureadium.openPublication(url);
      setState(() {
        _publication = pub;
        _ttsEnabled = false;
        _audioEnabled = false;
        _audioPaused = false;
        _voices = [];
        _voiceIndex = 0;
      });
    } catch (e) {
      debugPrint('openWebPub error: $e');
    }
  }

  Future<String> _extractAsset(String assetPath) async {
    if (kIsWeb) {
      return assetPath;
    }
    final bytes = await rootBundle.load(assetPath);
    final filename = assetPath.split('/').last;
    final tmp = File('${Directory.systemTemp.path}/$filename');
    await tmp.writeAsBytes(bytes.buffer.asUint8List());
    return tmp.path;
  }

  Future<void> _close() async {
    await _flureadium.closePublication();
    setState(() {
      _publication = null;
      _ttsEnabled = false;
      _audioEnabled = false;
      _audioPaused = false;
      _voices = [];
      _voiceIndex = 0;
    });
  }

  Future<void> _setNightPreferences() async {
    await _flureadium.setEPUBPreferences(
      EPUBPreferences(
        fontFamily: 'Georgia',
        fontSize: 100,
        fontWeight: null,
        verticalScroll: false,
        backgroundColor: const Color(0xFF1A1A1A),
        textColor: const Color(0xFFE0E0E0),
      ),
    );
  }

  Future<void> _toggleTts() async {
    if (_ttsEnabled) {
      await _flureadium.stop();
      setState(() {
        _ttsEnabled = false;
        _voices = [];
        _voiceIndex = 0;
      });
    } else {
      await _flureadium.ttsEnable(null);
      await _flureadium.play(null);
      final voices = await _flureadium.ttsGetAvailableVoices();
      setState(() {
        _ttsEnabled = true;
        _voices = voices;
        _voiceIndex = 0;
      });
    }
  }

  Future<void> _nextVoice() async {
    if (_voices.isEmpty) return;
    final next = (_voiceIndex + 1) % _voices.length;
    final voice = _voices[next];
    await _flureadium.ttsSetVoice(voice.identifier, voice.language);
    setState(() => _voiceIndex = next);
  }

  Future<void> _toggleAudio() async {
    if (_audioEnabled && !_audioPaused) {
      await _flureadium.pause();
      setState(() => _audioPaused = true);
    } else if (_audioEnabled && _audioPaused) {
      await _flureadium.resume();
      setState(() => _audioPaused = false);
    } else {
      await _flureadium.audioEnable();
      await _flureadium.play(null);
      setState(() {
        _audioEnabled = true;
        _audioPaused = false;
      });
    }
  }

  Future<void> _addHighlight() async {
    final loc = _locator;
    if (loc == null) return;
    await _flureadium.applyDecorations('highlights', [
      ReaderDecoration(
        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
        locator: loc,
        style: ReaderDecorationStyle(
          style: DecorationStyle.highlight,
          tint: const Color(0xFFFFFF00),
        ),
      ),
    ]);
  }

  Future<void> _goToSaved() async {
    final loc = _savedLocator;
    if (loc == null) return;
    await _flureadium.goToLocator(loc);
  }

  Future<void> _seekForward() =>
      _flureadium.audioSeekBy(const Duration(seconds: 30));

  Future<void> _goToFirstChapter() async {
    final pub = _publication;
    if (pub == null) return;
    final link =
        pub.tableOfContents.firstOrNull ?? pub.readingOrder.firstOrNull;
    if (link == null) return;
    await _flureadium.goByLink(link, pub);
  }

  Future<void> _loadOnly() async {
    try {
      final path = await _extractAsset('assets/pubs/moby_dick.epub');
      final pub = await _flureadium.loadPublication(path);
      debugPrint(
        'Loaded: ${pub.metadata.title} (${pub.tableOfContents.length} chapters)',
      );
    } catch (e) {
      debugPrint('loadOnly error: $e');
    }
  }

  String _fmtDuration(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pub = _publication;
    return Scaffold(
      body: Stack(
        children: [
          if (pub != null)
            ReadiumReaderWidget(
              publication: pub,
              onTap: () => setState(() => _controlsVisible = !_controlsVisible),
              onLocatorChanged: (l) => setState(() => _locator = l),
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (pub == null || _controlsVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_timebasedState case final s?)
                      Text(
                        '${_fmtDuration(s.currentOffset)} / ${_fmtDuration(s.currentDuration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: _openEpub,
                          child: const Text('Open EPUB'),
                        ),
                        TextButton(
                          onPressed: _openAudiobook,
                          child: const Text('Open AudioBook'),
                        ),
                        TextButton(
                          onPressed: _openWebPub,
                          child: const Text('Open WebPub'),
                        ),
                        TextButton(
                          onPressed: _loadOnly,
                          child: const Text('Load Only'),
                        ),
                        TextButton(
                          onPressed: _close,
                          child: const Text('Close'),
                        ),
                        TextButton(
                          onPressed: _flureadium.goLeft,
                          child: const Text('←'),
                        ),
                        TextButton(
                          onPressed: _flureadium.goRight,
                          child: const Text('→'),
                        ),
                        TextButton(
                          onPressed: _flureadium.skipToPrevious,
                          child: const Text('Skip Prev'),
                        ),
                        TextButton(
                          onPressed: _flureadium.skipToNext,
                          child: const Text('Skip Next'),
                        ),
                        if (pub != null)
                          TextButton(
                            onPressed: _goToSaved,
                            child: const Text('Go To Saved'),
                          ),
                        if (pub != null)
                          TextButton(
                            onPressed: _goToFirstChapter,
                            child: const Text('Ch.1'),
                          ),
                        TextButton(
                          onPressed: _setNightPreferences,
                          child: const Text('Night'),
                        ),
                        TextButton(
                          onPressed: _addHighlight,
                          child: const Text('Highlight'),
                        ),
                        TextButton(
                          onPressed: _toggleTts,
                          child: Text(_ttsEnabled ? 'TTS Off' : 'TTS On'),
                        ),
                        if (_ttsEnabled && _voices.isNotEmpty)
                          TextButton(
                            onPressed: _nextVoice,
                            child: Text(
                              'Voice ${_voiceIndex + 1}/${_voices.length}',
                            ),
                          ),
                        if (_ttsEnabled) ...[
                          TextButton(
                            onPressed: _flureadium.previous,
                            child: const Text('Prev Sentence'),
                          ),
                          TextButton(
                            onPressed: _flureadium.next,
                            child: const Text('Next Sentence'),
                          ),
                        ],
                        TextButton(
                          onPressed: _toggleAudio,
                          child: Text(
                            !_audioEnabled
                                ? 'Audio Play'
                                : _audioPaused
                                ? 'Audio Resume'
                                : 'Audio Pause',
                          ),
                        ),
                        if (_audioEnabled)
                          TextButton(
                            onPressed: _seekForward,
                            child: const Text('+30s'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
