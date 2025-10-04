#!/usr/bin/env python3
"""
MD Viewer - A minimal markdown viewer with live preview and Mermaid diagram support

Version: 2.0.0
Date: 2024-09-28
Author: Claude Code Assistant
License: MIT

Features:
- Live markdown preview with file watching
- Drag-and-drop file loading
- Server-side Mermaid diagram rendering (requires mermaid-cli)
- Responsive HTML styling
- Error handling with graceful fallbacks

Requirements:
- Python 3.13.5+
- PyQt6 >= 6.7.1
- PyQt6-WebEngine >= 6.7.0
- markdown >= 3.6
- mermaid-cli (optional, for Mermaid diagrams): npm install -g @mermaid-js/mermaid-cli

Changelog:
v2.0.0 (2024-09-28): Added server-side Mermaid diagram rendering
v1.0.0 (2024-07-28): Initial release with basic markdown viewing
"""

__version__ = "2.0.0"
__author__ = "Claude Code Assistant"
__license__ = "MIT"

import sys
import time
import re
import subprocess
import tempfile
import base64
from pathlib import Path
from threading import Thread, Event

from PyQt6.QtCore import Qt, QThread, pyqtSignal, QUrl
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QLabel
from PyQt6.QtWebEngineWidgets import QWebEngineView
import markdown


class FileWatcher(QThread):
    """Simple file watcher using pathlib polling"""
    file_changed = pyqtSignal()
    
    def __init__(self, filepath):
        super().__init__()
        self.filepath = Path(filepath)
        self.last_mtime = self.filepath.stat().st_mtime
        self.active = True
        self._stop_event = Event()
        
    def run(self):
        while self.active and not self._stop_event.is_set():
            try:
                current_mtime = self.filepath.stat().st_mtime
                if current_mtime > self.last_mtime:
                    self.last_mtime = current_mtime
                    self.file_changed.emit()
            except FileNotFoundError:
                self.active = False
            except Exception:
                pass  # Ignore other errors
            
            # Check every second
            self._stop_event.wait(1.0)
    
    def stop(self):
        self.active = False
        self._stop_event.set()
        self.wait()  # Wait for thread to finish


