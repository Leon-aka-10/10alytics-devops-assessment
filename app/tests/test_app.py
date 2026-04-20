import pytest
from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_home_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200


def test_home_returns_json(client):
    response = client.get("/")
    data = response.get_json()
    assert "message" in data
    assert "environment" in data


def test_health_without_db_returns_503(client, monkeypatch):
    monkeypatch.delenv("DB_CONNECTION_STRING", raising=False)
    response = client.get("/health")
    assert response.status_code == 503
    data = response.get_json()
    assert data["status"] == "degraded"


def test_health_with_db_returns_200(client, monkeypatch):
    monkeypatch.setenv("DB_CONNECTION_STRING", "Server=fake;Database=test")
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "ok"
