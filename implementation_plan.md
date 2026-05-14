
# Implementation Plan: Shift to New Project Requirements

## Quick Summary of the Shift

| Dimension | Old Project | New Project |
|-----------|------------|-------------|
| **Focus** | Generic CI/CD learning tasks (5 tasks, point-based) | One complete, graded assignment with real-world depth |
| **App** | Generic Python app (Flask/any) | **FastAPI** specifically |
| **Code Quality** | Ruff + Black linting only | **SonarQube** quality gate (mandatory, blocks deployment) |
| **Image Scanning** | Trivy (optional/additive) | Trivy **remains**, but SonarQube is the new gating concern |
| **Python Version** | Matrix: 3.10, 3.11, 3.12 | **3.11+** minimum (matrix optional but 3.11 required) |
| **Deployment** | staging auto + production manual (simple `docker run`) | **Blue-Green** strategy with rollback |
| **Multi-stage Docker** | Already done ✅ | Required — already satisfies this |
| **Codecov** | Required (Task 3) | **Not mentioned** — can drop |
| **`sonar-project.properties`** | Not present | **Required** with coverage report integration |

---

## Gap Analysis: What to Keep, Change, Remove, Add

### ✅ KEEP (Already Satisfies New Requirements)

| Item | File | Why It's Kept |
|------|------|--------------|
| FastAPI application | `src/app.py` | Already FastAPI — requirement met |
| Multi-stage Dockerfile | `Dockerfile` | Already multi-stage with non-root user + health check |
| `.dockerignore` | `.dockerignore` | Already exists |
| `HEALTHCHECK` in Dockerfile | `Dockerfile` | Required by new spec |
| Lint stage in CI | `ci.yml` (lint job) | New spec requires lint stage |
| Test stage in CI | `ci.yml` (test job) | New spec requires test stage |
| Docker build + push | `docker.yml` | New spec requires build stage |
| Trivy scan | `docker.yml` | New spec requires scan stage |
| `pyproject.toml` (Python ≥3.11) | `pyproject.toml` | Already `requires-python = ">=3.11"` |
| Existing unit tests | `test/test_app.py` | Required — tests must exist |
| `scripts/deploy.sh` | `scripts/deploy.sh` | Basis for new deployment strategy |

---

### ✏️ MODIFY (Exists but Needs Changes)

#### 1. `Dockerfile` — Minor Update
- **Change**: Pin base image from `python:3.13-slim` → `python:3.11-slim` (new spec says "3.11 or higher"; using 3.11 is safest for grading consistency)
- **Change**: Ensure the production stage is the **default** build target (either set `target: production` as default or ensure CI uses `--target production`)

#### 2. `.github/workflows/ci.yml` — Major Changes
- **Remove**: Codecov integration (not required by new spec, adds complexity)
- **Remove**: Commented-out duplicate code (lines 87–143 dead code)
- **Remove**: Matrix OS testing (`macos-latest`) — new spec only mandates the pipeline works; cross-OS matrix is overhead not specified
- **Add**: **SonarQube scan job** as a mandatory gate between `test` and deployment
- **Modify**: Coverage command — ensure it outputs `coverage.xml` correctly (needed by SonarQube)
- **Modify**: Job order: `lint` → `test` → `sonarqube` → (triggers docker.yml)

#### 3. `.github/workflows/docker.yml` — Moderate Changes
- **Modify**: Workflow trigger — should only fire after CI (including SonarQube gate) passes, not on raw push
- **Option A**: Use `workflow_run` depending on the new unified CI
- **Option B**: Merge all stages into one pipeline file

#### 4. `.github/workflows/deploy.yml` — Major Rewrite
- **Remove**: Simple `docker stop` + `docker run` approach (not Blue-Green/Canary)
- **Add**: Blue-Green deployment logic:
  - Run new container on an alternate port/name (`blue`/`green` slot)
  - Health check the new slot before switching traffic
  - Tear down old slot only after successful health check
  - Rollback: if health check fails, keep old slot running
- **Modify**: Remove commented-out dead code (lines 98–201)

#### 5. `docker-compose.yml` — Moderate Update
- **Add**: SonarQube service for local development (so the developer can run SonarQube locally)
- **Modify**: Add a `sonarqube` and `sonar-db` service to support local analysis

