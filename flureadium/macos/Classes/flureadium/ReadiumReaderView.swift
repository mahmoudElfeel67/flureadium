import ReadiumNavigator
import ReadiumAdapterGCDWebServer
import ReadiumShared
import FlutterMacOS
import AppKit
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

class ReadiumReaderView: NSObject, FlutterPlatformView, EPUBNavigatorDelegate, VisualNavigatorDelegate {

  private let channel: ReadiumReaderChannel
  private var errorStreamHandler: EventStreamHandler?
  private var readerStatusStreamHandler: EventStreamHandler?
  private var textLocatorStreamHandler: EventStreamHandler?
  private let _view: NSView
  private let readiumViewController: EPUBNavigatorViewController
  private var isVerticalScroll = false
  private var hasSentReady = false
  private var enableEdgeTapNavigation: Bool
  private var enableSwipeNavigation: Bool
  private var edgeTapAreaPoints: CGFloat?

  // Retain the navigation adapter to prevent ARC deallocation
  private var directionalNavigationAdapter: DirectionalNavigationAdapter?

  // Scroll-mode position memory: remembers the last scroll position per spine item
  // so swipe-back can restore where the user was in the previous chapter.
  private var spineItemHistory: [String: Locator] = [:]
  private var lastSpineItemLocator: Locator?
  private var currentSpineItemHref: String?

  var publicationIdentifier: String?

  func view() -> NSView {
    print(TAG, "::getView")
    return _view
  }

  deinit {
    print(TAG, "::deinit")
    readiumViewController.view.removeFromSuperview()
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

    let preferencesMap = creationParams["preferences"] as? [String: String]
    let defaultPreferences = preferencesMap.map { EPUBPreferences.init(fromMap: $0) }

    // Navigation config uses defaults; updated via setNavigationConfig channel call
    enableEdgeTapNavigation = true
    enableSwipeNavigation = true
    edgeTapAreaPoints = nil

    let locatorStr = creationParams["initialLocator"] as? String
    let locator = locatorStr == nil ? nil : try! Locator.init(jsonString: locatorStr!)
    print(TAG, "publication = \(publication)")

    channel = ReadiumReaderChannel(
      name: "\(readiumReaderViewType):\(viewId)", binaryMessenger: registrar.messenger)
    textLocatorStreamHandler = EventStreamHandler(withName: "text-locator", messenger: registrar.messenger)
    readerStatusStreamHandler = EventStreamHandler(withName: "reader-status", messenger: registrar.messenger)
    errorStreamHandler = EventStreamHandler(withName: "error", messenger: registrar.messenger)

    readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusLoading)

    print(TAG, "Publication: (identifier=\(String(describing: publication.metadata.identifier)),title=\(String(describing: publication.metadata.title)))")
    print(TAG, "Added publication at \(String(describing: publication.baseURL))")

    // Remove undocumented Readium default top/bottom padding.
    var config = EPUBNavigatorViewController.Configuration()
    config.contentInset = [
      .compact: (top: 0, bottom: 0),
      .regular: (top: 0, bottom: 0),
    ]
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

    _view = EdgeTapInterceptView()
    super.init()

    channel.setMethodCallHandler(onMethodCall)
    readiumViewController.delegate = self

    // Set initial scroll mode from preferences and configure edge tap handlers accordingly
    isVerticalScroll = defaultPreferences?.scroll ?? false
    configureEdgeTapHandlers(isScrollMode: isVerticalScroll)

    let child: NSView = readiumViewController.view
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

    currentReaderView = self
    publicationIdentifier = publication.metadata.identifier

    /// This adapter will automatically turn pages when the user clicks the
    /// screen edges or presses arrow keys.
    directionalNavigationAdapter = DirectionalNavigationAdapter(
        pointerPolicy: .init(types: [.mouse])
    )
    directionalNavigationAdapter?.bind(to: readiumViewController)

