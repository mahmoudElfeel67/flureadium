import ReadiumNavigator
import ReadiumAdapterGCDWebServer
import ReadiumShared
import Flutter
import UIKit
import WebKit

private let TAG = "ReadiumReaderView"
private let ReadiumReaderStatusReady = "ready"
private let ReadiumReaderStatusLoading = "loading"
private let ReadiumReaderStatusClosed = "closed"
private let ReadiumReaderStatusError = "error"

let readiumReaderViewType = "dev.mulev.flureadium/ReadiumReaderWidget"

class ReadiumBugLogger: ReadiumShared.WarningLogger {
  func log(_ warning: Warning) {
    print(TAG, "Error in Readium: \(warning)")
  }
}

private let readiumBugLogger = ReadiumBugLogger()
private var userScripts: [WKUserScript] = []

/// Debug view to log all touch events reaching the native layer
/// Also provides fallback edge tap handling when Readium's gesture recognizers fail
class TouchDebugView: UIView {
    private let logTag = "ReadiumReaderView [TOUCH]"

    /// Callback for left edge tap
    var onLeftEdgeTap: (() -> Void)?
    /// Callback for right edge tap
    var onRightEdgeTap: (() -> Void)?
    /// Edge threshold as percentage of width (default 30%)
    var edgeThresholdPercent: CGFloat = 0.3

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }

    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let edgeSize = bounds.width * edgeThresholdPercent

        print(logTag, "[FALLBACK TAP] at \(location), edgeSize=\(edgeSize), bounds=\(bounds)")

        if location.x < edgeSize {
            print(logTag, "[FALLBACK TAP] LEFT edge detected")
            onLeftEdgeTap?()
        } else if location.x > bounds.width - edgeSize {
            print(logTag, "[FALLBACK TAP] RIGHT edge detected")
            onRightEdgeTap?()
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)

        // Build type chain from hit view up to self
        var typeChain: [String] = []
        var current: UIView? = result
        while let v = current, v != self {
            typeChain.append("\(type(of: v))(\(Int(v.frame.width))x\(Int(v.frame.height)))")
            current = v.superview
        }

        let edgeSize = bounds.width * edgeThresholdPercent
        let isLeftEdge = point.x < edgeSize
        let isRightEdge = point.x > bounds.width - edgeSize
        let zone = isLeftEdge ? "LEFT_EDGE" : (isRightEdge ? "RIGHT_EDGE" : "CENTER")

        print(logTag, "[PIPELINE] hitTest at \(point) zone=\(zone)")
        print(logTag, "[PIPELINE]   chain: \(typeChain.joined(separator: " → "))")
        print(logTag, "[PIPELINE]   interaction: \(result?.isUserInteractionEnabled ?? false)")

        // Debug #4: Log coordinate space transforms when result is oversized
        if let result = result, result.frame.width > bounds.width {
            // Find WKScrollView and WKContentView in the chain
            var v: UIView? = result
            var wkScrollView: UIScrollView?
            var wkContentView: UIView?
            while let view = v {
                let className = String(describing: type(of: view))
                if className == "WKScrollView", let sv = view as? UIScrollView {
                    wkScrollView = sv
                }
                if className == "WKContentView" {
                    wkContentView = view
                }
                v = view.superview
            }

            let pointInResult = self.convert(point, to: result)
            print(logTag, "[COORDS] point in TouchDebugView: \(point)")
            print(logTag, "[COORDS] point in hitResult(\(type(of: result))): \(pointInResult)")
            print(logTag, "[COORDS] hitResult.frame.origin: \(result.frame.origin)")

            if let cv = wkContentView {
                let pointInCV = self.convert(point, to: cv)
                print(logTag, "[COORDS] point in WKContentView: \(pointInCV)")
                print(logTag, "[COORDS] WKContentView.frame: \(cv.frame)")
            }

            if let sv = wkScrollView {
                let pointInSV = self.convert(point, to: sv)
                print(logTag, "[COORDS] point in WKScrollView: \(pointInSV)")
                print(logTag, "[COORDS] WKScrollView.contentOffset: \(sv.contentOffset)")
                print(logTag, "[COORDS] WKScrollView.contentSize: \(sv.contentSize)")
                print(logTag, "[COORDS] WKScrollView.frame: \(sv.frame)")
            }
        }

        // If we have edge tap callbacks and the touch is in an edge zone,
        // return self so our gesture recognizer receives the tap
        if (isLeftEdge && onLeftEdgeTap != nil) || (isRightEdge && onRightEdgeTap != nil) {
            print(logTag, "[PIPELINE]   → returning SELF (edge intercept)")
            return self
        }

        print(logTag, "[PIPELINE]   → returning child: \(type(of: result as Any))")
        return result
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            print(logTag, "[PIPELINE] touchesBegan at \(loc) view=\(type(of: touch.view as Any))")

            // Debug #4: Log touch coordinates in different coordinate spaces
            if let touchView = touch.view, touchView.frame.width > bounds.width {
                let locInTouchView = touch.location(in: touchView)
                let locInWindow = touch.location(in: nil)
                print(logTag, "[TOUCH-COORDS] in touchView(\(type(of: touchView))): \(locInTouchView)")
                print(logTag, "[TOUCH-COORDS] in window: \(locInWindow)")

                // Find WKScrollView
                var v: UIView? = touchView
                while let view = v {
                    let className = String(describing: type(of: view))
                    if className == "WKScrollView", let sv = view as? UIScrollView {
                        let locInSV = touch.location(in: sv)
                        print(logTag, "[TOUCH-COORDS] in WKScrollView: \(locInSV)")
                        print(logTag, "[TOUCH-COORDS] WKScrollView.contentOffset: \(sv.contentOffset)")
                        break
                    }
                    v = view.superview
                }
            }
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            print(logTag, "[PIPELINE] touchesEnded at \(loc)")
        }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            print(logTag, "[PIPELINE] touchesCancelled at \(loc)")
        }
        super.touchesCancelled(touches, with: event)
    }
}

