
from flask import Flask, Response, jsonify, render_template_string
import pyautogui, cv2, numpy as np, time
import threading
import socket
from zeroconf import Zeroconf, ServiceInfo
import platform
from aiortc import VideoStreamTrack, RTCPeerConnection

app = Flask(__name__)

zeroconf = None
service_info = None
mirror_running = False

# ————— SCREEN MIRROR STREAMING FUNCTION —————
def generate():
    global mirror_running
    while mirror_running:
        screenshot = pyautogui.screenshot()
        frame = cv2.cvtColor(np.array(screenshot), cv2.COLOR_BGR2RGB)
        ret, buffer = cv2.imencode('.jpg', frame)
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + buffer.tobytes() + b'\r\n')
        time.sleep(1 / 30)  # 30 FPS
    
@app.route('/mirror')
def mirror():
    global mirror_running
    if not mirror_running:
        return "Mirror is stopped. Start the server to view the stream.", 403
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')


def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def register_mdns_service(port=5000):
    global zeroconf, service_info
    local_ip = get_local_ip()
    hostname = platform.node()
    service_name = f"{hostname}-PCMirrorServer._http._tcp.local."
    service_info = ServiceInfo(
        "_http._tcp.local.",
        service_name,
        addresses=[socket.inet_aton(local_ip)],
        port=port,
        properties={'path': '/mirror'},
        server=f"{hostname}.local.",
    )
    zeroconf = Zeroconf()
    zeroconf.register_service(service_info)
    print(f"✅ mDNS service registered at {local_ip}:{port}/mirror")

def unregister_mdns_service():
    global zeroconf, service_info
    if zeroconf and service_info:
        zeroconf.unregister_service(service_info)
        zeroconf.close()
        zeroconf = None
        service_info = None
        print("🛑 mDNS service unregistered")

# ===================== FLASK MAIN UI + API ======================
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>CastSpot</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</head>
<body class="bg-white p-4 font-sans">
  <div class="text-center mb-4">
    <h1 class="text-xl font-bold">CastSpot</h1>
    <p class="text-sm">Choose Your Mirroring Direction</p>
  </div>

  <div class="space-y-6">
    <div class="bg-white rounded-lg shadow p-4">
      <img src="https://via.placeholder.com/300x150" class="rounded mb-2">
      <h2 class="text-lg font-semibold">Mirror PC to Phone</h2>
      <p class="text-sm mb-2 text-gray-600">Control your computer on your mobile device for presentations or remote access.</p>
      <button id="toggleServer" class="bg-blue-500 text-white px-4 py-1 rounded hover:bg-blue-600">Start Server</button>
    </div>
  </div>

  <script>
    let serverRunning = false;

    async function checkStatus() {
        const res = await fetch('/status');
        const data = await res.json();
        serverRunning = data.running;
        updateButton();
    }

    function updateButton() {
        const btn = document.getElementById("toggleServer");
        btn.textContent = serverRunning ? "Stop Server" : "Start Server";
        btn.className = serverRunning 
        ? "bg-red-500 text-white px-4 py-1 rounded hover:bg-red-600"
        : "bg-blue-500 text-white px-4 py-1 rounded hover:bg-blue-600";
    }

    document.getElementById("toggleServer").addEventListener("click", async () => {
        const action = serverRunning ? "stop" : "start";
        const confirm = await Swal.fire({
        title: `${action === "start" ? "Start" : "Stop"} Mirroring?`,
        text: `Are you sure you want to ${action} the server?`,
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: `Yes, ${action}`,
        });

        if (confirm.isConfirmed) {
        await fetch(`/${action}_server`, { method: "POST" });
        await checkStatus();
        Swal.fire("Done", `Server ${action}ed`, "success");
        }
    });

    checkStatus();
  </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/start_server', methods=['POST'])
def start_server():
    global mirror_running
    if not mirror_running:
        register_mdns_service(port=5000)
        mirror_running = True
    return jsonify({"status": "started"})

@app.route('/stop_server', methods=['POST'])
def stop_server():
    global mirror_running
    if mirror_running:
        unregister_mdns_service()
        mirror_running = False
    return jsonify({"status": "stopped"})

@app.route('/status')
def status():
    return jsonify({"running": mirror_running})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
