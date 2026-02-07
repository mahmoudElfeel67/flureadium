package dev.mulev.flureadium.models

import org.readium.adapter.pdfium.navigator.PdfiumEngineProvider
import org.readium.r2.navigator.pdf.PdfNavigatorFactory

open class PdfReaderViewModel : ReaderViewModel() {
    var fit: org.readium.r2.navigator.preferences.Fit? = null
    var scroll: Boolean? = null
    var spread: org.readium.r2.navigator.preferences.Spread? = null
    var offsetFirstPage: Boolean? = null

    var navigatorFactory: PdfNavigatorFactory? = null
    var engineProvider: PdfiumEngineProvider? = null
}
