# ACE-Step Docker Image

This repository builds a Docker image that installs and runs ACE-Step (from the upstream GitHub repository) on top of a minimal Debian base.

Key goals:

- Base image: `debian:stable-slim` (small, auditable)
- Install ACE-Step from the upstream GitHub repo (configurable at build time)
- Provide a default entrypoint that shows ACE-Step help when no args are supplied
- Run as a non-root user (`aceuser`) where possible
- Clean up build artifacts to keep the image small

## Files in this repository

- `Dockerfile` - builds the container image (based on `debian:stable-slim`)
- `entrypoint.sh` - entrypoint which shows `acestep --help` by default and forwards args
- `requirements.txt` - minimal build helpers (setuptools/wheel)

## Build

From the repository root, build the image:

```powershell
docker build -t ace-step .
```

Build-time arguments:

- `ACE_STEP_REF` (default: `main`) — branch, tag or commit to clone from https://github.com/ace-step/ACE-Step
- `TORCH_INDEX` (default: CPU index): URL used to install PyTorch wheels (the Dockerfile installs CPU wheels by default)

Examples:

Pin ACE-Step to a tag (replace `vX.Y.Z` with the desired tag):

```powershell
docker build --build-arg ACE_STEP_REF=vX.Y.Z -t ace-step:vX.Y.Z .
```

If you want GPU support, build similarly but point `TORCH_INDEX` at the appropriate CUDA wheel index (or install CUDA-enabled PyTorch in a later step). See the PyTorch site for the exact wheel URLs for your CUDA version.

## Run

Run the container with no arguments to show ACE-Step help (this is the default behavior):

```powershell
docker run --rm ace-step
```

Pass flags directly (they will be forwarded to the `acestep` console script):

```powershell
docker run --rm ace-step --version
docker run --rm ace-step -h
```

Run a shell inside the container (for debugging):

```powershell
docker run --rm -it ace-step bash
```

Mount a host directory to work with local files (example for Windows PowerShell):

```powershell
docker run --rm -v C:\\path\\to\\data:/data -w /data ace-step acestep analyze input.json
```

To run as root (if needed):

```powershell
docker run --rm --user root -it ace-step bash
```

## Dependencies and notes

- Python: ACE-Step requires Python 3.10+. The base Debian image provides `python3` (recent stable). The Dockerfile uses system python and installs ACE-Step system-wide via `pip`.
- PyTorch: ACE-Step depends on PyTorch. By default this Dockerfile installs CPU PyTorch wheels using the official PyTorch wheel index for CPU. For GPU support you must install CUDA-enabled wheels that match your host GPU drivers and CUDA version (see https://pytorch.org/get-started/locally/).
- System libs: FFmpeg and libsndfile are installed to support audio I/O.

If you need a different PyTorch configuration (e.g. a CUDA-enabled wheel), build with a different `TORCH_INDEX` or modify the Dockerfile to install the exact wheel matching your CUDA version.

## Entrypoint and runtime behavior

- `entrypoint.sh` is the container's entrypoint. Behavior:
	- No args: runs `acestep --help`
	- If the first arg begins with `-`, it forwards args to `acestep` (so `docker run ace-step --port 7865` runs ACE-Step)
	- Otherwise it executes the provided command (so `docker run ace-step bash` will open a shell)

ACE-Step's console script is installed as `acestep` by the upstream packaging. If you find a different console script name in the future, update `entrypoint.sh` accordingly.

## Volumes, checkpoints and persistent storage

ACE-Step downloads or stores model checkpoints by default under `~/.cache/ace-step/checkpoints` (upstream behaviour). To persist model data between runs, mount a host directory:

```powershell
docker run --rm -v C:\\ace-step-cache:/home/aceuser/.cache ace-step acestep --checkpoint_path /home/aceuser/.cache/checkpoints
```

## Troubleshooting

- If `acestep` is not found after running the image, run a shell in the container to inspect installed packages:

```powershell
docker run --rm -it ace-step bash
# inside container: which acestep || python3 -m pip show ace-step
```

## Security

- The image runs as a non-root user (`aceuser`) by default for safer operation. If ACE-Step needs elevated privileges for specific tasks, run with `--user root` or adjust permissions carefully.

## Notes

This repository follows the upstream project's install instructions: cloning the repo and installing via `pip install -e .`. If upstream packaging changes, the Dockerfile may require adjustments.

If you'd like, I can also:
- pin ACE-Step to a specific release tag by default
- add an automated self-check that runs `acestep --version` during build

---
Generated: Dockerfile based on `debian:stable-slim` that installs ACE-Step and CPU PyTorch wheels (changeable via build args).

