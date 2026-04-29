FROM python:3.12-slim

WORKDIR /app

# Install system dependencies including libgomp1 for ONNX
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/.u2net && chmod 777 /app/.u2net
ENV U2NET_HOME=/app/.u2net

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "5000"]
