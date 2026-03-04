# Running the Ghibli At Home App in a Container

This step-by-step tutorial shows you how to build and run the service using Docker (and Docker Compose for convenience).

## Prerequisites

- Docker Engine installed (20.10+ recommended).
- **Optional**: NVIDIA Container Toolkit if you want GPU acceleration (`--gpus` support).
- A copy of the repository on your machine.
- A valid `.env` file created from `.env_template` in the project root.

## 1. Prepare Your Environment File

```bash
# copy the template if you haven't already
cp .env_template .env

# edit .env and set values as needed, especially:
#   - Maximum queue/upload sizes
#   - HUGGING_FACE_HUB_TOKEN (required for gated models)
#   - PYTORCH_DEVICE (optional: cuda or cpu)
```

## 2. Build the Docker Image

### CPU-only build (default)

```bash
docker build -t ghibli-at-home .
```

### GPU-enabled build

```bash
docker build \
  --build-arg BASE_IMAGE=nvidia/cuda:12.2.0-runtime-ubuntu22.04 \
  -t ghibli-at-home:gpu .
```

> 🔧 Make sure the host has the NVIDIA runtime configured (`nvidia-docker2` or similar).

## 3. Run the Container

### Basic (CPU) Run

```bash
docker run --rm -p 5000:5000 \
    --env-file .env \
    -v $(pwd)/generated_images:/app/generated_images \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    ghibli-at-home
```

### GPU Run

```bash
docker run --rm --gpus all -p 5000:5000 \
    --env-file .env \
    -v $(pwd)/generated_images:/app/generated_images \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    ghibli-at-home:gpu
```

The container listens on port `5000` by default. Use your browser to visit `http://localhost:5000` once the server is up.

> 📌 The server log will print `Initializing model...` followed by a success message. Expect a minute or two while the model downloads and loads, especially on first run.

## 4. Use Docker Compose (Alternative)

A `docker-compose.yml` file is provided in the repository for convenience.

```bash
# build and start the service
docker compose up --build
```

By default, the compose file uses a CPU base image. To switch to the GPU image edit the `build.args.BASE_IMAGE` value or supply an override file.

## 5. Persisted Data & Cleanup

- Generated images are saved to `./generated_images` on the host via a bind mount.
- The Hugging Face cache is shared with the host to avoid re‑downloading models.
- Containers are ephemeral (`--rm`), so as soon as you stop them all state is in mounted volumes.

## 6. Advanced Tips

- **Custom ports**: pass `-e PORT=5555` or modify `docker-compose.yml`.
- **Logs**: redirect container output to a file with `docker logs` or the compose `logging` section.
- **Healthcheck**: you can add a `HEALTHCHECK` to the Dockerfile pointing at `/status/`.
- **Single-worker**: remember not to change the `uvicorn --workers 1` command in `CMD`.

## 7. Troubleshooting

- **`pip` install errors**: ensure build dependencies (`build-essential`) were installed by the Dockerfile.
- **Permission denied writing to `generated_images`**: make sure the host directory exists and is writable by UID 1000 (the `appuser` inside the container).
- **CUDA errors**: verify the host GPU drivers and NVIDIA Container Toolkit are correctly configured.

You're now running the app fully containerized! Enjoy stylizing images with local AI.
