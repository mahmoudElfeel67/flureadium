package dev.mulev.flureadium

import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertIs
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.Mockito
import org.mockito.Mockito.verify
import org.readium.r2.shared.util.Error
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
internal class PublicationChannelErrorTest {

    /** Helper: build a Readium Error with an optional cause. */
    private fun fakeError(
        msg: String,
        inner: Error? = null
    ): Error = object : Error {
        override val message: String = msg
        override val cause: Error? = inner
        override fun toString(): String = "FakeError($msg)"
    }

    @Test
    fun publicationError_withCause_detailsIsString() {
        val mockResult = Mockito.mock(MethodChannel.Result::class.java)

        // Unexpected(outerError) stores outerError.cause as the PublicationError.cause.
        // outerError.cause is a Readium Error object — not codec-safe before the fix.
        val innerCause = fakeError("underlying cause")
        val outerError = fakeError("wrapper", inner = innerCause)
        val error = PublicationError.Unexpected(outerError)

        mockResult.publicationError("testMethod", error)

        val detailsCaptor = ArgumentCaptor.forClass(Any::class.java)
        verify(mockResult).error(
            Mockito.eq(PublicationError.ReadiumExceptionType.unknown.name),
            Mockito.eq("wrapper"),
            detailsCaptor.capture()
        )
        // details must be a String, not a Readium Error object
        assertIs<String>(detailsCaptor.value)
    }

    @Test
    fun publicationError_withoutCause_detailsIsNull() {
        val mockResult = Mockito.mock(MethodChannel.Result::class.java)
        val error = PublicationError.Unavailable()

        mockResult.publicationError("testMethod", error)

        verify(mockResult).error(
            PublicationError.ReadiumExceptionType.unavailable.name,
            "Resource unavailable",
            null
        )
    }

    @Test
    fun publicationError_unexpected_errorCodeAndMessagePreserved() {
        val mockResult = Mockito.mock(MethodChannel.Result::class.java)
        val outerError = fakeError("specific error message")
        val error = PublicationError.Unexpected(outerError)

        mockResult.publicationError("testMethod", error)

        verify(mockResult).error("unknown", "specific error message", null)
    }

    @Test
    fun publicationError_unknown_errorCodeAndMessagePreserved() {
        val mockResult = Mockito.mock(MethodChannel.Result::class.java)
        val error = PublicationError.Unknown("something went wrong")

        mockResult.publicationError("testMethod", error)

        verify(mockResult).error("unknown", "something went wrong", null)
    }
}
