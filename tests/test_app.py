import pytest

from app.main import app


@pytest.fixture()
def client():
    app.config.update(TESTING=True)
    return app.test_client()


def test_health_is_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_health_reports_version(client, monkeypatch):
    monkeypatch.setenv("APP_VERSION", "abc1234")
    assert client.get("/health").get_json()["version"] == "abc1234"


def test_index_reports_environment(client, monkeypatch):
    monkeypatch.setenv("APP_ENV", "staging")
    body = client.get("/").get_json()
    assert body["service"] == "two-click-demo"
    assert body["environment"] == "staging"


def test_unknown_route_is_404(client):
    assert client.get("/nope").status_code == 404
