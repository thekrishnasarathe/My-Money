import os
import sys
import json
import logging
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

from llm_provider import LLMProvider

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger("MoneyAIServer")

llm_provider = LLMProvider()

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

class AIServerHandler(BaseHTTPRequestHandler):
    server_version = "MoneyAIServer/2.0"

    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")

    def _send_json_response(self, status_code: int, data: dict):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?")[0].rstrip("/")
        if path == "/api/health" or path == "/health":
            status = llm_provider.get_status()
            self._send_json_response(200, status)
        elif path == "" or path == "/":
            status = llm_provider.get_status()
            self._send_json_response(200, {
                "service": "MONEY AI Financial Coach Backend",
                "version": "2.0.0",
                "status": "active",
                "provider_info": status
            })
        else:
            self._send_json_response(404, {"error": "Not found", "path": self.path})

    def do_POST(self):
        path = self.path.split("?")[0].rstrip("/")
        
        # Read and enforce max payload size (1MB)
        content_length_header = self.headers.get("Content-Length")
        if not content_length_header:
            self._send_json_response(400, {"error": "Missing Content-Length header"})
            return
        
        try:
            length = int(content_length_header)
        except ValueError:
            self._send_json_response(400, {"error": "Invalid Content-Length header"})
            return

        if length > 1024 * 1024:
            self._send_json_response(413, {"error": "Payload exceeds 1MB limit"})
            return

        try:
            raw_body = self.rfile.read(length).decode("utf-8")
            body = json.loads(raw_body) if raw_body else {}
        except json.JSONDecodeError as e:
            self._send_json_response(400, {"error": f"Malformed JSON: {str(e)}"})
            return

        # Route endpoints
        try:
            if path == "/api/ai/chat":
                message = body.get("message", "").strip()
                if not message:
                    self._send_json_response(400, {"error": "Field 'message' cannot be empty"})
                    return
                context = body.get("context", {})
                history = body.get("history", [])
                result = llm_provider.chat(message, context, history)
                self._send_json_response(200, result)

            elif path == "/api/ai/insights":
                context = body.get("context", {})
                result = llm_provider.get_insights(context)
                self._send_json_response(200, result)

            elif path == "/api/ai/savings-recommendations":
                context = body.get("context", {})
                result = llm_provider.get_savings_recommendations(context)
                self._send_json_response(200, result)

            elif path == "/api/ai/categorize":
                name = body.get("name", "").strip()
                amount = float(body.get("amount", 0.0))
                payment_method = body.get("payment_method", "UPI")
                categories = body.get("categories", [])
                result = llm_provider.categorize_transaction(name, amount, payment_method, categories)
                self._send_json_response(200, result)

            elif path == "/api/ai/summary":
                context = body.get("context", {})
                result = llm_provider.get_insights(context)
                self._send_json_response(200, result)

            elif path == "/api/ai/budget-planner":
                result = llm_provider.plan_budget(body)
                self._send_json_response(200, result)

            else:
                self._send_json_response(404, {"error": f"Endpoint '{path}' not found"})
        except Exception as e:
            logger.exception("Unhandled error processing request")
            self._send_json_response(500, {
                "error": "Internal server error occurred while processing AI request",
                "details": str(e)
            })

    def log_message(self, format, *args):
        # Format logs cleanly without printing sensitive request data
        logger.info(f"{self.client_address[0]} - {format % args}")

def run():
    parser = argparse.ArgumentParser(description="MONEY AI Coach Backend Server")
    parser.add_argument("--port", type=int, default=int(os.getenv("PORT", "5005")), help="Server port (default: 5005)")
    parser.add_argument("--host", type=str, default=os.getenv("HOST", "127.0.0.1"), help="Host address (default: 127.0.0.1)")
    args = parser.parse_args()

    port = args.port
    host = args.host
    server_address = (host, port)
    
    server = ThreadingHTTPServer(server_address, AIServerHandler)
    status = llm_provider.get_status()
    print("=" * 60)
    print("  [MONEY] AI Personal Finance Coach Backend")
    print("=" * 60)
    print(f"  * Listening on:  http://{host}:{port}")
    print(f"  * Provider:      {status['provider'].upper()}")
    print(f"  * Model:         {status['model']}")
    print(f"  * Configured:    {'YES' if status['is_configured'] else 'NO (Set GEMINI_API_KEY in server/.env)'}")
    print(f"  * CORS:          Enabled for all origins")
    print("=" * 60)
    print("  Ready to process financial coaching requests.")
    print("  Press Ctrl+C to stop.\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down AI server gracefully...")
        server.server_close()

if __name__ == "__main__":
    run()
