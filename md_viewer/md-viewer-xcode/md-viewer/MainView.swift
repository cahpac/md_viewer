import Cocoa
import WebKit
import Markdown

class MainView: NSView {

    private let webView = WKWebView()
    private var fileMonitor: DispatchSourceFileSystemObject?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        webView.frame = bounds
        webView.autoresizingMask = [.width, .height]
        addSubview(webView)

        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL else {
            return false
        }

        if url.pathExtension == "md" {
            loadFile(url: url)
            return true
        } else {
            let alert = NSAlert()
            alert.messageText = "Invalid File Type"
            alert.informativeText = "Please drop a Markdown file (.md)."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return false
        }
    }

    private func loadFile(url: URL) {
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
                        let document = try Document(parsing: markdown)
            let html = document.html
            webView.loadHTMLString(html, baseURL: nil)
            startMonitoringFile(url: url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error Reading File"
            alert.informativeText = "Could not read the file: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func startMonitoringFile(url: URL) {
        let fileDescriptor = open(url.path, O_EVTONLY)
        fileMonitor = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: .main)
        fileMonitor?.setEventHandler { [weak self] in
            self?.loadFile(url: url)
        }
        fileMonitor?.resume()
    }
}
