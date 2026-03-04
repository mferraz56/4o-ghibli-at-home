import os
import time

import pytest
import httpx
from testcontainers.core.container import DockerContainer


@pytest.mark.skipif(
    os.getenv("CI") and not os.getenv("DOCKER_HOST"),
    reason="Docker not available in this environment",
)
def test_app_status_endpoint():
    """Builds the image, runs a container and ensures /status returns 200."""

    # build the image using the same Dockerfile in the repo root
    image_tag = "ghibli-at-home:test"
    client = DockerContainer("python:3.12-slim-bullseye")
    # we will simply use the command-line docker build instead of python API for simplicity
    os.system(f"docker build -t {image_tag} .")

    with DockerContainer(image_tag) as container:
        container.with_bind_ports(5000, 5000)
        container.start()
        # wait for the server to start
        time.sleep(5)
        response = httpx.get("http://localhost:5000/status/some-id")
        # we expect 404 for unknown job but the server should reply
        assert response.status_code in (200, 404)
