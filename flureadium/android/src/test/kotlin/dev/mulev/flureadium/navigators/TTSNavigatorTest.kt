package dev.mulev.flureadium.navigators

import dev.mulev.flureadium.FlutterTtsPreferences
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.mockito.Mockito.mock
import org.readium.navigator.media.tts.android.AndroidTtsEngine
import org.readium.r2.shared.ExperimentalReadiumApi
import org.readium.r2.shared.publication.Locator
import org.readium.r2.shared.publication.Publication
import org.readium.r2.shared.util.Language

/**
 * Tests for TTSNavigator:
 * - TTS error type classification (companion function)
 * - Scroll-suppression flag clearing on explicit navigation
 */
@OptIn(ExperimentalReadiumApi::class, ExperimentalCoroutinesApi::class)
internal class TTSNavigatorTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // -- Reflection helpers (same pattern as TTSNavigatorReleaseTest) --

    private fun TTSNavigator.setFlag(name: String, value: Boolean) {
        val field = TTSNavigator::class.java.getDeclaredField(name)
        field.isAccessible = true
        field.setBoolean(this, value)
    }

    private fun TTSNavigator.getFlag(name: String): Boolean {
        val field = TTSNavigator::class.java.getDeclaredField(name)
        field.isAccessible = true
        return field.getBoolean(this)
    }

    private fun createNavigator(): TTSNavigator {
        return TTSNavigator(
            mock(Publication::class.java),
            mock(TimebasedNavigator.TimebasedListener::class.java),
            null,
            FlutterTtsPreferences()
        )
    }

    // -- Error classification tests --

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

    // -- Suppression flag tests --

    @Test
    fun goBack_clearsSuppressScrollFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("suppressScrollUntilNewLocation", true)

        nav.goBack()

        assertFalse(nav.getFlag("suppressScrollUntilNewLocation"))
    }

    @Test
    fun goBack_clearsIsInSuppressedLocationFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("isInSuppressedLocation", true)

        nav.goBack()

        assertFalse(nav.getFlag("isInSuppressedLocation"))
    }

    @Test
    fun goForward_clearsSuppressScrollFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("suppressScrollUntilNewLocation", true)

        nav.goForward()

        assertFalse(nav.getFlag("suppressScrollUntilNewLocation"))
    }

    @Test
    fun goForward_clearsIsInSuppressedLocationFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("isInSuppressedLocation", true)

        nav.goForward()

        assertFalse(nav.getFlag("isInSuppressedLocation"))
    }

    @Test
    fun goToLocator_clearsSuppressScrollFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("suppressScrollUntilNewLocation", true)

        nav.goToLocator(mock(Locator::class.java))

        assertFalse(nav.getFlag("suppressScrollUntilNewLocation"))
    }

    @Test
    fun goToLocator_clearsIsInSuppressedLocationFlag() = runTest {
        val nav = createNavigator()
        nav.setFlag("isInSuppressedLocation", true)

        nav.goToLocator(mock(Locator::class.java))

        assertFalse(nav.getFlag("isInSuppressedLocation"))
    }
}
