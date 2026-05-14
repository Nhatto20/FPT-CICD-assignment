# Answers

## 1. Why are multi-stage builds used in the Dockerfile?

Multi-stage builds separate dependency installation from the final runtime image. In this project, the `builder` stage creates the virtual environment and installs production dependencies, while the `production` stage copies only the finished runtime environment and app code.

This improves image size by leaving build-time work and dev dependencies out of the production image. It improves security by reducing the attack surface and running the app as a non-root `appuser`.

## 2. Complete CI/CD pipeline flow

When a developer pushes to `main` or `develop`, the CI workflow starts. It checks out the code, runs Ruff and Black, then runs pytest with coverage and uploads the test artifacts.

After tests pass, SonarQube analyzes the code and checks the quality gate. If CI succeeds, the Docker workflow builds the image, pushes it to GitHub Container Registry, and scans it with Trivy. If that succeeds, the deploy workflow pulls the image and runs it on the self-hosted runner: `develop` deploys to staging on port `8000`, and `main` deploys to production on port `8080`.

## 3. SonarQube quality gate integration

SonarQube runs after the test job and uses the generated `coverage.xml` report. The pipeline then runs the SonarQube Quality Gate Check action.

If the quality gate fails, the SonarQube job fails. Because the Docker build workflow only runs after a successful CI pipeline, the image is not built or pushed, and deployment does not continue.
