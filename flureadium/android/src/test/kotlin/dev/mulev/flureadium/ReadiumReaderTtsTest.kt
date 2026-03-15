package dev.mulev.flureadium

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.mockito.Mockito
import org.mockito.Mockito.timeout

/**
 * Tests for ttsCanSpeak and ttsRequestInstallVoice method channel handlers.
 *
 * Verifies correct behavior when no publication is loaded or
 * when no TTS navigator/engine is present.
 */
@ExperimentalCoroutinesApi
internal class ReadiumReaderTtsTest {

    @Test
    fun ttsCanSpeak_returnsFalseWhenNoPublicationLoaded() {
        val handler = PublicationMethodCallHandler()
        val call = MethodCall("ttsCanSpeak", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        handler.onMethodCall(call, mockResult)

        // The handler dispatches on a coroutine, so allow some time
        Mockito.verify(mockResult, timeout(2000)).success(false)
    }

    @Test
    fun ttsRequestInstallVoice_succeedsWithNoEnginePresent() {
        val handler = PublicationMethodCallHandler()
        val call = MethodCall("ttsRequestInstallVoice", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        handler.onMethodCall(call, mockResult)

        // Should succeed with null without throwing
        Mockito.verify(mockResult, timeout(2000)).success(null)
    }
}
