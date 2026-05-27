# Podsumowanie testów akceptacyjnych EPC

## Cel

Zestaw testów Robot Framework weryfikuje API symulatora Evolved Packet Core (EPC) w czterech obszarach zgodnych z dokumentacją produktu (`README.md`):

| Plik                              | Obszar dokumentacji | Funkcjonalności                       |
| --------------------------------- | ------------------- | ------------------------------------- |
| `epc_session_management.robot`    | pkt 1, 2, 9         | attach, detach, reset                 |
| `epc_transfer_control.robot`      | pkt 3, 5            | start/stop transferu DL, statystyki   |
| `epc_readings_units_limits.robot` | pkt 1, 4            | odczyty statystyk, jednostki, limity  |
| `channel_managment.robot`         | pkt 6, 7, 8         | dodawanie, odczyt i usuwanie bearerów |

Każdy test startuje od czystego stanu dzięki `Test Setup: Reset Simulator`.

Łącznie: **37 testów** w **4 suite’ach**.

## Środowisko i uruchomienie

- Biblioteka API: `EpcApiLibrary.py`
- Endpoint bazowy: `http://localhost:8000` (zmienna `${EPC_BASE_URL}`)
- Zależności: `pip install -r requirements.txt`
- Symulator (przed testami):

  ```bash
  docker run -p 8000:8000 epc-simulator:1.0.0
  ```

### Uruchomienie wszystkich suite’ów

Skrypt `run_tests.sh` uruchamia po kolei wszystkie cztery pliki `.robot` i zapisuje raporty Robot Framework w osobnych katalogach:

```bash
./run_tests.sh
```

Wyniki (dla każdej suite): `output.xml`, `log.html`, `report.html` w:

| Suite                             | Katalog wyników                      |
| --------------------------------- | ------------------------------------ |
| `epc_session_management.robot`    | `results/epc_session_management/`    |
| `epc_transfer_control.robot`      | `results/epc_transfer_control/`      |
| `epc_readings_units_limits.robot` | `results/epc_readings_units_limits/` |
| `channel_managment.robot`         | `results/channel_managment/`         |

Inny katalog wyników (opcjonalnie):

```bash
RESULTS_DIR=/ścieżka/do/wyników ./run_tests.sh
```

### Uruchomienie pojedynczej suite

```bash
robot --outputdir results/epc_session_management epc_session_management.robot
robot --outputdir results/epc_transfer_control epc_transfer_control.robot
robot --outputdir results/epc_readings_units_limits epc_readings_units_limits.robot
robot --outputdir results/channel_managment channel_managment.robot
```

## Struktura podejścia testowego

Testy są napisane stylem BDD z czytelnymi krokami:

- `When ...` — akcja na API (np. attach, start traffic, add bearer),
- `Then ...` — walidacja statusu HTTP,
- `And ...` — walidacje pól odpowiedzi lub stanu sieci.

W plikach użyto embedded keywords dla akcji z parametrami (np. `When I attach UE with ID 42`). Wartości parametrów muszą być w tej samej linii co krok, a nie w osobnej kolumnie tabeli Robot Framework.

Walidacja sukcesu/błędu:

- `epc_session_management.robot` — `Then response is success` (2xx) / `Then response is error` (≥400),
- `epc_transfer_control.robot` — `Then response status is` z konkretnym kodem lub `Then response is client error` (4xx),
- `epc_readings_units_limits.robot` — `Then response status is` z dokładnym kodem (200/422) oraz walidacje pól (`And field has value`, `And field has integer value`),
- `channel_management.robot` — jak w session management (2xx / ≥400).
