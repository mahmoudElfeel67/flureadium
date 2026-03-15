package dev.mulev.flureadium.navigators

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.readium.navigator.media.tts.android.AndroidTtsEngine
import org.readium.r2.shared.ExperimentalReadiumApi
import org.readium.r2.shared.util.Language

/**
 * Tests for TTS error type discrimination logic in TTSNavigator.
 *
 * The companion function classifyTtsErrorType maps engine-level errors
 * to a string discriminator sent to Dart:
 * - AndroidTtsEngine.Error.LanguageMissingData -> "languageMissingData"
 * - Any other engine error -> "unknown"
 * - null -> "unknown"
 */
@OptIn(ExperimentalReadiumApi::class, ExperimentalCoroutinesApi::class)
internal class TTSNavigatorTest {

    @Test
    fun classifyTtsErrorType_withLanguageMissingData_returnsLanguageMissingData() {
        val error: AndroidTtsEngine.Error = AndroidTtsEngine.Error.LanguageMissingData(
            language = Language("en")
        )
        val result = TTSNavigator.classifyTtsErrorType(error)
        assertEquals("languageMissingData", result)
    }

    @Test
    fun classifyTtsErrorType_withNull_returnsUnknown() {
        val result = TTSNavigator.classifyTtsErrorType(null)
        assertEquals("unknown", result)
    }
}