class MDViewer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.current_file = None
        self.file_watcher = None
        self.init_ui()
        
    def init_ui(self):
        self.setWindowTitle(f"MD Viewer v{__version__}")
        self.setGeometry(200, 200, 800, 600)
        
        # Create central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Create layout
        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(0, 0, 0, 0)
        
        # Create web view for rendering
        self.web_view = QWebEngineView()
        self.web_view.setAcceptDrops(False)  # We'll handle drops on the window
        layout.addWidget(self.web_view)
        
        # Enable drag and drop
        self.setAcceptDrops(True)
        
        # Show initial content
        self.show_welcome()
        
    def show_welcome(self):
        """Show welcome message"""
        html = """
        <html>
        <head>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background-color: #f5f5f5;
                }
                .welcome {
                    text-align: center;
                    color: #666;
                }
                h1 {
                    color: #333;
                    font-weight: 300;
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
        self.web_view.setHtml(html)
        
    def dragEnterEvent(self, event):
        """Handle drag enter"""
        if event.mimeData().hasUrls():
            # Check if any URL is a markdown file
            for url in event.mimeData().urls():
                if url.isLocalFile() and url.toLocalFile().endswith('.md'):
                    event.acceptProposedAction()
                    return
        event.ignore()
        
    def dropEvent(self, event):
        """Handle file drop"""
        for url in event.mimeData().urls():
            if url.isLocalFile():
                filepath = url.toLocalFile()
                if filepath.endswith('.md'):
                    self.load_file(filepath)
                    break
                    
    def load_file(self, filepath):
        """Load and render markdown file"""
        # Stop previous watcher if any
        if self.file_watcher:
            self.file_watcher.stop()
            self.file_watcher = None
            
        self.current_file = Path(filepath)
        self.setWindowTitle(f"MD Viewer v{__version__} - {self.current_file.name}")
        
        # Render the file
        self.render_markdown()
        
        # Start watching for changes
        self.file_watcher = FileWatcher(filepath)
        self.file_watcher.file_changed.connect(self.render_markdown)
        self.file_watcher.start()
        
    def process_mermaid_blocks(self, md_content):
        """Process Mermaid code blocks and convert them to PNG images"""
        # Pattern to find Mermaid code blocks
        mermaid_pattern = r'```mermaid\n([\s\S]*?)```'

        import re
        mermaid_blocks = re.findall(mermaid_pattern, md_content)
        print(f"DEBUG: process_mermaid_blocks called, found {len(mermaid_blocks)} mermaid blocks")

        if not mermaid_blocks:
            print("DEBUG: No mermaid blocks found, returning original content")
            return md_content

        def replace_mermaid(match):
            mermaid_code = match.group(1)

            try:
                # Create temporary files for input and output
                with tempfile.NamedTemporaryFile(mode='w', suffix='.mmd', delete=False) as input_file:
                    input_file.write(mermaid_code)
                    input_path = input_file.name

                output_path = input_path.replace('.mmd', '.png')

                import os
                import sys

                # Check if running as frozen app
                if getattr(sys, 'frozen', False):
                    # Running as bundled app
                    bundle_dir = sys._MEIPASS
                    # Use system node with bundled mermaid-cli
                    node_path = '/usr/local/bin/node'  # macOS typical location
                    if not os.path.exists(node_path):
                        node_path = 'node'  # Fallback to PATH

                    # Path to bundled mermaid-cli
                    mmdc_script = os.path.join(bundle_dir, 'node_modules', '@mermaid-js', 'mermaid-cli', 'src', 'cli.js')
                    node_modules_path = os.path.join(bundle_dir, 'node_modules')
                    puppeteer_config = os.path.join(bundle_dir, 'puppeteer-config.json')

                    cmd = [node_path, mmdc_script, '-i', input_path, '-o', output_path, '-b', 'white', '-t', 'default']
                else:
                    # Running as script
                    mmdc_path = '/Users/cahpac/.npm-global/bin/mmdc'
                    if not os.path.exists(mmdc_path):
                        mmdc_path = 'mmdc'  # Fallback to PATH lookup
                    puppeteer_config = os.path.join(os.path.dirname(__file__), 'puppeteer-config.json')
                    node_modules_path = None

                    cmd = [mmdc_path, '-i', input_path, '-o', output_path, '-b', 'white', '-t', 'default']
                if os.path.exists(puppeteer_config):
                    cmd.extend(['--puppeteerConfigFile', puppeteer_config])

                # Set up environment for subprocess
                env = os.environ.copy()
                if node_modules_path:
                    env['NODE_PATH'] = node_modules_path
                    # For bundled app, we need to use system node
                    env['PATH'] = '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'

                # Run mermaid-cli to generate PNG
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=10,
                    env=env
                )

                if result.returncode == 0 and Path(output_path).exists():
                    # Read the generated PNG
                    with open(output_path, 'rb') as f:
                        png_data = f.read()

                    # Convert to base64 for embedding
                    png_base64 = base64.b64encode(png_data).decode('utf-8')

                    # Clean up temporary files
                    Path(input_path).unlink(missing_ok=True)
                    Path(output_path).unlink(missing_ok=True)

                    # Return the PNG embedded as base64
                    return f'<div class="mermaid-diagram" style="text-align: center; margin: 2rem 0;"><img src="data:image/png;base64,{png_base64}" alt="Mermaid Diagram" style="max-width: 100%; height: auto;"/></div>'
                else:
                    # Fall back to client-side Mermaid render
                    return f'<div class="mermaid">{mermaid_code}</div>'

            except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
                # Fall back to client-side Mermaid render for any error
                return f'<div class="mermaid">{mermaid_code}</div>'

        # Replace all Mermaid blocks with PNG images
        return re.sub(mermaid_pattern, replace_mermaid, md_content)

    def render_markdown(self):
        """Read and render the current markdown file"""
        if not self.current_file or not self.current_file.exists():
            return

        try:
            # Read markdown content
            md_content = self.current_file.read_text(encoding='utf-8')

            # Process Mermaid blocks first (convert to SVG)
            md_content = self.process_mermaid_blocks(md_content)

            # Convert to HTML with HTML allowed
            import markdown.extensions.md_in_html
            html_content = markdown.markdown(
                md_content,
                extensions=[
                    'extra',  # Tables, footnotes, etc.
                    'codehilite',  # Code highlighting
                    'toc',  # Table of contents
                    'nl2br',  # New line to break
                    'md_in_html',  # Allow HTML in markdown
                ]
            )
            
            # Wrap in HTML with styling
            full_html = """
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
                    .mermaid-diagram {
                        text-align: center;
                        margin: 2rem 0;
                    }
                </style>
            </head>
            <body>
                {html_content}
                <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
                <script>
                (function(){
                  try {
                    // Convert any remaining ```mermaid blocks rendered as code
                    var blocks = document.querySelectorAll('pre code.language-mermaid');
                    blocks.forEach(function(code){
                      var pre = code.closest('pre');
                      var div = document.createElement('div');
                      div.className = 'mermaid';
                      div.textContent = code.textContent;
                      pre.replaceWith(div);
                    });
                    // Render all .mermaid blocks (including server-side fallback)
                    if (window.mermaid) {
                      window.mermaid.initialize({ startOnLoad: false, securityLevel: 'loose' });
                      window.mermaid.run({ querySelector: '.mermaid' });
                    }
                  } catch (e) { /* ignore */ }
                })();
                </script>
            </body>
            </html>
            """
            # Inject rendered markdown safely without f-string interpolation
            full_html = full_html.replace("{html_content}", html_content)
            
            # Get current scroll position
            page = self.web_view.page()
            scroll_pos = page.scrollPosition()
            
            # Set HTML content
            self.web_view.setHtml(full_html, QUrl.fromLocalFile(str(self.current_file.parent) + '/'))
            
            # Restore scroll position after content loads
            page.loadFinished.connect(lambda: page.runJavaScript(
                f"window.scrollTo({scroll_pos.x()}, {scroll_pos.y()});"
            ))
            
        except Exception as e:
            error_html = f"""
            <html>
            <body style="font-family: sans-serif; padding: 20px;">
                <h2 style="color: #d32f2f;">Error loading file</h2>
                <p>{str(e)}</p>
            </body>
            </html>
            """
            self.web_view.setHtml(error_html)
            
    def closeEvent(self, event):
        """Clean up when closing"""
        if self.file_watcher:
            self.file_watcher.stop()
        event.accept()


def main():
    # Handle version argument
    if len(sys.argv) > 1 and sys.argv[1] in ('--version', '-v'):
        print(f"MD Viewer v{__version__}")
        print(f"Author: {__author__}")
        print(f"License: {__license__}")
        return

    app = QApplication(sys.argv)
    app.setApplicationName("MD Viewer")
    app.setApplicationVersion(__version__)

    viewer = MDViewer()
    viewer.show()

    # Handle file argument if provided
    if len(sys.argv) > 1 and sys.argv[1].endswith('.md'):
        viewer.load_file(sys.argv[1])

    sys.exit(app.exec())


if __name__ == '__main__':
    main()
