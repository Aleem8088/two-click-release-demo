"""Tiny sample service used to demonstrate the CI/CD pipeline.

The pipeline bakes the git commit SHA into the image as APP_VERSION, so the
smoke test can prove that the *new* revision is the one serving traffic.
"""

import os

from flask import Flask, jsonify

app = Flask(__name__)


def _version() -> str:
    return os.environ.get("APP_VERSION", "dev")


def _environment() -> str:
    return os.environ.get("APP_ENV", "local")


@app.get("/")
def index():
    return jsonify(service="two-click-demo", version=_version(), environment=_environment())


@app.get("/health")
def health():
    return jsonify(status="ok", version=_version())
