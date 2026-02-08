//
//  PdfReaderView.swift
//  flureadium
//
//  PDF reader view using Readium's PDFNavigatorViewController.
//  Follows the same pattern as ReadiumReaderView.swift for EPUB.
//

import ReadiumNavigator
import ReadiumShared
import Flutter
import UIKit

private let TAG = "PdfReaderView"
private let PdfReaderStatusReady = "ready"
private let PdfReaderStatusLoading = "loading"
private let PdfReaderStatusClosed = "closed"
private let PdfReaderStatusError = "error"

let pdfReaderViewType = "dev.mulev.flureadium/PdfReaderWidget"

class PdfReaderView: NSObject, FlutterPlatformView, PDFNavigatorDelegate, VisualNavigatorDelegate {

  private let channel: ReadiumReaderChannel
  private var errorStreamHandler: EventStreamHandler?
  private var readerStatusStreamHandler: EventStreamHandler?
  private var textLocatorStreamHandler: EventStreamHandler?
  private let _view: UIView
  private let pdfViewController: PDFNavigatorViewController
  private var hasSentReady = false
  private let disableDoubleTapZoom: Bool
  private let disableTextSelection: Bool
  private let disableDragGestures: Bool

  var publicationIdentifier: String?

  func view() -> UIView {
    print(TAG, "::getView")
    return _view
  }

