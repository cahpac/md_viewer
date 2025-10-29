//
//  ViewController.swift
//  md_viewer_xcode
//
//  Created by cahpac on 10/19/25.
//

import Cocoa
import WebKit
import Markdown

// Transparent overlay view that captures drag events
class DragOverlayView: NSView {
    var onFileDropped: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let url = items.first,
              url.pathExtension.lowercased() == "md" else {
            return []
        }
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let url = items.first,
              url.pathExtension.lowercased() == "md" else {
            return []
        }
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let url = items.first,
              url.pathExtension.lowercased() == "md" else {
            return false
        }
        onFileDropped?(url)
        return true
    }

    // Return self to capture all events including drags
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self
    }

    // Allow mouse events to pass through when not dragging
    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        nextResponder?.mouseDragged(with: event)
    }
}

class MarkdownViewController: NSViewController {

    private var webView: WKWebView!
    private var currentFileURL: URL?
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    override func loadView() {
        // Create container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 600))
        containerView.autoresizingMask = [.width, .height]

        // Create web view with proper initial size
        let configuration = WKWebViewConfiguration()

        // Configure preferences
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        webView = WKWebView(frame: containerView.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]

        // Add webView as subview
        containerView.addSubview(webView)

        // Create transparent overlay on top to capture drag events
        let overlay = DragOverlayView(frame: containerView.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.onFileDropped = { [weak self] url in
            self?.loadFile(url: url)
        }
        containerView.addSubview(overlay)

        self.view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Show welcome message
        showWelcome()
    }

    func showWelcome() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    background-color: #ffffff;
                }
                .welcome {
                    text-align: center;
                    padding: 40px;
                }
                h1 {
                    color: #000000;
                    font-weight: 300;
                    font-size: 48px;
                    margin-bottom: 20px;
                }
                p {
                    color: #666666;
                    font-size: 18px;
                }
            </style>
        </head>
        <body>
            <div class="welcome">
                <h1>MD Viewer</h1>
                <p>Drag a markdown file here to view it</p>
            </div>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: URL(string: "about:blank"))
    }

    func loadFile(url: URL) {
        // Stop watching previous file
        stopWatchingFile()

        currentFileURL = url
        view.window?.title = "MD Viewer - \(url.lastPathComponent)"

        // Render the file
        renderMarkdown()

        // Start watching for changes
        startWatchingFile(url: url)
    }

    func renderMarkdown() {
        guard let fileURL = currentFileURL else { return }

        do {
            // Read markdown content
            let markdownContent = try String(contentsOf: fileURL, encoding: .utf8)

            // Convert markdown to HTML using swift-markdown
            let document = Document(parsing: markdownContent)
            let htmlContent = HTMLRenderer().render(document: document)

            // Wrap in styled HTML
            let fullHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        line-height: 1.6;
                        color: #333;
                        max-width: 900px;
                        margin: 0 auto;
                        padding: 20px;
                        background-color: #fff;
                    }
                    h1, h2, h3, h4, h5, h6 {
                        margin-top: 24px;
                        margin-bottom: 16px;
                        font-weight: 600;
                        line-height: 1.25;
                    }
                    h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                    h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                    h3 { font-size: 1.25em; }
                    code {
                        background-color: #f6f8fa;
                        padding: 0.2em 0.4em;
                        border-radius: 3px;
                        font-size: 85%;
                        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                    }
                    pre {
                        background-color: #f6f8fa;
                        padding: 16px;
                        overflow: auto;
                        border-radius: 6px;
                        line-height: 1.45;
                    }
                    pre code {
                        background-color: transparent;
                        padding: 0;
                    }
                    blockquote {
                        margin: 0;
                        padding: 0 1em;
                        color: #6a737d;
                        border-left: 0.25em solid #dfe2e5;
                    }
                    table {
                        border-collapse: collapse;
                        width: 100%;
                        margin: 16px 0;
                    }
                    table th, table td {
                        border: 1px solid #dfe2e5;
                        padding: 6px 13px;
                    }
                    table tr:nth-child(2n) {
                        background-color: #f6f8fa;
                    }
                    a {
                        color: #0366d6;
                        text-decoration: none;
                    }
                    a:hover {
                        text-decoration: underline;
                    }
                    img {
                        max-width: 100%;
                        height: auto;
                    }
                    hr {
                        height: 0.25em;
                        padding: 0;
                        margin: 24px 0;
                        background-color: #e1e4e8;
                        border: 0;
                    }
                    .mermaid {
                        text-align: center;
                        margin: 2rem 0;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
                    }
                </style>
                <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            </head>
            <body>
                \(htmlContent)
                <script>
                (function(){
                  try {
                    // Convert code blocks with language-mermaid to mermaid divs
                    var blocks = document.querySelectorAll('pre code.language-mermaid, pre code[class*="mermaid"]');
                    blocks.forEach(function(code){
                      var pre = code.closest('pre');
                      var div = document.createElement('div');
                      div.className = 'mermaid';
                      div.textContent = code.textContent;
                      pre.replaceWith(div);
                    });
                    // Initialize and render mermaid
                    if (window.mermaid) {
                      window.mermaid.initialize({
                        startOnLoad: false,
                        securityLevel: 'loose',
                        theme: 'default',
                        themeVariables: {
                          fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                          fontSize: '14px'
                        }
                      });
                      window.mermaid.run({ querySelector: '.mermaid' });
                    }
                  } catch (e) { console.error('Mermaid error:', e); }
                })();
                </script>
            </body>
            </html>
            """

            // Load HTML with base URL for relative resources
            let baseURL = fileURL.deletingLastPathComponent()
            webView.loadHTMLString(fullHTML, baseURL: baseURL)

        } catch {
            let errorHTML = """
            <html>
            <body style="font-family: sans-serif; padding: 20px;">
                <h2 style="color: #d32f2f;">Error loading file</h2>
                <p>\(error.localizedDescription)</p>
            </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }

    func startWatchingFile(url: URL) {
        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)

        guard fileDescriptor >= 0 else { return }

        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.main
        )

        fileWatcher?.setEventHandler { [weak self] in
            self?.renderMarkdown()
        }

        fileWatcher?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }

        fileWatcher?.resume()
    }

    func stopWatchingFile() {
        fileWatcher?.cancel()
        fileWatcher = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    deinit {
        stopWatchingFile()
    }
}

