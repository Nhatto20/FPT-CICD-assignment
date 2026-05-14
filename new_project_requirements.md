Assignment Details
Assignment 1: CI/CD Pipeline with Docker & SonarQube for a FastAPI Application
Description
Build a complete CI/CD pipeline that containerizes a FastAPI application, runs automated tests, enforces
code quality with SonarQube quality gates, and deploys using a zero-downtime strategy. This project
integrates all three units of the DevOps Essentials module into a real-world workflow.
Objectives
• Write an optimized, production-ready Dockerfile using multi-stage builds and security best practices.
• Design and implement a CI/CD pipeline (GitHub Actions or GitLab CI) with lint, test, build, scan,
and deploy stages.
• Integrate SonarQube code quality analysis as a mandatory quality gate in the pipeline.
• Apply a deployment strategy (Blue-Green or Canary) with health checks and rollback capability.
Problem Description
Develop a “DevOps Pipeline for FastAPI” that takes a provided FastAPI project (with existing unit tests),
containerizes it with Docker, and automates the entire build -> test -> scan -> deploy lifecycle through a
CI/CD pipeline. The pipeline must block deployments when SonarQube quality gates fail.
Assumptions
• A working FastAPI application with pytest unit tests is provided as the starting codebase.
• You have access to a Docker runtime (Docker Desktop or Docker Engine).
• A SonarQube instance is available (local Docker instance or hosted).
• You have a GitHub or GitLab account for CI/CD pipeline configuration.
• The target deployment environment is accessible (e.g., a staging server or local Docker Compose setup).
1
Technical Requirements
• Must use Python (version 3.11 or higher)
• Must write a multi-stage Dockerfile with non-root user, .dockerignore, and health check
• Must create a CI/CD pipeline with at minimum: lint, test, build, SonarQube scan, and deploy stages
• Must configure sonar-project.properties with correct source paths and coverage report integration
• Must implement a SonarQube quality gate that blocks deployment on failure
• Must use a Blue-Green or Canary deployment strategy with health check verification