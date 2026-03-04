# syntax=docker/dockerfile:1

# ARG allows building either a CPU or GPU variant by specifying a different base image.
# Default is a slim Python image for CPU-only use.
ARG BASE_IMAGE=python:3.12-slim-bullseye
FROM ${BASE_IMAGE} as base

# Standard environment settings to keep containers lean and reproducible
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TMPDIR=/tmp

# Work directory
WORKDIR /app

# Install minimal system dependencies required by the Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libgl1 && \
    rm -rf /var/lib/apt/lists/*

# Copy package metadata first to leverage Docker cache
COPY pyproject.toml uv.lock* ./

# Install dependencies; using the project package itself pulls in
# all the runtime requirements declared in pyproject.toml
# disable cache to lower disk usage during install and avoid temporary file I/O errors
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN pip install --upgrade pip && \
    python -m pip install --no-cache-dir .

# Copy the rest of the application code and static assets
COPY . .

# Create a non-root user for security
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

# Expose default port used by the application
EXPOSE 5000

# The recommended production command; a single worker must be used
# Uvicorn runs the ASGI-wrapped Flask app defined as `asgi_app` in app.py
CMD ["uvicorn", "app:asgi_app", "--host", "0.0.0.0", "--port", "5000", "--workers", "1"]
