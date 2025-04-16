# Stage 1: Base image
FROM ubuntu:18.04 as base

ENV DEBIAN_FRONTEND noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.8 python3.8-dev python3-pip python3-setuptools \
        python3.8-distutils python3.8-venv \
        ca-certificates git wget vim cmake ninja-build build-essential curl \
        libjpeg-dev libpng-dev x11-apps v4l-utils unzip \
        rsync ffmpeg psmisc libcairo2-dev libgif-dev libpango1.0-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3.8 /usr/bin/python

# Stage 2: Python environment setup
FROM base as python

WORKDIR /opt
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Create and activate virtual environment
RUN python3.8 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install pip packages using pre-compiled wheels
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch CPU version
RUN pip install --no-cache-dir torch==1.8.1+cpu torchvision==0.9.1+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install core scientific packages
RUN pip install --no-cache-dir \
    numpy==1.19.5 \
    scipy==1.5.4 \
    matplotlib==3.3.4 \
    scikit-learn==0.24.2 \
    scikit-image==0.17.2

# Install computer vision packages
RUN pip install --no-cache-dir \
    opencv-contrib-python==4.5.5.62 \
    kornia==0.6.2 \
    shapely==1.8.0 \
    Pillow==8.4.0  # Specific version for detectron2 compatibility

# Install development and utility packages first
RUN pip install --no-cache-dir \
    tensorboard==2.8.0 \
    jupyter==1.0.0 \
    ninja==1.10.2.3 \
    pytest==6.2.5 \
    typing==3.7.4.3 \
    future==0.18.2

# Install pycocotools with all dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3.8-dev \
    python3.8-distutils \
    python3.8-venv \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir cython==0.29.28 \
    && git clone https://github.com/philferriere/cocoapi.git \
    && cd cocoapi/PythonAPI \
    && python setup.py build_ext install \
    && cd ../.. \
    && rm -rf cocoapi

# Install graphics and visualization packages
RUN pip install --no-cache-dir \
    pycairo==1.20.1 \
    glfw==2.5.5 \
    ipympl==0.8.8 \
    pyrr==0.10.3 \
    future-fstrings==1.2.0 \
    PyOpenGL==3.1.6 \
    PyOpenGL-accelerate==3.1.6 \
    plyfile==0.7.4

# Stage 3: Final image
FROM python

ENV PATH="/opt/venv/bin:$PATH"
ENV FORCE_CPU="1"
ENV FVCORE_CACHE="/tmp"

# Install detectron2
RUN git clone https://github.com/facebookresearch/detectron2 detectron2_repo \
    && cd detectron2_repo && git checkout "v0.6" \
    && pip install -e .

WORKDIR /