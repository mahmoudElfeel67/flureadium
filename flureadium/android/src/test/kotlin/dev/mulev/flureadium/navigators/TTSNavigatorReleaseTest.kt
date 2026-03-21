package dev.mulev.flureadium.navigators

import dev.mulev.flureadium.FlutterTtsPreferences
import dev.mulev.flureadium.PluginMediaServiceFacade
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.readium.navigator.media.tts.TtsNavigator
import org.readium.navigator.media.tts.android.AndroidTtsEngine
import org.readium.navigator.media.tts.android.AndroidTtsPreferences
import org.readium.navigator.media.tts.android.AndroidTtsSettings
import org.readium.r2.shared.ExperimentalReadiumApi
import org.readium.r2.shared.publication.Publication
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertNull

/**
 * Tests that TTSNavigator.release() awaits cleanup instead of
 * firing-and-forgetting like dispose() does.
 *
 * Uses reflection to access private fields (ttsNavigator, mediaServiceFacade).
 */
@OptIn(ExperimentalReadiumApi::class, ExperimentalCoroutinesApi::class)
internal class TTSNavigatorReleaseTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun TTSNavigator.setField(name: String, value: Any?) {
        val field = TTSNavigator::class.java.getDeclaredField(name)
        field.isAccessible = true
        field.set(this, value)
    }

    private fun TTSNavigator.getField(name: String): Any? {
        val field = TTSNavigator::class.java.getDeclaredField(name)
        field.isAccessible = true
        return field.get(this)
    }

    private fun createNavigator(): TTSNavigator {
        return TTSNavigator(
            mock(Publication::class.java),
            mock(TimebasedNavigator.TimebasedListener::class.java),
            null,
            FlutterTtsPreferences()
        )
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_callsCloseSessionOnMediaServiceFacade() = runTest {
        val navigator = createNavigator()
        val mockFacade = mock(PluginMediaServiceFacade::class.java)
        navigator.setField("mediaServiceFacade", mockFacade)

        navigator.release()

        verify(mockFacade).closeSession()
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_callsCloseOnTtsNavigator() = runTest {
        val navigator = createNavigator()
        val mockTtsNav = mock(TtsNavigator::class.java)
                as TtsNavigator<AndroidTtsSettings, AndroidTtsPreferences, AndroidTtsEngine.Error, AndroidTtsEngine.Voice>
        navigator.setField("ttsNavigator", mockTtsNav)

        navigator.release()

        verify(mockTtsNav).close()
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_nullsOutTtsNavigator() = runTest {
        val navigator = createNavigator()
        val mockTtsNav = mock(TtsNavigator::class.java)
                as TtsNavigator<AndroidTtsSettings, AndroidTtsPreferences, AndroidTtsEngine.Error, AndroidTtsEngine.Voice>
        navigator.setField("ttsNavigator", mockTtsNav)

        navigator.release()

        assertNull(navigator.getField("ttsNavigator"))
    }
}
