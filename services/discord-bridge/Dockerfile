FROM python:3.13-slim
RUN pip install --no-cache-dir "discord.py==2.*" "httpx==0.28.*"
WORKDIR /app
COPY bridge.py .
USER 1000:1000
CMD ["python", "-u", "bridge.py"]