/// Debug message handler for JS→Xcode console bridge
class DebugScriptMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("ReadiumReaderView [JS]", message.body)
    }
}

/// Debug observer that tracks UIGestureRecognizer state changes on WKContentView
/// to understand why the click gesture recognizer doesn't fire after goLeft/goRight.
class GestureRecognizerObserver: NSObject {
    private let logTag = "ReadiumReaderView [GR-DEBUG]"
    private var observations: [NSKeyValueObservation] = []

    /// Find WKContentView(s) in the view hierarchy and observe their gesture recognizers.
    /// viewportWidth: only observe WKContentViews wider than this (to skip normal-sized ones).
    /// verbose: if true, enumerate all gesture recognizers (first call only).
    func observe(rootView: UIView, viewportWidth: CGFloat = 0, verbose: Bool = false) {
        stopObserving()
        let contentViews = findWKContentViews(in: rootView)
        print(logTag, "Found \(contentViews.count) WKContentView(s)")

        for contentView in contentViews {
            let frame = contentView.frame
            let gestures = contentView.gestureRecognizers ?? []

            // Skip WKContentViews that are viewport-sized or zero-sized (not the problem)
            if viewportWidth > 0 && frame.width <= viewportWidth {
                print(logTag, "  Skipping WKContentView(\(Int(frame.width))x\(Int(frame.height))) — not oversized")
                continue
            }

            print(logTag, "Observing WKContentView frame=\(Int(frame.width))x\(Int(frame.height)), \(gestures.count) gesture recognizers")

            for (i, gr) in gestures.enumerated() {
                if verbose {
                    let desc = describeGestureRecognizer(gr)
                    print(logTag, "  [\(i)] \(type(of: gr)) state=\(stateName(gr.state)) enabled=\(gr.isEnabled) \(desc)")
                }

                // Observe state changes — read recognizer.state directly (KVO change dict is unreliable)
                let observation = gr.observe(\.state, options: []) { [weak self] recognizer, _ in
                    guard let self = self else { return }
                    let currentState = self.stateName(recognizer.state)
                    let cvFrame = contentView.frame
                    print(self.logTag, "  STATE CHANGE on WKContentView(\(Int(cvFrame.width))x\(Int(cvFrame.height))): \(type(of: recognizer)) → \(currentState)")
                }
                observations.append(observation)
            }
        }
    }

