FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PATH="/opt/venv/bin:$PATH"

WORKDIR /app
RUN useradd -m appuser && chown -R appuser:appuser /app

# Upgrade pip in the virtual environment
RUN pip install --no-cache-dir --upgrade pip setuptools wheel>=0.46.2 jaraco.context>=6.1.0

# ---------------------------------------------------------
# BUILDER STAGE
# ---------------------------------------------------------
FROM base AS builder

RUN python -m venv /opt/venv


# With standard pip and pyproject.toml, pip needs the source code (e.g., your src/ dir)
# alongside the toml file to build the package. 
COPY . .

# Install the project and its production dependencies (defined in [project.dependencies])
RUN pip install --no-cache-dir .

# ---------------------------------------------------------
# DEVELOPMENT STAGE
# ---------------------------------------------------------
FROM base AS development

COPY --from=builder /opt/venv /opt/venv

# Copy the source code and pyproject.toml
COPY . .

# Install the extra development dependencies defined in [project.optional-dependencies]
# Note: If you mount your local code via Docker volumes (e.g., docker-compose), 
# you might want to change this to an editable install: pip install --no-cache-dir -e ".[dev]"
RUN pip install --no-cache-dir ".[dev]"

# Ensure the appuser owns everything we just copied over
RUN chown -R appuser:appuser /app

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ---------------------------------------------------------
# PRODUCTION STAGE
# ---------------------------------------------------------
FROM base AS production

# Copy the venv from builder (which ONLY contains production dependencies)
COPY --from=builder /opt/venv /opt/venv

# Copy your application source code securely
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]


# FROM python:3.11-slim AS base

# ENV PYTHONDONTWRITEBYTECODE=1 \
#     PYTHONUNBUFFERED=1 \
#     PATH="/opt/venv/bin:$PATH"

# WORKDIR /app
# RUN useradd -m appuser && chown -R appuser:appuser /app

# FROM base AS builder
# #RUN apt-get update && apt-get install -y --no-install-recommends build-essential gcc && rm -rf /var/lib/apt/lists/*

# RUN python -m venv /opt/venv
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt


# FROM base AS development

# COPY --from=builder /opt/venv /opt/venv

# COPY requirements-dev.txt .
# RUN pip install --no-cache-dir -r requirements-dev.txt

# COPY --chown=appuser:appuser . .
# USER appuser
# EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#   CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]


# FROM base AS production
# COPY --from=builder /opt/venv /opt/venv
# COPY --chown=appuser:appuser . .
# USER appuser
# EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#   CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]