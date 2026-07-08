# Stage 1: Build Python packages in Alpine Python image
FROM python:3.12-alpine AS python-builder

RUN pip install --no-cache-dir --root=/python-root \
    requests \
    numpy \
    pandas \
    openai \
    anthropic \
    python-dotenv \
    pyyaml \
    beautifulsoup4 \
    lxml

# Stage 2: n8n image + Python copied in
FROM n8nio/n8n:latest

USER root

# Copy Python runtime from the official Alpine Python image
COPY --from=python:3.12-alpine /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python:3.12-alpine /usr/local/bin/python3.12 /usr/local/bin/python3.12
COPY --from=python:3.12-alpine /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python:3.12-alpine /usr/local/lib/libpython3.12.so* /usr/local/lib/

# Copy installed Python packages (from the builder stage)
COPY --from=python-builder /python-root /usr/local

# Make sure Python shared library is discoverable
ENV LD_LIBRARY_PATH=/usr/local/lib

USER node