    print(TAG, "::init success")
  }

  @objc public func onCustomEditingAction() {
    print(TAG, "EditingAction::NOTA")
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
  }

  // override EPUBNavigatorDelegate::middleTapHandler
  func middleTapHandler() {
  }

  // macOS: NSEdgeInsets instead of UIEdgeInsets
  func navigatorContentInset(_ navigator: VisualNavigator) -> NSEdgeInsets? {
    return .init(top: 0, left: 0, bottom: 0, right: 0)
  }

  // override EPUBNavigatorDelegate::navigator:presentError
  func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
    print(TAG, "presentError: \(error)")
  }

  // override EPUBNavigatorDelegate::navigator:didFailToLoadResourceAt
  func navigator(_ navigator: Navigator, didFailToLoadResourceAt href: ReadiumShared.RelativeURL, withError error: ReadiumShared.ReadError) {
    print(TAG, "didFailToLoadResourceAt: \(href). err: \(error)")

    self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusError)

    let error = FlureadiumError(message: error.localizedDescription, code: "DidFailToLoadResource", data: href.string)
    self.errorStreamHandler?.sendEvent(error)
  }

  // override NavigatorDelegate::navigator:locationDidChange
  func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
    print(TAG, "onPageChanged: \(locator)")

    let newHref = strippedHref(locator.href.string)

    if isVerticalScroll, let oldHref = currentSpineItemHref, newHref != oldHref {
      if let outgoing = lastSpineItemLocator {
        spineItemHistory[oldHref] = outgoing
      }

      let readingOrder = readiumViewController.publication.readingOrder
      if isBackwardNavigation(from: oldHref, to: newHref, in: readingOrder),
         let stored = spineItemHistory[newHref] {
        Task { @MainActor in
          await self.goToLocator(locator: stored, animated: false)
        }
      }
    }

    currentSpineItemHref = newHref
    lastSpineItemLocator = locator

    if !hasSentReady {
      self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusReady)
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
    configureEdgeTapHandlers(isScrollMode: isVerticalScroll)
  }

  /// Configure edge tap/click handlers based on scroll mode.
  private func configureEdgeTapHandlers(isScrollMode: Bool) {
    guard let edgeTapView = _view as? EdgeTapInterceptView else { return }

    edgeTapView.interceptEdgeTaps = !isScrollMode

    if isScrollMode {
      edgeTapView.onLeftEdgeTap = nil
      edgeTapView.onRightEdgeTap = nil
    } else {
      if enableEdgeTapNavigation {
        if let points = edgeTapAreaPoints {
          edgeTapView.edgeThresholdPoints = points
        }
        edgeTapView.onLeftEdgeTap = { [weak self] in
          guard let self = self else { return }
          print(TAG, "[FALLBACK] Triggering goLeft via fallback click handler")
          Task { @MainActor in
            let _ = await self.readiumViewController.goLeft(options: NavigatorGoOptions(animated: true))
          }
        }
        edgeTapView.onRightEdgeTap = { [weak self] in
          guard let self = self else { return }
          print(TAG, "[FALLBACK] Triggering goRight via fallback click handler")
          Task { @MainActor in
            let _ = await self.readiumViewController.goRight(options: NavigatorGoOptions(animated: true))
          }
        }
      } else {
        edgeTapView.onLeftEdgeTap = nil
        edgeTapView.onRightEdgeTap = nil
      }
    }
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
    spineItemHistory.removeValue(forKey: strippedHref(locator.href.string))

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
        result(success)
      }
      break
    case "goRight":
      let animated = call.arguments as! Bool
      let readiumViewController = self.readiumViewController

      Task { @MainActor in
        let success = await readiumViewController.goRight(options: NavigatorGoOptions(animated: animated))
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
        guard let json = await self.readiumViewController.currentLocation?.jsonString else {
          await MainActor.run { result(nil) }
          return
        }
        let data = await self.getLocatorFragments(json, isVerticalScroll)
        await MainActor.run {
          result(data?.jsonString)
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
    case "setNavigationConfig":
      let args = call.arguments as! [String: Any]
      print(TAG, "onMethodCall[setNavigationConfig] args = \(args)")
      let navConfig = FlutterNavigationConfig(fromMap: args)
      if let v = navConfig.enableEdgeTapNavigation { enableEdgeTapNavigation = v }
      if let v = navConfig.enableSwipeNavigation { enableSwipeNavigation = v }
      if let pts = navConfig.edgeTapAreaPoints {
        edgeTapAreaPoints = CGFloat(min(max(pts, 44.0), 120.0))
      }
      configureEdgeTapHandlers(isScrollMode: isVerticalScroll)
      result(nil)
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

      print(TAG, "onMethodCall[applyDecorations] args = \(args)")
      applyDecorations(decorations, forGroup: identifier)
      break
    case "dispose":
      print(TAG, "Disposing readiumViewController")
      readiumViewController.view.removeFromSuperview()
      readiumViewController.delegate = nil
      self.readerStatusStreamHandler?.sendEvent(ReadiumReaderStatusClosed)
      textLocatorStreamHandler?.dispose()
      textLocatorStreamHandler = nil
      readerStatusStreamHandler?.dispose()
      readerStatusStreamHandler = nil
      errorStreamHandler?.dispose()
      errorStreamHandler = nil
      channel.setMethodCallHandler(nil)
      if currentReaderView === self { currentReaderView = nil }
      result(nil)
      break
    default:
      print(TAG, "Unhandled call \(call.method)")
      result(FlutterMethodNotImplemented)
      break
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
  for jsScript in jsScripts {
    userScripts.append(WKUserScript(source: jsScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
  }
  for addCssScript in addCssScripts {
    userScripts.append(WKUserScript(source: addCssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
  }
  // macOS: detect as macOS instead of iOS
  userScripts.append(WKUserScript(source: "const isAndroid=false,isIos=false,isMacOS=true;", injectionTime: .atDocumentStart, forMainFrameOnly: false))

  // Click synthesis not needed on macOS — native mouse clicks work correctly with WKWebView
}

func strippedHref(_ href: String) -> String {
  href.components(separatedBy: "#").first?
      .components(separatedBy: "?").first ?? href
}

func chapterLink(before currentHref: String, in readingOrder: [Link]) -> Link? {
  let clean = strippedHref(currentHref)
  guard let idx = readingOrder.firstIndex(where: { strippedHref($0.href) == clean }),
        idx > 0 else { return nil }
  return readingOrder[idx - 1]
}

func chapterLink(after currentHref: String, in readingOrder: [Link]) -> Link? {
  let clean = strippedHref(currentHref)
  guard let idx = readingOrder.firstIndex(where: { strippedHref($0.href) == clean }),
        idx < readingOrder.count - 1 else { return nil }
  return readingOrder[idx + 1]
}

func isBackwardNavigation(from oldHref: String, to newHref: String, in readingOrder: [Link]) -> Bool {
  let cleanOld = strippedHref(oldHref)
  let cleanNew = strippedHref(newHref)
  guard let oldIdx = readingOrder.firstIndex(where: { strippedHref($0.href) == cleanOld }),
        let newIdx = readingOrder.firstIndex(where: { strippedHref($0.href) == cleanNew }) else {
    return false
  }
  return newIdx < oldIdx
}

private func canScroll(locations: Locator.Locations?) -> Bool {
  guard let locations = locations else { return false }
  return locations.domRange != nil || locations.cssSelector != nil || locations.progression != nil
}
