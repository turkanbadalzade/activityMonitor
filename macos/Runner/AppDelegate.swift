import Cocoa
import FlutterMacOS
import ApplicationServices

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.example.inactivity/detector",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getIdleTimeMs":
        // Compute the minimum across multiple concrete event types.
        let types: [CGEventType] = [
          .mouseMoved,
          .leftMouseDown, .rightMouseDown, .otherMouseDown,
          .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
          .scrollWheel,
          .keyDown, .keyUp
        ]

        var best = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .null)
        for t in types {
          let v = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: t)
          if v >= 0 && v < best { best = v }
        }
        let ms = Int64(best * 1000.0)
        result(ms)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}