#!/usr/bin/env python3
"""
Lumen-OS Local UI Simulator Server
Serves the 1280x720 interactive simulator and live assets locally on macOS.
"""

import http.server
import os
import socketserver
import sys
import urllib.parse
import webbrowser

PORT = 8765
DIRECTORY = "/Users/dibble/Documents/GitHub/lumen-os"

class SimulatorHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def translate_path(self, path):
        parsed = urllib.parse.urlparse(path)
        clean = parsed.path
        if clean == "/" or clean == "":
            clean = "/tools/simulator/index.html"
        return super().translate_path(clean)

def start_server():
    os.chdir(DIRECTORY)
    with socketserver.TCPServer(("", PORT), SimulatorHandler) as httpd:
        url = f"http://localhost:{PORT}"
        print(f"=== Lumen-OS Lumen UI Simulator Running at {url} ===")
        print("Press Ctrl+C to stop the server.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down simulator server.")

if __name__ == "__main__":
    start_server()