#### 6. `scripts/deploy.sh` — Rewrite
- **Replace** simple pull-stop-run pattern with **Blue-Green logic**:
  - Determine active slot (blue or green)
  - Start new container on inactive slot
  - Health check new slot
  - Switch traffic (update port mapping or reverse proxy config)
  - Stop old slot
  - Handle rollback on failure

#### 7. `pyproject.toml` — Minor
- **Add** `pytest-cov` to dev dependencies explicitly (it's installed ad-hoc in CI, should be declared)
- Optionally add `sonarqube-client` or just rely on the SonarQube GitHub Action

---

### ❌ REMOVE

| Item | File | Reason |
|------|------|--------|
| Codecov integration | `ci.yml` line 78–85 | Not required in new spec |
| All commented-out dead code | `ci.yml` lines 87–143, `deploy.yml` lines 98–201 | Cleanup — dead weight |
| macOS matrix runner | `ci.yml` line 39 | Not required, wastes CI minutes |
| Python 3.12 matrix | `ci.yml` line 40 | New spec says "3.11 or higher" — single version is fine |

---

### ➕ ADD (New — Does Not Exist Yet)

#### 1. `sonar-project.properties` *(NEW FILE — Required)*
```properties
sonar.projectKey=fastapi-cicd
sonar.projectName=FastAPI CI/CD Pipeline
sonar.sources=src
sonar.tests=test
sonar.python.coverage.reportPaths=coverage.xml
sonar.python.version=3.11
sonar.exclusions=**/migrations/**,**/__pycache__/**
```

#### 2. SonarQube Scan Job in CI *(NEW JOB in `ci.yml`)*
```yaml
sonarqube:
  name: SonarQube Analysis
  needs: test
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v5
      with:
        fetch-depth: 0  # Required for SonarQube blame info
    - name: Download coverage report
      uses: actions/download-artifact@v4
      with:
        name: coverage-ubuntu-latest-py3.11
    - name: SonarQube Scan
      uses: SonarSource/sonarqube-scan-action@v5
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    - name: SonarQube Quality Gate Check
      uses: SonarSource/sonarqube-quality-gate-action@v1
      timeout-minutes: 5
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

#### 3. Blue-Green Deployment Script *(REWRITE `scripts/deploy.sh`)*
Logic:
- Detect active slot via a label or port check
- Spin up new container in inactive slot
- Poll `/health` endpoint until healthy (timeout)
- On success: stop old slot
- On failure: stop new slot, keep old slot (rollback)

#### 4. Updated `deploy.yml` with Blue-Green Jobs
The deploy workflow needs to execute `deploy.sh` with the Blue-Green logic instead of simple `docker run`.

#### 5. SonarQube in `docker-compose.yml` *(LOCAL DEV)*
```yaml
sonarqube:
  image: sonarqube:community
  ports:
    - "9000:9000"
  environment:
    - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
  volumes:
    - sonarqube_data:/opt/sonarqube/data
    - sonarqube_logs:/opt/sonarqube/logs
```

#### 6. GitHub Secrets to Configure
| Secret | Value |
|--------|-------|
| `SONAR_TOKEN` | Token from SonarQube instance |
| `SONAR_HOST_URL` | URL of SonarQube (e.g., `http://localhost:9000` or hosted URL) |
| `GITHUB_TOKEN` | Already auto-provided by GitHub |

---

## Phased Implementation Plan

### Phase 1 — Cleanup & Foundation (Low Risk)
**Goal**: Clean up existing files without breaking anything.

1. **Remove dead commented-out code** from `ci.yml` (lines 87–143) and `deploy.yml` (lines 98–201)
2. **Remove Codecov step** from `ci.yml`
3. **Remove macOS matrix** — keep only `ubuntu-latest` with `python-version: ["3.11"]`
4. **Fix pytest coverage path**: change `--cov=app` → `--cov=src` to match actual source directory
5. **Update `pyproject.toml`**: add `pytest-cov` explicitly to `[project.optional-dependencies.dev]`

**Files touched**: `ci.yml`, `deploy.yml`, `pyproject.toml`
**Risk**: Low — purely subtractive

---

### Phase 2 — SonarQube Integration
**Goal**: Satisfy the mandatory quality gate requirement.

1. **Create `sonar-project.properties`** in project root
2. **Add `sonarqube` job** to `ci.yml` after the `test` job
3. **Add `quality-gate` check** step — this is what blocks deployment on failure
4. **Update `docker.yml` trigger**: change from `on: push` → `on: workflow_run` depending on CI passing (so SonarQube gate prevents Docker build from proceeding if quality gate fails)
5. **Update `docker-compose.yml`**: add SonarQube + postgres services for local dev
6. **Add GitHub Secrets**: `SONAR_TOKEN`, `SONAR_HOST_URL` (document in README)

**Files touched**: `sonar-project.properties` (new), `ci.yml`, `docker.yml`, `docker-compose.yml`
**Risk**: Medium — requires a live SonarQube instance

---

### Phase 3 — Blue-Green Deployment
**Goal**: Replace naive `docker run` deployment with Blue-Green strategy.

1. **Rewrite `scripts/deploy.sh`**:
   - Accept `IMAGE_TAG` and `SLOT` (blue/green) as arguments
   - Start new container on designated slot
   - Poll `/health` with retry logic
   - On success: stop old slot, print deployment success
   - On failure: stop new slot, exit with error (triggers rollback)
2. **Update `deploy.yml`**:
   - Determine active/inactive slot before deploy
   - Pass correct slot to `deploy.sh`
   - Add rollback step triggered on failure
3. **Port mapping for Blue-Green** (local setup):
   - Blue: port `8000`
   - Green: port `8001`
   - A simple Nginx or port-switch approach to route traffic

**Files touched**: `scripts/deploy.sh`, `deploy.yml`
**Risk**: Medium-High — requires careful port management

---

### Phase 4 — Validation & Documentation
**Goal**: End-to-end pipeline works and is documented.

1. **Test full pipeline**: push to `develop` → CI lint → test → SonarQube → Docker build → Deploy staging (Blue-Green)
2. **Test rollback**: simulate a broken image and verify old slot stays alive
3. **Update `README.md`**: document:
   - How to run SonarQube locally (docker-compose)
   - How to configure secrets
   - Blue-Green deployment explanation
4. **Clean up scan artifacts** (`multistage-scan.txt`) — move to a `reports/` dir or remove

**Files touched**: `README.md`
**Risk**: Low

---

## Pipeline Architecture (After Changes)

```
Push to develop/main
        │
        ▼
   ┌─────────┐
   │  lint   │  (Ruff + Black)
   └────┬────┘
        │ passes
        ▼
   ┌─────────┐
   │  test   │  (pytest + coverage.xml)
   └────┬────┘
        │ passes
        ▼
   ┌──────────────┐
   │  sonarqube   │  ← NEW — MANDATORY GATE
   │ quality gate │
   └──────┬───────┘
          │ passes (quality gate green)
          ▼
   ┌───────────────┐
   │ docker build  │  (multi-stage, production target)
   │  + push GHCR  │
   └───────┬───────┘
           │
           ▼
   ┌──────────────┐
   │  trivy scan  │  (HIGH/CRITICAL — exit 1 on fail)
   └──────┬───────┘
          │ clean
          ▼
   ┌──────────────────────────┐
   │  deploy (Blue-Green)     │  ← REWRITTEN
   │  staging (auto, develop) │
   │  production (manual, main)│
   └──────────────────────────┘
```

---

## File Change Summary

| File | Action | Effort |
|------|--------|--------|
| `sonar-project.properties` | **CREATE** | Small |
| `.github/workflows/ci.yml` | **MODIFY** (add sonarqube job, cleanup) | Medium |
| `.github/workflows/docker.yml` | **MODIFY** (trigger change) | Small |
| `.github/workflows/deploy.yml` | **REWRITE** (Blue-Green logic) | Large |
| `scripts/deploy.sh` | **REWRITE** (Blue-Green logic) | Large |
| `docker-compose.yml` | **MODIFY** (add SonarQube service) | Medium |
| `pyproject.toml` | **MODIFY** (minor dependency fix) | Tiny |
| `Dockerfile` | **MODIFY** (pin to 3.11-slim, cosmetic) | Tiny |
| `README.md` | **UPDATE** (secrets, SonarQube, deploy docs) | Medium |
| `ci.yml` dead comments | **DELETE** | Tiny |
| `deploy.yml` dead comments | **DELETE** | Tiny |
| Codecov integration | **DELETE** | Tiny |
| macOS matrix runner | **DELETE** | Tiny |

