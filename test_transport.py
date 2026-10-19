"""Exercise the real C# HTTP client against a local test server."""
import http.server
import json
import os
import pathlib
import subprocess
import threading
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_POST(self):
        self.rfile.read(int(self.headers.get('Content-Length', 0)))
        if self.path == '/slow':
            time.sleep(2)
        if self.path == '/redirect':
            self.send_response(302)
            self.send_header('Location', 'http://example.org/forbidden')
            self.end_headers()
            return
        content = 'Test.'
        if self.path == '/empty':
            content = ''
        response = {'choices': [{'message': {'content': content},
                                 'finish_reason': 'length' if self.path == '/truncated' else 'stop'}]}
        if self.path == '/missing':
            response = {'choices': []}
        body = b'not-json' if self.path == '/malformed' else json.dumps(response).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass

if __name__ == '__main__':
    with http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        env = dict(os.environ, SB_TEST_URL=f'http://127.0.0.1:{server.server_port}')
        code = subprocess.call([str(ROOT / 'dist' / 'ScholarBridge.exe'), '--transport-test'], env=env)
        server.shutdown()
    print((ROOT / 'artifacts' / 'transport-test.txt').read_text(encoding='utf-8-sig'))
    raise SystemExit(code)
