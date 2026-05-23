"""Robot Framework library — HTTP client for the EPC simulator REST API."""

from __future__ import annotations

from typing import Any

import requests


class EpcApiLibrary:
    """Thin wrapper around the OpenAPI described at /openapi.json."""

    ROBOT_LIBRARY_SCOPE = "TEST"

    def __init__(self, base_url: str = "http://localhost:8000") -> None:
        self._base = base_url.rstrip("/")
        self._session = requests.Session()

    def reset_simulator(self) -> dict[str, Any]:
        r = self._session.post(f"{self._base}/reset", timeout=10)
        r.raise_for_status()
        return r.json()

    def attach_ue(self, ue_id: int) -> tuple[int, Any]:
        r = self._session.post(
            f"{self._base}/ues",
            json={"ue_id": int(ue_id)},
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def detach_ue(self, ue_id: int) -> tuple[int, Any]:
        r = self._session.delete(f"{self._base}/ues/{int(ue_id)}", timeout=10)
        return r.status_code, self._safe_json(r)

    def get_ue(self, ue_id: int) -> tuple[int, Any]:
        r = self._session.get(f"{self._base}/ues/{int(ue_id)}", timeout=10)
        return r.status_code, self._safe_json(r)

    def list_ues(self) -> tuple[int, Any]:
        r = self._session.get(f"{self._base}/ues", timeout=10)
        return r.status_code, self._safe_json(r)

    def add_bearer(self, ue_id: int, bearer_id: int) -> tuple[int, Any]:
        r = self._session.post(
            f"{self._base}/ues/{int(ue_id)}/bearers",
            json={"bearer_id": int(bearer_id)},
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def delete_bearer(self, ue_id: int, bearer_id: int) -> tuple[int, Any]:
        r = self._session.delete(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}",
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def start_traffic_mbps(
        self, ue_id: int, bearer_id: int, protocol: str, mbps: float
    ) -> tuple[int, Any]:
        r = self._session.post(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}/traffic",
            json={"protocol": protocol, "Mbps": float(mbps)},
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def start_traffic_with_direction(
        self, ue_id: int, bearer_id: int, protocol: str, mbps: float, direction: str
    ) -> tuple[int, Any]:
        r = self._session.post(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}/traffic",
            json={
                "protocol": protocol,
                "Mbps": float(mbps),
                "direction": direction,
            },
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def stop_traffic(self, ue_id: int, bearer_id: int) -> tuple[int, Any]:
        r = self._session.delete(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}/traffic",
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def get_bearer_traffic_stats_unit(
        self, ue_id: int, bearer_id: int, unit: str | None = None
    ) -> tuple[int, Any]:
        params = {"unit": unit} if unit else {}
        r = self._session.get(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}/traffic",
            params=params,
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    def stop_all_traffic_for_ue(self, ue_id: int) -> tuple[int, Any]:
        r = self._session.delete(f"{self._base}/ues/{int(ue_id)}/traffic", timeout=10)
        return r.status_code, self._safe_json(r)

    def get_ue_traffic_stats(
        self, ue_id: int, unit: str | None = None
    ) -> tuple[int, Any]:
        params = {"unit": unit} if unit else {}
        r = self._session.get(
            f"{self._base}/ues/{int(ue_id)}/traffic",
            params=params,
            timeout=10,
        )
        return r.status_code, self._safe_json(r)
    
    def get_bearer_traffic_stats(self, ue_id: int, bearer_id: int) -> tuple[int, Any]:
        r = self._session.get(
            f"{self._base}/ues/{int(ue_id)}/bearers/{int(bearer_id)}/traffic",
            timeout=10,
        )
        return r.status_code, self._safe_json(r)

    @staticmethod
    def _safe_json(r: requests.Response) -> Any:
        if not r.content:
            return None
        try:
            return r.json()
        except ValueError:
            return r.text
