from fastapi.testclient import TestClient
from app import app

client = TestClient(app)


def test_health_returns_200():
    response = client.get("/health")
    assert response.status_code == 200


def test_health_returns_correct_body():
    response = client.get("/health")
    assert response.json() == {"status": "healthy"}


def test_ping_returns_pong():
    response = client.get("/api/ping")
    assert response.status_code == 200
    assert response.json() == {"message": "pong"}


def test_version_returns_app_metadata():
    response = client.get("/api/version")
    assert response.status_code == 200
    assert response.json() == {"name": "myapp", "version": "0.1.0"}
