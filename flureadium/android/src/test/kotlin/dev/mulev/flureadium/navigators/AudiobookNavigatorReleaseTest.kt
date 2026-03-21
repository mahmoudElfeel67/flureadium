package dev.mulev.flureadium.navigators

import dev.mulev.flureadium.FlutterAudioPreferences
import dev.mulev.flureadium.PluginMediaServiceFacade
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.readium.adapter.exoplayer.audio.ExoPlayerPreferences
import org.readium.adapter.exoplayer.audio.ExoPlayerSettings
import org.readium.navigator.media.audio.AudioNavigator
import org.readium.r2.shared.ExperimentalReadiumApi
import org.readium.r2.shared.publication.Publication
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertNull

/**
 * Tests that AudiobookNavigator.release() awaits cleanup instead of
 * firing-and-forgetting like dispose() does.
 *
 * Uses a test subclass to access protected fields (audioNavigator, mediaServiceFacade).
 */
@OptIn(ExperimentalReadiumApi::class, ExperimentalCoroutinesApi::class)
internal class AudiobookNavigatorReleaseTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    /**
     * Subclass that exposes protected fields for testing.
     */
    private class TestableAudiobookNavigator(
        publication: Publication,
        listener: TimebasedNavigator.TimebasedListener,
        preferences: FlutterAudioPreferences
    ) : AudiobookNavigator(publication, listener, null, preferences) {

        override suspend fun initNavigator() {
            // No-op — skip ExoPlayer setup in tests
        }

        fun setTestAudioNavigator(
            nav: AudioNavigator<ExoPlayerSettings, ExoPlayerPreferences>?
        ) {
            audioNavigator = nav
        }

        fun setTestMediaServiceFacade(facade: PluginMediaServiceFacade?) {
            mediaServiceFacade = facade
        }

        fun getTestAudioNavigator() = audioNavigator
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_callsCloseSessionOnMediaServiceFacade() = runTest {
        val navigator = TestableAudiobookNavigator(
            mock(Publication::class.java),
            mock(TimebasedNavigator.TimebasedListener::class.java),
            FlutterAudioPreferences()
        )
        val mockFacade = mock(PluginMediaServiceFacade::class.java)
        navigator.setTestMediaServiceFacade(mockFacade)

        navigator.release()

        verify(mockFacade).closeSession()
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_callsCloseOnAudioNavigator() = runTest {
        val navigator = TestableAudiobookNavigator(
            mock(Publication::class.java),
            mock(TimebasedNavigator.TimebasedListener::class.java),
            FlutterAudioPreferences()
        )
        val mockAudioNav = mock(AudioNavigator::class.java)
                as AudioNavigator<ExoPlayerSettings, ExoPlayerPreferences>
        navigator.setTestAudioNavigator(mockAudioNav)

        navigator.release()

        verify(mockAudioNav).close()
    }

    @Suppress("UNCHECKED_CAST")
    @Test
    fun release_nullsOutAudioNavigator() = runTest {
        val navigator = TestableAudiobookNavigator(
            mock(Publication::class.java),
            mock(TimebasedNavigator.TimebasedListener::class.java),
            FlutterAudioPreferences()
        )
        val mockAudioNav = mock(AudioNavigator::class.java)
                as AudioNavigator<ExoPlayerSettings, ExoPlayerPreferences>
        navigator.setTestAudioNavigator(mockAudioNav)

        navigator.release()

        assertNull(navigator.getTestAudioNavigator())
    }
}
