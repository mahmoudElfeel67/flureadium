import 'dart:async';
import 'dart:io';

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
  bool _controlsVisible = true;
  bool _ttsEnabled = false;
  bool _audioEnabled = false;

  late final StreamSubscription<ReadiumReaderStatus> _statusSub;
  late final StreamSubscription<Locator> _locatorSub;
  late final StreamSubscription<ReadiumError> _errorSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _flureadium.onReaderStatusChanged.listen(
      (s) => debugPrint('ReaderStatus: $s'),
    );
    _locatorSub = _flureadium.onTextLocatorChanged.listen(
      (l) => setState(() => _locator = l),
    );
    _errorSub = _flureadium.onErrorEvent.listen(
      (e) => debugPrint('FlureadiumError: $e'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _openEpub());
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _locatorSub.cancel();
    _errorSub.cancel();
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
      });
    } catch (e) {
      debugPrint('openAudiobook error: $e');
    }
  }

  Future<void> _openWebPub() async {
    try {
      const url =
          'https://readium.org/webpub-manifest/examples/MobyDick/manifest.json';
      final pub = await _flureadium.openPublication(url);
      setState(() {
        _publication = pub;
        _ttsEnabled = false;
        _audioEnabled = false;
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
      setState(() => _ttsEnabled = false);
    } else {
      await _flureadium.ttsEnable(null);
      await _flureadium.play(null);
      setState(() => _ttsEnabled = true);
    }
  }

  Future<void> _toggleAudio() async {
    if (_audioEnabled) {
      await _flureadium.pause();
      setState(() => _audioEnabled = false);
    } else {
      await _flureadium.audioEnable();
      await _flureadium.play(null);
      setState(() => _audioEnabled = true);
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
                child: Wrap(
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
                    TextButton(onPressed: _close, child: const Text('Close')),
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
                    TextButton(
                      onPressed: _setNightPreferences,
                      child: const Text('Night'),
                    ),
                    TextButton(
                      onPressed: _toggleTts,
                      child: Text(_ttsEnabled ? 'TTS Off' : 'TTS On'),
                    ),
                    TextButton(
                      onPressed: _toggleAudio,
                      child: Text(_audioEnabled ? 'Audio Pause' : 'Audio Play'),
                    ),
                    TextButton(
                      onPressed: _addHighlight,
                      child: const Text('Highlight'),
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