    func stopObserving() {
        observations.removeAll()
    }

    private func findWKContentViews(in view: UIView) -> [UIView] {
        var results: [UIView] = []
        let className = String(describing: type(of: view))
        if className == "WKContentView" {
            results.append(view)
        }
        for subview in view.subviews {
            results.append(contentsOf: findWKContentViews(in: subview))
        }
        return results
    }

    private func describeGestureRecognizer(_ gr: UIGestureRecognizer) -> String {
        var parts: [String] = []
        if let tap = gr as? UITapGestureRecognizer {
            parts.append("taps=\(tap.numberOfTapsRequired) touches=\(tap.numberOfTouchesRequired)")
        }
        if let longPress = gr as? UILongPressGestureRecognizer {
            parts.append("minDuration=\(longPress.minimumPressDuration)")
        }
        if gr.cancelsTouchesInView { parts.append("cancels") }
        if gr.delaysTouchesBegan { parts.append("delaysBegin") }
        if gr.delaysTouchesEnded { parts.append("delaysEnd") }
        return parts.joined(separator: " ")
    }

    private func stateName(_ state: UIGestureRecognizer.State) -> String {
        switch state {
        case .possible: return "possible"
        case .began: return "began"
        case .changed: return "changed"
        case .ended: return "ended/recognized"
        case .cancelled: return "cancelled"
        case .failed: return "failed"
        @unknown default: return "unknown(\(state.rawValue))"
        }
    }

    deinit {
        stopObserving()
    }
}

class ReadiumReaderView: NSObject, FlutterPlatformView, EPUBNavigatorDelegate, VisualNavigatorDelegate {

  private let channel: ReadiumReaderChannel
  private var errorStreamHandler: EventStreamHandler?
  private var readerStatusStreamHandler: EventStreamHandler?
  private var textLocatorStreamHandler: EventStreamHandler?
  private let _view: UIView
  private let readiumViewController: EPUBNavigatorViewController
  private var isVerticalScroll = false
  private var hasSentReady = false

  // Retain the navigation adapter to prevent ARC deallocation
  private var directionalNavigationAdapter: DirectionalNavigationAdapter?

  // Debug: observe gesture recognizer state changes on WKContentView
  private let gestureObserver = GestureRecognizerObserver()

  var publicationIdentifier: String?

  func view() -> UIView {
    print(TAG, "::getView")
    return _view
  }

  deinit {
    print(TAG, "::dispose")
    readiumViewController.view.removeFromSuperview()
    readiumViewController.delegate = nil
    textLocatorStreamHandler?.dispose()
    textLocatorStreamHandler = nil
    readerStatusStreamHandler?.dispose()
    readerStatusStreamHandler = nil
    errorStreamHandler?.dispose()
    errorStreamHandler = nil
    channel.setMethodCallHandler(nil)
    setCurrentReadiumReaderView(nil)
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

    let preferencesMap = creationParams["preferences"] as? Dictionary<String, String>?
    let defaultPreferences = preferencesMap == nil ? nil : EPUBPreferences.init(fromMap: preferencesMap!!)

    let locatorStr = creationParams["initialLocator"] as? String
    let locator = locatorStr == nil ? nil : try! Locator.init(jsonString: locatorStr!)
    print(TAG, "publication = \(publication)")

    channel = ReadiumReaderChannel(
      name: "\(readiumReaderViewType):\(viewId)", binaryMessenger: registrar.messenger())
    textLocatorStreamHandler = EventStreamHandler(withName: "text-locator", messenger: registrar.messenger())
    readerStatusStreamHandler = EventStreamHandler(withName: "reader-status", messenger: registrar.messenger())
    errorStreamHandler = EventStreamHandler(withName: "error", messenger: registrar.messenger())

    readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusLoading)