// MARK: - WKNavigationDelegate

extension MarkdownViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Open external links in default browser
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - HTML Renderer for swift-markdown

struct HTMLRenderer {
    func render(document: Document) -> String {
        var html = ""
        for child in document.children {
            html += renderMarkup(child)
        }
        return html
    }

    private func renderMarkup(_ markup: Markup) -> String {
        switch markup {
        case let heading as Heading:
            let content = heading.children.map { renderMarkup($0) }.joined()
            return "<h\(heading.level)>\(content)</h\(heading.level)>\n"

        case let paragraph as Paragraph:
            let content = paragraph.children.map { renderMarkup($0) }.joined()
            return "<p>\(content)</p>\n"

        case let text as Text:
            return escapeHTML(text.string)

        case let strong as Strong:
            let content = strong.children.map { renderMarkup($0) }.joined()
            return "<strong>\(content)</strong>"

        case let emphasis as Emphasis:
            let content = emphasis.children.map { renderMarkup($0) }.joined()
            return "<em>\(content)</em>"

        case let inlineCode as InlineCode:
            return "<code>\(escapeHTML(inlineCode.code))</code>"

        case let codeBlock as CodeBlock:
            let language = codeBlock.language ?? ""
            let code = escapeHTML(codeBlock.code)
            return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"

        case let link as Link:
            let content = link.children.map { renderMarkup($0) }.joined()
            let destination = link.destination ?? ""
            return "<a href=\"\(escapeHTML(destination))\">\(content)</a>"

        case let image as Image:
            let source = image.source ?? ""
            let title = image.title.map { escapeHTML($0) } ?? ""
            return "<img src=\"\(escapeHTML(source))\" alt=\"\(title)\" />"

        case let list as UnorderedList:
            let items = list.children.map { renderMarkup($0) }.joined()
            return "<ul>\n\(items)</ul>\n"

        case let list as OrderedList:
            let items = list.children.map { renderMarkup($0) }.joined()
            return "<ol start=\"\(list.startIndex)\">\n\(items)</ol>\n"

        case let item as ListItem:
            let content = item.children.map { renderMarkup($0) }.joined()
            return "<li>\(content)</li>\n"

        case let blockQuote as BlockQuote:
            let content = blockQuote.children.map { renderMarkup($0) }.joined()
            return "<blockquote>\(content)</blockquote>\n"

        case _ as ThematicBreak:
            return "<hr />\n"

        default:
            // Handle other markup types
            return ""
        }
    }

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

