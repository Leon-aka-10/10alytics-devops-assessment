import os
import logging
from flask import Flask, jsonify

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)


@app.route("/")
def home():
    env = os.environ.get("ENVIRONMENT", "unknown")
    return jsonify({"message": "10Alytics DevOps API", "environment": env})


@app.route("/health")
def health():
    """
    Health endpoint for Azure App Service health checks and pipeline verification.
    Returns 200 if the app is running and DB config is present.
    Returns 503 if a critical dependency is misconfigured.
    """
    checks = {}
    status_code = 200

    db_conn = os.environ.get("DB_CONNECTION_STRING")
    if db_conn:
        checks["database"] = "configured"
    else:
        checks["database"] = "not configured"
        status_code = 503
        logger.warning("DB_CONNECTION_STRING is not set")

    return jsonify({
        "status": "ok" if status_code == 200 else "degraded",
        "checks": checks,
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
    }), status_code


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=False)