  deinit {
    print(TAG, "::dispose")
    pdfViewController.view.removeFromSuperview()
    pdfViewController.delegate = nil
    textLocatorStreamHandler?.dispose()
    textLocatorStreamHandler = nil
    readerStatusStreamHandler?.dispose()
    readerStatusStreamHandler = nil
    errorStreamHandler?.dispose()
    errorStreamHandler = nil
    channel.setMethodCallHandler(nil)
    setCurrentPdfReaderView(nil)
  }

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    registrar: FlutterPluginRegistrar
  ) {
    print(TAG, "::init")
    let creationParams = args as! Dictionary<String, Any?>

    let publication = getCurrentPublication()!

    let preferencesMap = creationParams["preferences"] as? Dictionary<String, Any>
    let pdfPreferences = preferencesMap != nil ? PDFPreferences(fromMap: preferencesMap!) : PDFPreferences()

    // Read Flutter PDF preferences for gesture control settings
    let flutterPrefs = FlutterPdfPreferences(fromMap: preferencesMap)
    disableDoubleTapZoom = flutterPrefs.disableDoubleTapZoom ?? false
    disableTextSelection = flutterPrefs.disableTextSelection ?? false
    disableDragGestures = flutterPrefs.disableDragGestures ?? false
    print(TAG, "PDF Preferences - disableDoubleTapZoom: \(disableDoubleTapZoom), disableTextSelection: \(disableTextSelection), disableDragGestures: \(disableDragGestures)")

    let locatorStr = creationParams["initialLocator"] as? String
    let locator = locatorStr == nil ? nil : try! Locator.init(jsonString: locatorStr!)
    print(TAG, "publication = \(publication)")

    channel = ReadiumReaderChannel(
      name: "\(readiumReaderViewType):\(viewId)", binaryMessenger: registrar.messenger())
    textLocatorStreamHandler = EventStreamHandler(withName: "pdf-text-locator", messenger: registrar.messenger())
    readerStatusStreamHandler = EventStreamHandler(withName: "pdf-reader-status", messenger: registrar.messenger())
    errorStreamHandler = EventStreamHandler(withName: "pdf-error", messenger: registrar.messenger())

    readerStatusStreamHandler?.sendEvent(PdfReaderStatusLoading)

    print(TAG, "Publication: (identifier=\(String(describing: publication.metadata.identifier)),title=\(String(describing: publication.metadata.title)))")

    // Configure PDF navigator
    var config = PDFNavigatorViewController.Configuration()
    config.preferences = pdfPreferences

    pdfViewController = try! PDFNavigatorViewController(
      publication: publication,
      initialLocation: locator,
      config: config,
      httpServer: sharedReadium.httpServer!
    )

    _view = UIView()
    super.init()

    channel.setMethodCallHandler(onMethodCall)
    pdfViewController.delegate = self

    let child: UIView = pdfViewController.view
    let view = _view
    view.addSubview(pdfViewController.view)

    child.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate(
      [
        child.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        child.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        child.topAnchor.constraint(equalTo: view.topAnchor),
        child.bottomAnchor.constraint(equalTo: view.bottomAnchor)
      ]
    )

    setCurrentPdfReaderView(self)
    publicationIdentifier = publication.metadata.identifier

    print(TAG, "::init success")
  }

  // MARK: - VisualNavigatorDelegate

  func navigatorContentInset(_ navigator: VisualNavigator) -> UIEdgeInsets? {
    // All margin & safe-area is handled on the Flutter side.
    return .init(top: 0, left: 0, bottom: 0, right: 0)
  }

  // MARK: - NavigatorDelegate

  func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
    print(TAG, "presentError: \(error)")
  }

  func navigator(_ navigator: Navigator, didFailToLoadResourceAt href: ReadiumShared.RelativeURL, withError error: ReadiumShared.ReadError) {
    print(TAG, "didFailToLoadResourceAt: \(href). err: \(error)")

    self.readerStatusStreamHandler?.sendEvent(PdfReaderStatusError)

    let flureadiumError = FlureadiumError(message: error.localizedDescription, code: "DidFailToLoadResource", data: href.string)
    self.errorStreamHandler?.sendEvent(flureadiumError)
  }

  func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
    print(TAG, "onPageChanged: \(locator)")
    if (!hasSentReady) {
      self.readerStatusStreamHandler?.sendEvent(PdfReaderStatusReady)
      hasSentReady = true
    }
    emitOnPageChanged(locator: locator)
  }

  func navigator(_ navigator: Navigator, presentExternalURL url: URL) {
    guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
      print(TAG, "skipped non-http external URL: \(url)")
      return
    }
    emitOnExternalLinkActivated(url: url)
  }

  // MARK: - PDFNavigatorDelegate

  func navigator(_ navigator: PDFNavigatorViewController, setupPDFView view: PDFDocumentView) {
    print(TAG, "setupPDFView called - disableDoubleTapZoom: \(disableDoubleTapZoom), disableTextSelection: \(disableTextSelection), disableDragGestures: \(disableDragGestures)")

    if disableDoubleTapZoom {
      print(TAG, "Calling disableDoubleTapZoomGesture...")
      disableDoubleTapZoomGesture(in: view)
    }

    if disableTextSelection {
      print(TAG, "Calling disableTextSelectionGesture...")
      disableTextSelectionGesture(in: view)
    }

    if disableDragGestures {
      print(TAG, "Calling disableDragGesturesRecognizer...")
      disableDragGesturesRecognizer(in: view)
    }

    print(TAG, "setupPDFView completed")
  }

  // MARK: - Public Methods

  func getCurrentLocation() -> Locator? {
    return self.pdfViewController.currentLocation
  }

  func goToLocator(locator: Locator, animated: Bool) async -> Void {
    let _ = await pdfViewController.go(to: locator, options: NavigatorGoOptions(animated: animated))
  }

  // MARK: - Private Methods

  private func setUserPreferences(preferences: PDFPreferences) {
    self.pdfViewController.submitPreferences(preferences)
  }

  private func disableDoubleTapZoomGesture(in view: UIView) {
    // Disable double-tap gesture recognizers on this view
    for gestureRecognizer in view.gestureRecognizers ?? [] {
      if let tapGesture = gestureRecognizer as? UITapGestureRecognizer,
         tapGesture.numberOfTapsRequired == 2 {
        tapGesture.isEnabled = false
      }
    }
    // Recursively disable on all subviews
    for subview in view.subviews {
      disableDoubleTapZoomGesture(in: subview)
    }
  }

  private func disableTextSelectionGesture(in view: UIView) {
    // Log all gesture recognizers on this view for debugging
    if let gestures = view.gestureRecognizers, !gestures.isEmpty {
      print(TAG, "disableTextSelectionGesture: Found \(gestures.count) gesture(s) on \(type(of: view))")
      for (index, gesture) in gestures.enumerated() {
        let gestureType = type(of: gesture)
        if let tapGesture = gesture as? UITapGestureRecognizer {
          print(TAG, "  [\(index)] \(gestureType) - taps: \(tapGesture.numberOfTapsRequired), touches: \(tapGesture.numberOfTouchesRequired), enabled: \(gesture.isEnabled)")
        } else if let longPress = gesture as? UILongPressGestureRecognizer {
          print(TAG, "  [\(index)] \(gestureType) - minDuration: \(longPress.minimumPressDuration), enabled: \(gesture.isEnabled)")
        } else {
          print(TAG, "  [\(index)] \(gestureType) - enabled: \(gesture.isEnabled)")
        }
      }
    }

    // Disable gesture recognizers that might trigger text selection
    var disabledCount = 0
    for gestureRecognizer in view.gestureRecognizers ?? [] {
      // Disable long-press (primary text selection trigger)
      if gestureRecognizer is UILongPressGestureRecognizer {
        print(TAG, "  → Disabling UILongPressGestureRecognizer")
        gestureRecognizer.isEnabled = false
        disabledCount += 1
      }
      // Disable single-tap recognizers that might be for text selection menu
      // Note: Double-tap is already handled by disableDoubleTapZoomGesture
      else if let tapGesture = gestureRecognizer as? UITapGestureRecognizer {
        if tapGesture.numberOfTapsRequired == 1 && tapGesture.numberOfTouchesRequired == 1 {
          print(TAG, "  → Disabling single-tap UITapGestureRecognizer")
          gestureRecognizer.isEnabled = false
          disabledCount += 1
        }
      }
    }

    if disabledCount > 0 {
      print(TAG, "disableTextSelectionGesture: Disabled \(disabledCount) gesture(s) on \(type(of: view))")
    }

    // Remove UITextInteraction objects (iOS 13+)
    if #available(iOS 13.0, *) {
      let textInteractions = view.interactions.filter { $0 is UITextInteraction }
      if !textInteractions.isEmpty {
        print(TAG, "  Found \(textInteractions.count) UITextInteraction(s) on \(type(of: view))")
        for interaction in textInteractions {
          print(TAG, "  → Removing UITextInteraction")
          view.removeInteraction(interaction)
        }
      }
    }

    // Recursively disable on all subviews
    for subview in view.subviews {
      disableTextSelectionGesture(in: subview)
    }
  }

  private func disableDragGesturesRecognizer(in view: UIView) {
    // Disable drag gesture recognizers that can trigger text selection/drag-and-drop
    var disabledCount = 0
    for gestureRecognizer in view.gestureRecognizers ?? [] {
      let gestureTypeName = String(describing: type(of: gestureRecognizer))

      // Disable drag gesture recognizers (for text selection/drag-and-drop)
      if gestureTypeName.contains("Drag") {
        print(TAG, "  → Disabling drag gesture: \(gestureTypeName)")
        gestureRecognizer.isEnabled = false
        disabledCount += 1
      }
    }

    if disabledCount > 0 {
      print(TAG, "disableDragGesturesRecognizer: Disabled \(disabledCount) gesture(s) on \(type(of: view))")
    }

    // Recursively disable on all subviews
    for subview in view.subviews {
      disableDragGesturesRecognizer(in: subview)
    }
  }

  private func emitOnPageChanged(locator: Locator) -> Void {
    print(TAG, "emitOnPageChanged:locator=\(String(describing: locator))")

    Task.detached(priority: .high) {
      await MainActor.run() {
        self.channel.onPageChanged(locator: locator)
        guard let textLocatorStreamHandler = self.textLocatorStreamHandler else {
          print(TAG, "emitOnPageChanged: textLocatorStreamHandler is nil!")
          return
        }
        textLocatorStreamHandler.sendEvent(locator.jsonString)
      }
    }
  }

  private func emitOnExternalLinkActivated(url: URL) {
    print(TAG, "emitOnExternalLinkActivated: \(url)")
    Task.detached(priority: .high) {
      await MainActor.run() {
        self.channel.onExternalLinkActivated(url: url)
      }
    }
  }

  // MARK: - Method Channel Handler

  func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "go":
      let args = call.arguments as! [Any?]
      print(TAG, "onMethodCall[go] locator = \(args[0] as! String)")
      let locator = try! Locator(jsonString: args[0] as! String)!
      let animated = args[1] as! Bool

      Task { @MainActor in
        await self.goToLocator(locator: locator, animated: animated)
        result(true)
      }
    case "goLeft":
      let animated = call.arguments as! Bool
      let pdfViewController = self.pdfViewController

      Task { @MainActor in
        let success = await pdfViewController.goLeft(options: NavigatorGoOptions(animated: animated))
        result(success)
      }
    case "goRight":
      let animated = call.arguments as! Bool
      let pdfViewController = self.pdfViewController

      Task { @MainActor in
        let success = await pdfViewController.goRight(options: NavigatorGoOptions(animated: animated))
        result(success)
      }
    case "getCurrentLocator":
      print(TAG, "onMethodCall[getCurrentLocator]")
      Task.detached(priority: .high) {
        let locator = await self.pdfViewController.currentLocation
        await MainActor.run {
          result(locator?.jsonString)
        }
      }
    case "setPreferences":
      let args = call.arguments as! [String: Any]
      print(TAG, "onMethodCall[setPreferences] args = \(args)")
      let preferences = PDFPreferences(fromMap: args)
      setUserPreferences(preferences: preferences)
      result(nil)
    case "dispose":
      print(TAG, "Disposing pdfViewController")
      pdfViewController.view.removeFromSuperview()
      pdfViewController.delegate = nil
      self.readerStatusStreamHandler?.sendEvent(PdfReaderStatusClosed)
      result(nil)
    default:
      print(TAG, "Unhandled call \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }
}
