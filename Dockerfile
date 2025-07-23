FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime

# Sätt miljövariabler för icke-interaktiv installation och rätt tidszon
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Stockholm

WORKDIR /app

# Installera systemberoenden och klona repo
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git ffmpeg libsm6 libxext6 libgl1 \
    pkg-config libavformat-dev libavcodec-dev libavdevice-dev libavutil-dev \
    libavfilter-dev libswscale-dev libswresample-dev tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    git clone https://github.com/lllyasviel/FramePack.git

WORKDIR /app/FramePack

# Installera Python-paket, patcha beroenden
RUN pip install --upgrade pip && \
    pip install --no-cache-dir gradio==5.25.2 torch torchvision torchaudio && \
    sed -i 's/gradio==5.23.0/gradio==5.25.2/g' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt && \
    sed -i "s/crf': '0'}/crf': '18'}/g" diffusers_helper/utils.py || true && \
    sed -i 's/torch.backends.cuda.cudnn_sdp_enabled()/hasattr(torch.backends.cuda, "cudnn_sdp_enabled") and torch.backends.cuda.cudnn_sdp_enabled()/g' diffusers_helper/models/hunyuan_video_packed.py || true

EXPOSE 7860

# (Valfritt) Lägg till Healthcheck
HEALTHCHECK --interval=60s --timeout=3s \
  CMD wget --spider -q http://localhost:7860/ || exit 1

CMD ["python", "demo_gradio.py", "--port", "7860"]
