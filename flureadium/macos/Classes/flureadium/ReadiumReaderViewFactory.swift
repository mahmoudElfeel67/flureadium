import FlutterMacOS
import Foundation
import AppKit
import ReadiumShared

class ReadiumReaderViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var registrar: FlutterPluginRegistrar?

  init(registrar: FlutterPluginRegistrar?) {
    self.registrar = registrar
    super.init()
  }

  func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> NSView {
        // Check if current publication is PDF
        if let publication = getCurrentPublication(),
           publication.conforms(to: .pdf) {
            return PdfReaderView(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args,
                registrar: registrar!).view()
        }

        // Default to EPUB reader
        return ReadiumReaderView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            registrar: registrar!).view()
    }

  // Required for creationParams to not silently become nil
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