    print(TAG, "Publication: (identifier=\(String(describing: publication.metadata.identifier)),title=\(String(describing: publication.metadata.title)))")
    print(TAG, "Added publication at \(String(describing: publication.baseURL))")

    // Remove undocumented Readium default 20dp or 44dp top/bottom padding.
    // See EPUBNavigatorViewController.swift in r2-navigator-swift.
    var config = EPUBNavigatorViewController.Configuration()
    config.contentInset = [
      .compact: (top: 0, bottom: 0),
      .regular: (top: 0, bottom: 0),
    ]
    // TODO: Make this config configurable from Flutter
    // Might want it to be higher for a local publication than remote.
    config.preloadPreviousPositionCount = 2
    config.preloadNextPositionCount = 4
    config.debugState = true
    config.decorationTemplates = HTMLDecorationTemplate.defaultTemplates(alpha: 1.0, experimentalPositioning: true)
    config.editingActions = [.lookup, .translate, EditingAction(title: "Custom Action", action: #selector(onCustomEditingAction))]

    if (defaultPreferences != nil) {
      config.preferences = defaultPreferences!
    }

    readiumViewController = try! EPUBNavigatorViewController(
      publication: publication,
      initialLocation: locator,
      config: config,
      httpServer: sharedReadium.httpServer!
    )

    if userScripts.isEmpty {
      initUserScripts(registrar: registrar)
    }

    _view = TouchDebugView()
    super.init()

    channel.setMethodCallHandler(onMethodCall)
    readiumViewController.delegate = self

    // Setup fallback edge tap handlers
    if let touchDebugView = _view as? TouchDebugView {
        touchDebugView.onLeftEdgeTap = { [weak self] in
            guard let self = self else { return }
            print(TAG, "[FALLBACK] Triggering goLeft via fallback tap handler")
            Task { @MainActor in
                let _ = await self.readiumViewController.goLeft(options: NavigatorGoOptions(animated: true))
            }
        }
        touchDebugView.onRightEdgeTap = { [weak self] in
            guard let self = self else { return }
            print(TAG, "[FALLBACK] Triggering goRight via fallback tap handler")
            Task { @MainActor in
                let _ = await self.readiumViewController.goRight(options: NavigatorGoOptions(animated: true))
            }
        }
    }

    let child: UIView = readiumViewController.view
    let view = _view
    view.addSubview(readiumViewController.view)

    child.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate(
      [
        child.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        child.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        child.topAnchor.constraint(equalTo: view.topAnchor),
        child.bottomAnchor.constraint(equalTo: view.bottomAnchor)
      ]
    )

    setCurrentReadiumReaderView(self)
    publicationIdentifier = publication.metadata.identifier

    /// This adapter will automatically turn pages when the user taps the
    /// screen edges or press arrow keys.
    ///
    /// Bind it to the navigator before adding your own observers to prevent
    /// triggering your actions when turning pages.
    /// NOTE: Store in property to prevent ARC deallocation
    directionalNavigationAdapter = DirectionalNavigationAdapter(
        pointerPolicy: .init(types: [.mouse, .touch])
    )
    directionalNavigationAdapter?.bind(to: readiumViewController)

    print(TAG, "::init success")
  }

  @objc public func onCustomEditingAction() {
    print(TAG, "EditingAction::NOTA")
    // NOTE: This method will not actually be hit. It will try to find an "onEditingActionNota" function in the Responder chain!
    // see https://github.com/readium/swift-toolkit/issues/466

    // This methos should actually be implemented in the Flutter AppDelegate!
    // TODO: Find a way to trigger the code below, from the AppDelegate.
    if let selection = readiumViewController.currentSelection {
      let selectionLocator = selection.locator
      currentReaderView?.readiumViewController.apply(decorations: [Decoration(id: "highlight", locator: selectionLocator, style: .highlight(), userInfo: [:])], in: "user-highlight")
      readiumViewController.clearSelection()
    }
  }

  // override EPUBNavigatorDelegate::navigator:setupUserScripts
  func navigator(_ navigator: EPUBNavigatorViewController, setupUserScripts userContentController: WKUserContentController) {
    print(TAG, "setupUserScripts: adding \(userScripts.count) scripts")
    for script in userScripts {
      userContentController.addUserScript(script)
    }
    // Register debug message handler for JS→Xcode logging bridge
    userContentController.add(DebugScriptMessageHandler(), name: "debugLog")
  }

  // override EPUBNavigatorDelegate::middleTapHandler
  func middleTapHandler() {
  }

  func navigatorContentInset(_ navigator: VisualNavigator) -> UIEdgeInsets? {
    // All margin & safe-area is handled on the Flutter side.
    return .init(top: 0, left: 0, bottom: 0, right: 0)
  }

  // override EPUBNavigatorDelegate::navigator:presentError
  func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
    print(TAG, "presentError: \(error)")
  }

