FROM debian:stable-slim

ARG ACE_STEP_REF=main
ARG TORCH_INDEX="https://download.pytorch.org/whl/cpu"
ARG PYTHON_BIN=python3

ENV DEBIAN_FRONTEND=noninteractive \
	ACE_STEP_HOME=/opt/ACE-Step

# Install system deps, Python, and build tools; install ACE-Step and clean up to reduce image size.
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		git \
		ffmpeg \
		libsndfile1 \
		libsndfile1-dev \
		build-essential \
		bzip2 \
	; \
	# Clone ACE-Step first
	git clone --depth 1 --branch "${ACE_STEP_REF}" https://github.com/ace-step/ACE-Step.git ${ACE_STEP_HOME}; \
	# Install Miniforge (lightweight conda) and create Python 3.10 env to satisfy ACE-Step pinned deps
	curl -sSL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh; \
	bash /tmp/miniforge.sh -b -p /opt/conda; \
	rm -f /tmp/miniforge.sh; \
	/opt/conda/bin/conda create -y -n ace python=3.10 pip; \
	/opt/conda/bin/conda clean -afy; \
	# Install packages inside the conda env
	/opt/conda/bin/conda run -n ace pip install --no-cache-dir --upgrade pip setuptools wheel; \
	/opt/conda/bin/conda run -n ace pip install --no-cache-dir "torch>=2.2.0" --index-url ${TORCH_INDEX}; \
	/opt/conda/bin/conda run -n ace pip install --no-cache-dir -e ${ACE_STEP_HOME}; \
	# Cleanup build deps and apt lists to reduce image size
	apt-get purge -y --auto-remove build-essential bzip2; \
	rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache/pip

ENV PATH="/opt/conda/envs/ace/bin:/opt/conda/bin:$PATH"

# Create a non-root user and set up permissions
RUN useradd --create-home --shell /bin/bash --uid 1000 aceuser \
	&& chown -R aceuser:aceuser ${ACE_STEP_HOME}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/aceuser
USER aceuser

ENTRYPOINT ["/entrypoint.sh"]
CMD []
