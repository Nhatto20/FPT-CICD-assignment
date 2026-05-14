Task 1: Create Basic CI Workflow (20 points)
1. Create a GitHub repository with a Python application including:
• Source code in src/ directory
• Tests in tests/ directory
• pyproject.toml with dependencies
2. Create a basic CI workflow (.github/workflows/ci.yml):
name: CI Pipeline
on:
push:
branches: [main, develop]
pull_request:
branches: [main]
3. Implement the following jobs:
• lint: Run Ruff and Black for code quality
• test: Run pytest with coverage reporting
4. Configure job dependencies so tests only run after linting passes
Task 2: Implement Matrix Testing (15 points)
1. Extend the CI workflow with matrix builds:
• Test across Python versions: 3.10, 3.11, 3.12
• Test on multiple OS: ubuntu-latest, macos-latest
2. Configure fail-fast behavior appropriately
3. Document the matrix configuration and explain when to use exclude
Task 3: Add Caching and Artifacts (20 points)
1. Implement dependency caching:
• Cache pip dependencies
• Use cache key based on pyproject.toml hash
2. Upload test artifacts:
• Coverage reports
2
• Test results (JUnit XML format)
3. Configure Codecov integration for coverage reporting
4. Measure and document the time saved by caching: | Run Type | Build Time | |———-|———–| |
Without cache | ? seconds | | With cache | ? seconds |
Task 4: Build and Push Docker Image (20 points)
1. Create a Docker build workflow that:
• Builds the Docker image on every push to main
• Tags images with commit SHA and latest
• Pushes to GitHub Container Registry (ghcr.io)
2. Configure secrets for registry authentication
3. Implement conditional builds:
• Only build Docker image when source code changes
• Use paths filter to skip builds for documentation changes
4. Add image scanning in the pipeline using Trivy or Docker Scout
Task 5: Implement Deployment Strategy (25 points)
1. Create environment-specific deployments:
• staging: Auto-deploy on push to develop branch
• production: Manual approval required, deploy on push to main
2. Implement a deployment workflow with:
• Environment protection rules
• Deployment status notifications
• Health check verification after deployment
3. Create a simple deployment script (deploy.sh) that:
• Pulls the new Docker image
• Performs health check
• Reports deployment status