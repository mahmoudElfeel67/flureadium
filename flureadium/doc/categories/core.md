# Core

The core classes provide the main entry points for the Flureadium plugin.

## Main Entry Point

The [Flureadium] singleton is your main interface to the plugin. Use it to:

- Open and close publications
- Control playback (TTS, audiobook)
- Navigate within publications
- Listen to reader events

## Reader Widget

The [ReaderWidget] displays the publication content and handles user interactions
like page turns and text selection.

## Streams

Subscribe to event streams for:
- Position changes ([onTextLocatorChanged])
- Playback state ([onTimebasedPlayerStateChanged])
- Reader status ([onReaderStatusChanged])
- Errors ([onErrorEvent])
