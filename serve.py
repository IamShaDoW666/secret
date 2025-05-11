import os
import http.server
import socketserver
import socket
import pyqrcode

# Define the directory containing APK files
APK_DIR = os.path.abspath("build/app/outputs/flutter-apk")
PORT = 8080  # Change this if needed

if not os.path.exists(APK_DIR):
    print(f"Error: Directory {APK_DIR} does not exist.")
    exit(1)

# Change working directory to the APK folder
os.chdir(APK_DIR)

# Set up the HTTP server
class APKRequestHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        return  # Suppress logging for cleaner output

# Get the local network IP address
def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

local_ip = get_local_ip()
server_url = f"http://{local_ip}:{PORT}"
# Generate and display QR Code
qr = pyqrcode.create(server_url)
print(qr.terminal(quiet_zone=1))
print(f"Serving APKs from {APK_DIR} at {server_url}")
print("Scan the QR code to access:")
print("Press Ctrl+C to stop the server.")

with socketserver.TCPServer(("0.0.0.0", PORT), APKRequestHandler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

