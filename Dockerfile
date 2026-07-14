# =====================================================================
# n8n Custom Image — Codespaces-optimized
# =====================================================================
# Single-stage build on top of the official n8n image.
# Python is NOT included because the workflow uses only JavaScript
# Code nodes (jsCode). If you ever add pyCode nodes, uncomment the
# block at the bottom to re-enable Python support.
# =====================================================================

FROM n8nio/n8n:latest

# n8n runs as the "node" user by default — no need to switch to root.
# The base image already contains everything n8n needs to run.

# ---------------------------------------------------------------------
# If you ever need Python for pyCode nodes, uncomment this block:
# ---------------------------------------------------------------------
# USER root
# RUN apk add --no-cache python3 py3-pip ca-certificates && \
#     update-ca-certificates
# USER node