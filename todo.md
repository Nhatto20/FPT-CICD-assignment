# Task 3: Implement Multi-stage Build

## Objectives

- [x] **1. Create a multi-stage Dockerfile**
  - [x] Create a `builder` stage: Install build dependencies and compile/install packages.
  - [x] Create a `runtime` stage: Copy only necessary artifacts from the builder to keep the final image minimal.

- [x] **2. Compare image sizes**
  - [x] Build the single-stage image (if you have a previous Dockerfile) and note its size.
  - [x] Build the new multi-stage production image and note its size.
  - [x] Fill out the comparison table in your notes/report:
    | Stage | Image Size |
    |-------|------------|
    | Single-stage | 208 MB |
    | Multi-stage | 209 MB |

- [x] **3. Implement build targets for different environments**
  - [x] Define a `development` target: Should include the runtime requirements PLUS dev tools like `pytest` and `ruff`.
  - [x] Define a `production` target: Should be a minimal runtime containing only the application and production dependencies.

- [x] **4. Build specific targets**
  - [x] Build the dev image: `wsl -d Debian docker build --target development -t myapp:dev .`
  - [x] Build the prod image: `wsl -d Debian docker build --target production -t myapp:prod .`

## Notes
- Docker is installed in WSL under the `Debian` distribution. If you are running commands from Windows PowerShell or CMD, you need to prefix them with `wsl -d Debian`. If you are inside the WSL Debian terminal, you can just run `docker build ...`.
- Keep an eye on `requirements.txt`. If you need separate dependencies for dev, you might install `pytest` and `ruff` directly in the `development` stage via pip, or use a `requirements-dev.txt` if you have one.

# Task 4: Implement Security Best Practices

## Objectives

- [x] **1. Create a non-root user and run the container as that user**
- [x] **2. Create a .dockerignore file excluding:**
  - [x] `.git`, `__pycache__`, `.venv`
  - [x] Test files and documentation
  - [x] Environment files (`.env`)
- [x] **3. Add a HEALTHCHECK instruction to monitor application health**
- [x] **4. Scan the image for vulnerabilities using Docker Scout or Trivy:**
  - [x] `docker scout cves myapp:prod` OR `trivy image myapp:prod`
- [x] **5. Document any vulnerabilities found and mitigation strategies**

# Task 5: Volume and Port Configuration

## Objectives

- [x] **1. Configure volumes for:**
  - [x] Persistent data storage
  - [x] Configuration files (read-only)
- [x] **2. Document port mapping requirements**
- [x] **3. Create a docker-compose.yml for local development that includes:**
  - [x] Volume mounts for hot-reload
  - [x] Environment variable configuration
  - [x] Health check configuration
