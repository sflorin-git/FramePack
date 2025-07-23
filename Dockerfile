FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime

WORKDIR /app
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git ffmpeg libsm6 libxext6 libgl1 \
    pkg-config libavformat-dev libavcodec-dev libavdevice-dev libavutil-dev \
    libavfilter-dev libswscale-dev libswresample-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/lllyasviel/FramePack.git
WORKDIR /app/FramePack

RUN pip install --upgrade pip && \
    pip install gradio==5.25.2 torch torchvision torchaudio && \
    sed -i 's/gradio==5.23.0/gradio==5.25.2/g' requirements.txt && \
    pip install -r requirements.txt

RUN sed -i "s/crf': '0'}/crf': '18'}/g" diffusers_helper/utils.py || true
RUN sed -i 's/torch.backends.cuda.cudnn_sdp_enabled()/hasattr(torch.backends.cuda, "cudnn_sdp_enabled") and torch.backends.cuda.cudnn_sdp_enabled()/g' diffusers_helper/models/hunyuan_video_packed.py || true

EXPOSE 7860

CMD ["python", "demo_gradio.py", "--port", "7860"]