  // override EPUBNavigatorDelegate::navigator:didFailToLoadResourceAt
  func navigator(_ navigator: Navigator, didFailToLoadResourceAt href: ReadiumShared.RelativeURL, withError error: ReadiumShared.ReadError) {
    print(TAG, "didFailToLoadResourceAt: \(href). err: \(error)")

    // TODO: Should we send resource-load error like this?
    self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusError)

    let error = FlureadiumError(message: error.localizedDescription, code: "DidFailToLoadResource", data: href.string)
    self.errorStreamHandler?.sendEvent(error)
  }

  // override NavigatorDelegate::navigator:locationDidChange
  func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
    print(TAG, "onPageChanged: \(locator)")
    if (!hasSentReady) {
      self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusReady)
      hasSentReady = true
      // Start observing gesture recognizers on initial load (verbose on first call for reference)
      self.gestureObserver.observe(rootView: self._view, viewportWidth: self._view.bounds.width, verbose: true)
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

  func applyDecorations(_ decorations: [Decoration], forGroup groupIdentifier: String) {
    print(TAG, "onMethodApplyDecorations: \(decorations) identifier: \(groupIdentifier)")
    self.readiumViewController.apply(decorations: decorations, in: groupIdentifier)
  }

  func getFirstVisibleLocator() async -> Locator? {
    return await self.readiumViewController.firstVisibleElementLocator()
  }

  func getCurrentLocation() -> Locator? {
    return self.readiumViewController.currentLocation
  }

  func getCurrentSelection() -> Locator? {
    return self.readiumViewController.currentSelection?.locator
  }

  private func evaluateJavascript(_ code: String) async -> Result<Any, Error> {
    return await self.readiumViewController.evaluateJavaScript(code)
  }

  private func evaluateJSReturnResult(_ code: String, result: @escaping FlutterResult) {
    Task.detached(priority: .high) {
      do {
        let data = try await self.evaluateJavascript(code).get()
        print(TAG, "evaluateJSReturnResult result: \(data)")
        await MainActor.run() {
          return result(data)
        }
      } catch (let err) {
        print(TAG, "evaluateJSReturnResult error: \(err)")
        await MainActor.run() {
          return result(nil)
        }
      }
    }
  }

  private func setUserPreferences(preferences: EPUBPreferences) {
    isVerticalScroll = preferences.scroll ?? false
    self.readiumViewController.submitPreferences(preferences)
  }

  private func emitOnPageChanged(locator: Locator) -> Void {
    let json = locator.jsonString ?? "null"

    print(TAG, "emitOnPageChanged:locator=\(String(describing: locator))")

    Task.detached(priority: .high) { [isVerticalScroll] in
      guard let locatorWithFragments = await self.getLocatorFragments(json, isVerticalScroll) else {
        print(TAG, "emitOnPageChanged failed!")
        return
      }
      await MainActor.run() {
        self.channel.onPageChanged(locator: locatorWithFragments)
        guard let textLocatorStreamHandler = self.textLocatorStreamHandler else {
          print(TAG, "emitOnPageChanged: textLocatorStreamHandler is nil!")
          return
        }

        textLocatorStreamHandler.sendEvent(locatorWithFragments.jsonString)
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

  internal func getLocatorFragments(_ locatorJson: String, _ isVerticalScroll: Bool) async -> Locator? {
    switch await self.evaluateJavascript("window.epubPage.getLocatorFragments(\(locatorJson), \(isVerticalScroll));") {
      case .success(let jresult):
        let locatorWithFragments = try! Locator(json: jresult as? Dictionary<String, Any?>, warnings: readiumBugLogger)!
        return locatorWithFragments
      case .failure(let err):
        print(TAG, "getLocatorFragments failed! \(err)")
        return nil
      }
  }

  private func scrollTo(locations: Locator.Locations, toStart: Bool) async -> Void {
    let json = locations.jsonString ?? "null"
    print(TAG, "scrollTo: Go to locations \(json), toStart: \(toStart)")

    let _ = await evaluateJavascript("window.epubPage.scrollToLocations(\(json),\(isVerticalScroll),\(toStart));")
  }

  func goToLocator(locator: Locator, animated: Bool) async -> Void {
    let locations = locator.locations
    let shouldScroll = canScroll(locations: locations)
    let shouldGo = readiumViewController.currentLocation?.href != locator.href
    let readiumViewController = self.readiumViewController

    if shouldGo {
      print(TAG, "goToLocator: Go to \(locator.href)")
      let goToSuccees = await readiumViewController.go(to: locator, options: NavigatorGoOptions(animated: animated))
      if (goToSuccees && shouldScroll) {
        await self.scrollTo(locations: locations, toStart: false)
        self.emitOnPageChanged()
      }
    } else {
      print(TAG, "goToLocator: Already there, Scroll to \(locator.href)")
      if (shouldScroll) {
        await self.scrollTo(locations: locations, toStart: false)
        self.emitOnPageChanged()
      }
    }
  }

  func justGoToLocator(_ locator: Locator, animated: Bool) async -> Bool {
    return await readiumViewController.go(to: locator, options: NavigatorGoOptions(animated: animated))
  }

  private func setLocation(locator: Locator, isAudioBookWithText: Bool) async -> Result<Any, Error> {
    let json = locator.jsonString ?? "null"

    return await evaluateJavascript("window.epubPage.setLocation(\(json), \(isAudioBookWithText));")
  }

  private func emitOnPageChanged() {
    guard let locator = readiumViewController.currentLocation else {
      print(TAG, "emitOnPageChanged: currentLocation = nil!")
      return
    }
    print(TAG, "emitOnPageChanged: Calling navigator:locationDidChange.")
    navigator(readiumViewController, locationDidChange: locator)
  }

  func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "go":
      let args = call.arguments as! [Any?]
      print(TAG, "onMethodCall[go] locator = \(args[0] as! String)")
      let locator = try! Locator(jsonString: args[0] as! String, warnings: readiumBugLogger)!
      let animated = args[1] as! Bool
      let isAudioBookWithText = args[2] as? Bool ?? false

      Task { @MainActor in
        await self.goToLocator(locator: locator, animated: animated)
        let _ = await self.setLocation(locator: locator, isAudioBookWithText: isAudioBookWithText)
        result(true)
      }
      break
    case "goLeft":
      let animated = call.arguments as! Bool
      let readiumViewController = self.readiumViewController

      Task { @MainActor in
        let success = await readiumViewController.goLeft(options: NavigatorGoOptions(animated: animated))
        print(TAG, "[PIPELINE] goLeft completed, success: \(success)")
        self.logViewHierarchy(self._view, indent: 0)
        self.gestureObserver.observe(rootView: self._view, viewportWidth: self._view.bounds.width)
        result(success)
      }
      break
    case "goRight":
      let animated = call.arguments as! Bool
      let readiumViewController = self.readiumViewController

      Task { @MainActor in
        let success = await readiumViewController.goRight(options: NavigatorGoOptions(animated: animated))
        print(TAG, "[PIPELINE] goRight completed, success: \(success)")
        self.logViewHierarchy(self._view, indent: 0)
        self.gestureObserver.observe(rootView: self._view, viewportWidth: self._view.bounds.width)
        result(success)
      }
      break
    case "setLocation":
      let args = call.arguments as! [Any]
      print(TAG, "onMethodCall[setLocation] locator = \(args[0] as! String)")
      let locator = try! Locator(jsonString: args[0] as! String, warnings: readiumBugLogger)!
      let isAudioBookWithText = args[1] as? Bool ?? false
      Task.detached(priority: .high) {
        let _ = await self.setLocation(locator: locator, isAudioBookWithText: isAudioBookWithText)
        return await MainActor.run() {
          result(true)
        }
      }
      break
    case "getLocatorFragments":
      let args = call.arguments as? String ?? "null"
      Task.detached(priority: .high) {
        do {
          let data = try await self.evaluateJavascript("window.epubPage.getLocatorFragments(\(args), true);").get()
          await MainActor.run() {
            return result(data)
          }
        } catch (let err) {
          print(TAG, "getLocatorFragments error \(err)")
          await MainActor.run() {
            return result(false)
          }
        }
      }
      break
    case "getCurrentLocator":
      let args = call.arguments as? String ?? "null"
      print(TAG, "onMethodCall[currentLocator] args = \(args)")
      Task.detached(priority: .high) { [isVerticalScroll] in
        let json = await self.readiumViewController.currentLocation?.jsonString ?? nil
        if (json == nil) {
          await MainActor.run() {
            return result(nil)
          }
        }
        let data = await self.getLocatorFragments(json!, isVerticalScroll)
        await MainActor.run() {
          return result(data?.jsonString)
        }
      }
      break
    case "isLocatorVisible":
      let args = call.arguments as! String
      print(TAG, "onMethodCall[isLocatorVisible] locator = \(args)")
      let locator = try! Locator(jsonString: args, warnings: readiumBugLogger)!
      if locator.href != self.readiumViewController.currentLocation?.href {
        result(false)
        return
      }
      evaluateJSReturnResult("window.epubPage.isLocatorVisible(\(args));", result: result)
      break
    case "isReaderReady":
      self.evaluateJSReturnResult("""
                (function() {
                    if (typeof window.epubPage !== 'undefined' && typeof window.epubPage.isReaderReady === 'function') {
                        return window.epubPage.isReaderReady();
                    } else {
                        return false;
                    }
                })();
            """, result: result)
      break
    case "setPreferences":
      let args = call.arguments as! [String: String]
      print(TAG, "onMethodCall[setPreferences] args = \(args)")
      let preferences = EPUBPreferences.init(fromMap: args)
      setUserPreferences(preferences: preferences)
      break
    case "applyDecorations":
      let args = call.arguments as! [Any?]
      let identifier = args[0] as! String
      let decorationsStr = args[1] as! [String]

      guard let decorations = try? decorationsStr.map({ try Decoration(fromJson: $0) }) else {
        return result(FlutterError.init(
          code: "JSON mapping error",
          message: "Could not map decorations from JSON: \(decorationsStr)",
          details: nil))
      }

      print(TAG, "onMethodCall[setPreferences] args = \(args)")
      applyDecorations(decorations, forGroup: identifier)
      break
    case "dispose":
      print(TAG, "Disposing readiumViewController")
      readiumViewController.view.removeFromSuperview()
      readiumViewController.delegate = nil
      self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusClosed)
      result(nil)
      break
    default:
      print(TAG, "Unhandled call \(call.method)")
      result(FlutterMethodNotImplemented)
      break
    }
  }

  private func logViewHierarchy(_ view: UIView, indent: Int) {
    let prefix = String(repeating: "  ", count: indent)
    let gestures = view.gestureRecognizers?.count ?? 0
    print(TAG, "[HIERARCHY] \(prefix)\(type(of: view)) frame=\(Int(view.frame.width))x\(Int(view.frame.height)) interaction=\(view.isUserInteractionEnabled) gestures=\(gestures)")
    for subview in view.subviews {
      logViewHierarchy(subview, indent: indent + 1)
    }
  }
}

