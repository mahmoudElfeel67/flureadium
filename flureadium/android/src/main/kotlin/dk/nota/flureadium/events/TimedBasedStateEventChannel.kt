package dk.nota.flureadium.events

import dk.nota.flureadium.jsonEncode
import dk.nota.flureadium.models.ReadiumTimebasedState
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.launch

/**
 * Event channel for sending time-based state updates to Flutter.
 */
class TimedBasedStateEventChannel(messenger: BinaryMessenger) :
    EventChannelWrapper<ReadiumTimebasedState>(messenger, "dk.nota.flureadium/timebased-state") {
    override fun sendEvent(data: ReadiumTimebasedState) {
        mainScope.launch {
            eventSink?.success(jsonEncode(data.toJSON()))
        }
    }
}
