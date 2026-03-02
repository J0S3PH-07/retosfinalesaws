from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "message": "Hello from Reto 3!",
        "host": socket.gethostname(),
        "project": os.getenv("PROJECT", "reto3"),
    })

@app.route("/health")
def health():
    """Health check endpoint used by ALB and ECS."""
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
