//
//  AppDelegate.swift
//  md_viewer_xcode
//
//  Created by cahpac on 10/19/25.
//

import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create menu bar
        createMenuBar()

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        // Ensure window appears on main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
            window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
        }

        window.title = "MD Viewer"

        // Create and set content view controller
        let viewController = MarkdownViewController()
        window.contentViewController = viewController

        // Show window
        window.makeKeyAndOrderFront(nil)

        // Set as main window
        NSApp.mainWindow?.orderFrontRegardless()

        // Activate the app to bring it to front
        NSApp.activate(ignoringOtherApps: true)

        // Force window to front
        window.orderFrontRegardless()

        // Handle file opening from Finder
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }

    func createMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Quit MD Viewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(NSMenuItem(title: "Show Window Size", action: #selector(showWindowSize(_:)), keyEquivalent: "i"))

        NSApp.mainMenu = mainMenu
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                if let viewController = self?.window.contentViewController as? MarkdownViewController {
                    viewController.loadFile(url: url)
                }
            }
        }
    }

    @objc func showWindowSize(_ sender: Any?) {
        let size = window.frame.size
        let alert = NSAlert()
        alert.messageText = "Window Dimensions"
        alert.informativeText = "Width: \(Int(size.width)) px\nHeight: \(Int(size.height)) px"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlDescriptor = event.paramDescriptor(forKeyword: keyDirectObject) else { return }

        if let urlString = urlDescriptor.stringValue,
           let url = URL(string: urlString) {
            if let viewController = window.contentViewController as? MarkdownViewController {
                viewController.loadFile(url: url)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Main entry point
@main
struct Main {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

