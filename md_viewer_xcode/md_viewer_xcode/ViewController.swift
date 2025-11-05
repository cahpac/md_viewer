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

    // Return nil to allow mouse events to pass through to webView below
    // Drag operations will still work via registerForDraggedTypes
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class MarkdownViewController: NSViewController {

    private var webView: WKWebView!
    private var currentFileURL: URL?
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var reloadDebounceWorkItem: DispatchWorkItem?

    override func loadView() {
        // Create container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 1100, height: 600))
        containerView.autoresizingMask = [.width, .height]

        // Create web view with proper initial size
        let configuration = WKWebViewConfiguration()

        // Security: Use non-persistent data store (no cookies/localStorage)
        configuration.websiteDataStore = .nonPersistent()

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
        // Get version information
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

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
                .logo { margin-bottom: 16px; }
                .logo svg { width: 140px; height: auto; display: inline-block; }
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
                .version {
                    color: #999999;
                    font-size: 14px;
                    margin-top: 12px;
                }
            </style>
        </head>
        <body>
            <div class="welcome">
                <div class="logo">
                    <svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <defs>
                        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
                          <stop offset="0%" stop-color="#0A84FF"/>
                          <stop offset="100%" stop-color="#2563EB"/>
                        </linearGradient>
                        <linearGradient id="spark" x1="0" y1="0" x2="1" y2="1">
                          <stop offset="0%" stop-color="#22D3EE"/>
                          <stop offset="100%" stop-color="#14B8A6"/>
                        </linearGradient>
                        <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
                          <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#0B1B3A" flood-opacity="0.25"/>
                        </filter>
                      </defs>

                      <rect x="64" y="64" width="896" height="896" rx="176" fill="url(#bg)"/>

                      <g filter="url(#shadow)">
                        <rect x="256" y="208" width="512" height="624" rx="40" fill="#FFFFFF"/>
                        <rect x="256" y="208" width="512" height="72" rx="40" fill="#EEF6FF"/>
                        <text x="300" y="360" font-family="-apple-system, system-ui, Segoe UI, Roboto, Arial, sans-serif" font-size="120" font-weight="700" fill="#0F172A">#</text>
                        <rect x="300" y="390" width="384" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="426" width="352" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="462" width="368" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="522" width="404" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="558" width="340" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="594" width="376" height="18" rx="9" fill="#E5E7EB"/>
                        <rect x="300" y="654" width="240" height="28" rx="14" fill="#F3F4F6"/>
                      </g>

                      <g transform="translate(688,176) rotate(10)">
                        <path d="M40 0 L50 30 L80 40 L50 50 L40 80 L30 50 L0 40 L30 30 Z" fill="url(#spark)" opacity="0.95"/>
                        <circle cx="40" cy="40" r="6" fill="#FFFFFF" opacity="0.9"/>
                      </g>

                      <path d="M200 352 c0 -24 16 -40 40 -40 h32 v24 h-20 c-8 0 -12 4 -12 12 v248 c0 8 4 12 12 12 h20 v24 h-32 c-24 0 -40 -16 -40 -40 z" fill="#D9E6FF"/>
                      <path d="M824 352 c0 -24 -16 -40 -40 -40 h-32 v24 h20 c8 0 12 4 12 12 v248 c0 8 -4 12 -12 12 h-20 v24 h32 c24 0 40 -16 40 -40 z" fill="#D9E6FF"/>
                    </svg>
                </div>
                <h1>MD Viewer</h1>
                <p>Drag a markdown file here to view it</p>
                <p class="version">Version \(version) (Build \(build))</p>
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
            let htmlContent = HTMLRenderer().render(document: document, sourceText: markdownContent)

            // Prefer locally bundled mermaid.min.js, otherwise use CDN in Debug, or a stub in Release
            let mermaidScriptTag: String = {
                if let localURL = Bundle.main.url(forResource: "mermaid.min", withExtension: "js"),
                   let js = try? String(contentsOf: localURL, encoding: .utf8) {
                    return "<script>\n" + js + "\n</script>"
                } else {
                    #if DEBUG
                    return "<script src=\"https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js\"></script>"
                    #else
                    // No network in release: provide a no-op stub so page still loads
                    let stub = "window.mermaid={initialize:function(){},run:function(){}};"
                    return "<script>\(stub)</script>"
                    #endif
                }
            }()

            // Wrap in styled HTML
            let fullHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'unsafe-inline' 'unsafe-eval'; style-src 'unsafe-inline'; img-src data: https:; connect-src 'none';">
                <style>
                    html, body {
                        margin: 0;
                        padding: 0;
                    }
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        line-height: 1.6;
                        color: #333;
                        max-width: 960px;
                        margin: 0 auto;
                        padding: 20px;
                        padding-left: 100px;
                        position: relative;
                        background-color: #fff;
                        min-height: 100vh;
                    }
                    /* Gutter background that moves with body */
                    body::before {
                        content: '';
                        position: absolute;
                        left: 20px;
                        top: 0;
                        height: 100%;
                        width: 60px;
                        background-color: #f6f8fa;
                        border-right: 1px solid #d0d7de;
                        pointer-events: none;
                    }
                    h1, h2, h3, h4, h5, h6 {
                        margin-top: 0;
                        margin-bottom: 0;
                        font-weight: 600;
                        line-height: 1.25;
                    }
                    h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                    h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                    h3 { font-size: 1.25em; }
                    p {
                        margin: 0;
                        padding: 0;
                    }
                    ul, ol {
                        margin: 0;
                        padding-left: 2em;
                    }
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
                        margin: 0;
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
                        margin: 0;
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
                        margin: 0;
                        background-color: #e1e4e8;
                        border: 0;
                    }
                    del {
                        text-decoration: line-through;
                        opacity: 0.7;
                    }
                    input[type="checkbox"] {
                        margin-right: 0.5em;
                        vertical-align: middle;
                    }
                    .html-block {
                        margin: 0;
                    }
                    .mermaid {
                        text-align: center;
                        margin: 2rem 0;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
                    }
                    /* Line number gutter */
                    [data-line] {
                        position: relative;
                    }
                    [data-line]::before {
                        content: attr(data-line);
                        position: absolute;
                        left: -80px;
                        top: 50%;
                        transform: translateY(-50%);
                        width: 52px;
                        text-align: right;
                        color: #6e7781;
                        font-size: 12px !important;
                        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                        font-weight: normal !important;
                        line-height: 1;
                        user-select: none;
                        -webkit-user-select: none;
                    }
                    /* Blank lines */
                    .blank-line {
                        position: relative;
                        font-size: 16px;
                        line-height: 1.25;
                        margin: 0;
                        padding: 0;
                        height: 1.25em;
                    }
                    .blank-line::before {
                        content: attr(data-line);
                        position: absolute;
                        left: -80px;
                        top: 50%;
                        transform: translateY(-50%);
                        width: 52px;
                        text-align: right;
                        color: #6e7781;
                        font-size: 12px !important;
                        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                        line-height: 1;
                        user-select: none;
                        -webkit-user-select: none;
                    }
                </style>
                \(mermaidScriptTag)
            </head>
            <body>
                \(htmlContent)
                <script>
                (function(){
                  try {
                    // Listen for resize messages from iframes
                    window.addEventListener('message', function(event) {
                      if (event.data && event.data.type === 'resize' && event.data.height) {
                        // Find the iframe that sent the message
                        var iframes = document.querySelectorAll('iframe');
                        for (var i = 0; i < iframes.length; i++) {
                          if (iframes[i].contentWindow === event.source) {
                            iframes[i].style.height = event.data.height + 'px';
                            break;
                          }
                        }
                      }
                    });

                    // Initialize Mermaid in parent window
                    if (!window.mermaid) {
                      console.error('Mermaid not loaded');
                      return;
                    }

                    window.mermaid.initialize({
                      startOnLoad: false,
                      securityLevel: 'strict',
                      theme: 'default',
                      themeVariables: {
                        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                        fontSize: '14px'
                      }
                    });

                    // Convert code blocks with language-mermaid to sandboxed iframes
                    var blocks = document.querySelectorAll('pre code.language-mermaid, pre code[class*="mermaid"]');
                    var renderPromises = [];

                    blocks.forEach(function(code, index){
                      var pre = code.closest('pre');
                      var mermaidCode = code.textContent;
                      var uniqueId = 'mermaid-diagram-' + index;

                      // Create a temporary div to render the diagram
                      var tempDiv = document.createElement('div');
                      tempDiv.className = 'mermaid';
                      tempDiv.id = uniqueId;
                      tempDiv.textContent = mermaidCode;
                      tempDiv.style.display = 'none';
                      document.body.appendChild(tempDiv);

                      // Render the diagram in the parent
                      var promise = window.mermaid.render(uniqueId + '-svg', mermaidCode)
                        .then(function(result) {
                          // Create sandboxed iframe
                          var iframe = document.createElement('iframe');
                          iframe.setAttribute('sandbox', 'allow-scripts');
                          iframe.style.width = '100%';
                          iframe.style.border = 'none';
                          iframe.style.overflow = 'hidden';
                          iframe.style.display = 'block';

                          // Create iframe content with the rendered SVG and height reporting script
                          var iframeContent = '<!DOCTYPE html><html><head><style>body{margin:0;padding:8px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;overflow:hidden;}</style></head><body>' + result.svg + '<scr'+'ipt>window.addEventListener("load",function(){var h=Math.max(document.body.scrollHeight,document.documentElement.scrollHeight,document.body.offsetHeight);window.parent.postMessage({type:"resize",height:h},"*");});</scr'+'ipt></body></html>';
                          iframe.srcdoc = iframeContent;

                          // Replace pre with iframe
                          pre.replaceWith(iframe);

                          // Remove temp div
                          document.body.removeChild(tempDiv);
                        })
                        .catch(function(error) {
                          console.error('Mermaid render error:', error);
                          // Show error in place of diagram
                          var errorDiv = document.createElement('div');
                          errorDiv.style.padding = '10px';
                          errorDiv.style.backgroundColor = '#fee';
                          errorDiv.style.border = '1px solid #fcc';
                          errorDiv.textContent = 'Error rendering diagram: ' + error.message;
                          pre.replaceWith(errorDiv);
                          document.body.removeChild(tempDiv);
                        });

                      renderPromises.push(promise);
                    });

                  } catch (e) { console.error('Mermaid setup error:', e); }
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
        let fd = open(path, O_EVTONLY)
        fileDescriptor = fd

        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            guard let self = self, let watcher = self.fileWatcher else { return }

            let events = watcher.data

            // If the file was renamed or deleted (common with atomic saves), re-establish the watch
            if events.contains(.rename) || events.contains(.delete) {
                if let url = self.currentFileURL {
                    // Tear down and restart watching the same path
                    self.stopWatchingFile()
                    self.startWatchingFile(url: url)
                }
            }

            // Debounce rapid sequences of events while the editor writes
            self.reloadDebounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.renderMarkdown()
            }
            self.reloadDebounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
        }

        // Important: close the exact fd captured for this watcher to avoid
        // closing a newly opened descriptor with the same integer value.
        source.setCancelHandler {
            close(fd)
        }

        fileWatcher = source
        source.resume()
    }

    func stopWatchingFile() {
        // Cancel any pending debounced reload
        reloadDebounceWorkItem?.cancel()
        reloadDebounceWorkItem = nil

        // Cancel the source; its cancel handler will close the captured fd.
        if let watcher = fileWatcher {
            watcher.cancel()
        }
        fileWatcher = nil
        fileDescriptor = -1
    }

    deinit {
        stopWatchingFile()
    }

    // MARK: - Clipboard Support

    func copySelection() {
        webView.evaluateJavaScript("window.getSelection().toString()") { [weak self] result, error in
            if let selectedText = result as? String, !selectedText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(selectedText, forType: .string)
            }
        }
    }

    func selectAll() {
        webView.evaluateJavaScript("document.execCommand('selectAll', false, null)")
    }

    func showInFinder() {
        guard let fileURL = currentFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    // MARK: - Find Feature

    func showFindPanel() {
        let alert = NSAlert()
        alert.messageText = "Find"
        alert.informativeText = "Search for text in the document:"
        alert.addButton(withTitle: "Find")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = "Enter search text"
        alert.accessoryView = inputTextField

        alert.window.initialFirstResponder = inputTextField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let searchText = inputTextField.stringValue
            if !searchText.isEmpty {
                performFind(searchText: searchText)
            }
        }
    }

    private func performFind(searchText: String) {
        let escapedSearch = searchText.replacingOccurrences(of: "\\", with: "\\\\")
                                      .replacingOccurrences(of: "'", with: "\\'")

        let script = """
        (function() {
            window.find('\(escapedSearch)', false, false, true, false, true, false);
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Find error: \\(error)")
            }
        }
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

class HTMLRenderer {
    private var currentTable: Table?
    private var currentColumnIndex: Int = 0
    private var lastRenderedLine: Int = 0
    private var totalLines: Int = 0

    func render(document: Document, sourceText: String) -> String {
        // Count total lines in source
        totalLines = sourceText.components(separatedBy: .newlines).count

        var html = ""
        lastRenderedLine = 0  // Start at 0 so first element on line 1 works correctly

        for child in document.children {
            html += renderMarkup(child)
        }

        // Fill in any remaining lines at the end
        if lastRenderedLine < totalLines {
            html += fillGapLines(to: totalLines)
        }

        return html
    }

    private func renderMarkup(_ markup: Markup) -> String {
        var html = ""

        // Fill in any gap lines before this element
        if let lineNumber = markup.range?.lowerBound.line, shouldShowLineNumber(for: markup) {
            html += fillGapLines(to: lineNumber - 1)
        }

        switch markup {
        case let heading as Heading:
            let content = heading.children.map { renderMarkup($0) }.joined()
            let lineAttr = shouldShowLineNumber(for: heading) ? lineNumberAttribute(for: heading) : ""
            if shouldShowLineNumber(for: heading) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<h\(heading.level)\(lineAttr)>\(content)</h\(heading.level)>\n"

        case let paragraph as Paragraph:
            let content = paragraph.children.map { renderMarkup($0) }.joined(separator: " ")
            // Only add line numbers to top-level paragraphs, not those inside blockquotes or list items
            let lineAttr = shouldShowLineNumber(for: paragraph) ? lineNumberAttribute(for: paragraph) : ""
            if shouldShowLineNumber(for: paragraph) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<p\(lineAttr)>\(content)</p>\n"

        case let text as Text:
            return escapeHTML(text.string)

        case let strong as Strong:
            let content = strong.children.map { renderMarkup($0) }.joined()
            return "<strong>\(content)</strong>"

        case let emphasis as Emphasis:
            let content = emphasis.children.map { renderMarkup($0) }.joined()
            return "<em>\(content)</em>"

        case let strikethrough as Strikethrough:
            let content = strikethrough.children.map { renderMarkup($0) }.joined()
            return "<del>\(content)</del>"

        case let inlineCode as InlineCode:
            return "<code>\(escapeHTML(inlineCode.code))</code>"

        case _ as LineBreak:
            return "<br />"

        case _ as SoftBreak:
            return "\n"

        case let codeBlock as CodeBlock:
            let language = codeBlock.language ?? ""
            let code = escapeHTML(codeBlock.code)
            let lineAttr = shouldShowLineNumber(for: codeBlock) ? lineNumberAttribute(for: codeBlock) : ""
            if shouldShowLineNumber(for: codeBlock) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<pre\(lineAttr)><code class=\"language-\(language)\">\(code)</code></pre>\n"

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
            let lineAttr = shouldShowLineNumber(for: list) ? lineNumberAttribute(for: list) : ""
            if shouldShowLineNumber(for: list) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<ul\(lineAttr)>\n\(items)</ul>\n"

        case let list as OrderedList:
            let items = list.children.map { renderMarkup($0) }.joined()
            let lineAttr = shouldShowLineNumber(for: list) ? lineNumberAttribute(for: list) : ""
            if shouldShowLineNumber(for: list) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<ol start=\"\(list.startIndex)\"\(lineAttr)>\n\(items)</ol>\n"

        case let item as ListItem:
            let content = item.children.map { renderMarkup($0) }.joined()
            if let checkbox = item.checkbox {
                let checked = checkbox == .checked ? "checked" : ""
                let checkboxHTML = "<input type=\"checkbox\" \(checked) disabled /> "
                return "<li style=\"list-style-type: none;\">\(checkboxHTML)\(content)</li>\n"
            }
            return "<li>\(content)</li>\n"

        case let blockQuote as BlockQuote:
            let content = blockQuote.children.map { renderMarkup($0) }.joined()
            let lineAttr = shouldShowLineNumber(for: blockQuote) ? lineNumberAttribute(for: blockQuote) : ""
            if shouldShowLineNumber(for: blockQuote) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<blockquote\(lineAttr)>\(content)</blockquote>\n"

        case let thematicBreak as ThematicBreak:
            let lineAttr = shouldShowLineNumber(for: thematicBreak) ? lineNumberAttribute(for: thematicBreak) : ""
            if shouldShowLineNumber(for: thematicBreak) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<hr\(lineAttr) />\n"

        case let htmlBlock as HTMLBlock:
            let lineAttr = shouldShowLineNumber(for: htmlBlock) ? lineNumberAttribute(for: htmlBlock) : ""
            if shouldShowLineNumber(for: htmlBlock) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<div\(lineAttr) class=\"html-block\">\(htmlBlock.rawHTML)</div>\n"

        case let inlineHTML as InlineHTML:
            return inlineHTML.rawHTML

        case let table as Table:
            currentTable = table
            let content = table.children.map { renderMarkup($0) }.joined()
            currentTable = nil
            let lineAttr = shouldShowLineNumber(for: table) ? lineNumberAttribute(for: table) : ""
            if shouldShowLineNumber(for: table) {
                updateLastRenderedLine(for: markup)
            }
            return html + "<table\(lineAttr)>\n\(content)</table>\n"

        case let tableHead as Table.Head:
            let rows = tableHead.children.map { renderMarkup($0) }.joined()
            return "<thead>\n\(rows)</thead>\n"

        case let tableBody as Table.Body:
            let rows = tableBody.children.map { renderMarkup($0) }.joined()
            return "<tbody>\n\(rows)</tbody>\n"

        case let tableRow as Table.Row:
            currentColumnIndex = 0
            let cells = tableRow.children.map { renderMarkup($0) }.joined()
            return "<tr>\n\(cells)</tr>\n"

        case let tableCell as Table.Cell:
            // Determine if this is a header cell by checking parent hierarchy
            let tag = isInTableHead(tableCell) ? "th" : "td"
            let content = tableCell.children.map { renderMarkup($0) }.joined()

            var attributes = ""

            // Add alignment attribute using current column index
            if let table = currentTable, currentColumnIndex < table.columnAlignments.count {
                let alignment = table.columnAlignments[currentColumnIndex]
                let alignValue: String?
                switch alignment {
                case .left:
                    alignValue = "left"
                case .center:
                    alignValue = "center"
                case .right:
                    alignValue = "right"
                case .none:
                    alignValue = nil
                @unknown default:
                    alignValue = nil
                }
                if let alignValue = alignValue {
                    attributes += " align=\"\(alignValue)\""
                }
            }

            if tableCell.colspan > 1 {
                attributes += " colspan=\"\(tableCell.colspan)\""
            }
            if tableCell.rowspan > 1 {
                attributes += " rowspan=\"\(tableCell.rowspan)\""
            }

            // Increment column index for next cell
            currentColumnIndex += 1

            return "<\(tag)\(attributes)>\(content)</\(tag)>\n"

        default:
            // Handle other markup types
            return ""
        }
    }

    private func isInTableHead(_ markup: Markup) -> Bool {
        var current: Markup? = markup.parent
        while let parent = current {
            if parent is Table.Head {
                return true
            }
            current = parent.parent
        }
        return false
    }

    private func shouldShowLineNumber(for markup: Markup) -> Bool {
        // Don't show line numbers for elements nested inside blockquotes, list items, or tables
        var current: Markup? = markup.parent
        while let parent = current {
            if parent is BlockQuote || parent is ListItem || parent is Table.Cell {
                return false
            }
            current = parent.parent
        }
        return true
    }

    private func fillGapLines(to targetLine: Int) -> String {
        var html = ""
        // Only create blank lines for gaps between rendered content
        let startLine = lastRenderedLine + 1
        let endLine = targetLine

        // Only fill if there are actually gaps
        guard startLine <= endLine else { return html }

        for lineNum in startLine...endLine {
            lastRenderedLine = lineNum
            html += "<div data-line=\"\(lineNum)\" class=\"blank-line\">&nbsp;</div>\n"
        }
        return html
    }

    private func updateLastRenderedLine(for markup: Markup) {
        // Update to the last line that this element occupies
        if let range = markup.range {
            let endLine: Int
            if range.upperBound.column == 1 {
                // If upperBound is at column 1, it's at the start of the next line
                endLine = range.upperBound.line - 1
            } else {
                // If upperBound is mid-line, that's the last line
                endLine = range.upperBound.line
            }
            lastRenderedLine = max(lastRenderedLine, endLine)
        }
    }

    private func lineNumberAttribute(for markup: Markup) -> String {
        guard let range = markup.range else {
            return ""
        }
        let startLine = range.lowerBound.line
        // upperBound.line is the first line of the next element, so the last line
        // of this element is upperBound.line - 1, BUT we want inclusive end
        // Check if range spans to a newline character
        let endLine: Int
        if range.upperBound.column == 1 {
            // If upperBound is at column 1, it means it's at the start of the next line
            // so the actual last line with content is upperBound.line - 1
            endLine = range.upperBound.line - 1
        } else {
            // If upperBound is mid-line, that's the last line
            endLine = range.upperBound.line
        }

        // If element spans multiple lines, show as range with abbreviated end
        if endLine > startLine {
            let startStr = String(startLine)
            let endStr = String(endLine)

            // Find common prefix length
            var commonPrefixLen = 0
            for (c1, c2) in zip(startStr, endStr) {
                if c1 == c2 {
                    commonPrefixLen += 1
                } else {
                    break
                }
            }

            // Show abbreviated end (only the differing suffix)
            let endSuffix = String(endStr.dropFirst(commonPrefixLen))
            return " data-line=\"\(startLine)-\(endSuffix)\""
        } else {
            return " data-line=\"\(startLine)\""
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