func initUserScripts(registrar: FlutterPluginRegistrar) {
  let comicJsKey = registrar.lookupKey(forAsset: "assets/helpers/comics.js", fromPackage: "flureadium")
  let comicCssKey = registrar.lookupKey(forAsset: "assets/helpers/comics.css", fromPackage: "flureadium")
  let epubJsKey = registrar.lookupKey(forAsset: "assets/helpers/epub.js", fromPackage: "flureadium")
  let epubCssKey = registrar.lookupKey(forAsset: "assets/helpers/epub.css", fromPackage: "flureadium")
  let jsScripts = [comicJsKey, epubJsKey].map { sourceFile -> String in
    let path = Bundle.main.path(forResource: sourceFile, ofType: nil)!
    let data = FileManager().contents(atPath: path)!
    return String(data: data, encoding: .utf8)!
  }
  let addCssScripts = [comicCssKey, epubCssKey].map { sourceFile -> String in
    let path = Bundle.main.path(forResource: sourceFile, ofType: nil)!
    let data = FileManager().contents(atPath: path)!.base64EncodedString()
    return """
      (function() {
      var parent = document.getElementsByTagName('head').item(0);
      var style = document.createElement('style');
      style.type = 'text/css';
      style.innerHTML = window.atob('\(data)');
      parent.appendChild(style)})();
    """
  }
  /// Add JS scripts right away, before loading the rest of the document.
  for jsScript in jsScripts {
    userScripts.append(WKUserScript(source: jsScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
  }
  /// Add css injection scripts after primary document finished loading.
  for addCssScript in addCssScripts {
    userScripts.append(WKUserScript(source: addCssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
  }
  /// Add simple script used by our JS to detect OS
  userScripts.append(WKUserScript(source: "const isAndroid=false,isIos=true;", injectionTime: .atDocumentStart, forMainFrameOnly: false))

  /// Debug: log all touch/click/pointer events at the JavaScript level
  let debugTouchScript = """
  (function() {
      var tag = '[JS-PIPELINE]';
      ['touchstart','touchend','click','pointerdown','pointerup'].forEach(function(evt) {
          document.addEventListener(evt, function(e) {
              var x = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : '?');
              var y = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : '?');
              var href = e.target.href || (e.target.closest && e.target.closest('a') ? e.target.closest('a').href : 'none');
              var scrollX = window.scrollX || 0;
              var scrollLeft = document.scrollingElement ? document.scrollingElement.scrollLeft : '?';
              var pageX = e.pageX || '?';
              var msg = tag + ' ' + evt + ': ' + e.target.tagName.toLowerCase() + ' client(' + x + ',' + y + ') page(' + pageX + ',' + (e.pageY || '?') + ') scrollX=' + scrollX + ' scrollLeft=' + scrollLeft + ' href=' + href;
              try { window.webkit.messageHandlers.debugLog.postMessage(msg); } catch(ex) {}
          }, true);
      });
  })();
  """
  userScripts.append(WKUserScript(source: debugTouchScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
}

private func canScroll(locations: Locator.Locations?) -> Bool {
  guard let locations = locations else { return false }
  return locations.domRange != nil || locations.cssSelector != nil || locations.progression != nil
}
