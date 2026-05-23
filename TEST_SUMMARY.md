# Podsumowanie testów `epc_acceptance_v0.robot`

## Cel

Zestaw `epc_acceptance_v0.robot` zawiera skrócone testy akceptacyjne API symulatora EPC.  
Suite weryfikuje kluczowe scenariusze biznesowe dla:
- dołączania i odłączania UE,
- uruchamiania i zatrzymywania ruchu,
- obsługi bearerów,
- resetu stanu systemu.

Każdy test startuje od czystego stanu dzięki `Test Setup: Reset Simulator`.

## Zakres i środowisko

- Plik testów: `lab3/epc_acceptance_v0.robot`
- Biblioteka API: `lab3/EpcApiLibrary.py`
- Endpoint bazowy: `http://localhost:8000`
- Uruchomienie symulatora:
  - `docker run -p 8000:8000 epc-simulator:1.0.0`
- Uruchomienie testów:
  - `robot epc_acceptance_v0.robot`

## Struktura podejścia testowego

Testy są napisane stylem BDD z czytelnymi krokami:
- `Gdy ...` — akcja na API (np. attach, start traffic, delete bearer),
- `Wtedy ...` — walidacja statusu HTTP,
- `Oraz ...` — walidacje pól odpowiedzi.

W pliku użyto embedded keywords dla akcji z parametrami (np. `Gdy dołączam UE o ID ${ue_id}`), żeby było jasno, który parametr jest który.

## Szczegółowy opis 10 testów

1. **Attach UE — Sukces i domyślny bearer 9**
   - **Cel:** potwierdzić poprawne podłączenie UE i automatyczne utworzenie bearera 9.
   - **Kroki:** attach `UE=42`, pobranie danych UE.
   - **Asercje:** HTTP `200`, `status=attached`, obecność `bearer_id=9`.

2. **Attach UE — Błąd gdy UE ID poza zakresem (0 i 101)**
   - **Cel:** walidacja ograniczenia zakresu UE ID.
   - **Kroki:** attach dla `UE=0` i `UE=101`.
   - **Asercje:** HTTP `422` dla obu przypadków.

3. **Detach UE — Sukces**
   - **Cel:** zweryfikować poprawne odłączenie wcześniej podłączonego UE.
   - **Kroki:** attach `UE=15`, detach `UE=15`, potem GET `UE=15`.
   - **Asercje:** detach zwraca HTTP `200`, `status=detached`; później GET zwraca HTTP `400` i `detail=UE not found`.

4. **Start ruchu DL — Sukces (Mbps)**
   - **Cel:** potwierdzić, że ruch można uruchomić dla domyślnego bearera.
   - **Kroki:** attach `UE=33`, start ruchu na `bearer=9`, `protocol=tcp`, `Mbps=25.5`.
   - **Asercje:** HTTP `200`, `status=traffic_started`, `target_bps=25500000`.

5. **Pobierz statystyki bearera**
   - **Cel:** sprawdzić odczyt statystyk aktywnego ruchu.
   - **Kroki:** attach `UE=77`, start ruchu na `bearer=9`, GET statystyk bearera.
   - **Asercje:** HTTP `200`, `ue_id=77`, `bearer_id=9`, `protocol=tcp`.

6. **Zatrzymanie ruchu dla bearera**
   - **Cel:** zweryfikować poprawne zatrzymanie transferu.
   - **Kroki:** attach `UE=11`, start ruchu, stop ruchu na `bearer=9`.
   - **Asercje:** HTTP `200`, `status=traffic_stopped`.

7. **Dodaj dedykowany bearer**
   - **Cel:** potwierdzić możliwość dodania dodatkowego bearera dla UE.
   - **Kroki:** attach `UE=21`, add `bearer=4`, GET `UE=21`.
   - **Asercje:** HTTP `200`, `status=bearer_added`, obecność bearera `4` w danych UE.

8. **Usuń dedykowany bearer**
   - **Cel:** zweryfikować usunięcie bearera dodanego przez użytkownika.
   - **Kroki:** attach `UE=31`, add `bearer=5`, delete `bearer=5`.
   - **Asercje:** HTTP `200`, `status=bearer_deleted`.

9. **Usuń bearer — nie można usunąć domyślnego (9)**
   - **Cel:** wymusić regułę biznesową blokującą usunięcie domyślnego bearera.
   - **Kroki:** attach `UE=32`, delete `bearer=9`.
   - **Asercje:** HTTP `400`, `detail=Cannot remove default bearer`.

10. **Reset symulatora**
    - **Cel:** potwierdzić przywrócenie stanu początkowego.
    - **Kroki:** attach `UE=41`, reset, pobranie listy UE.
    - **Asercje:** HTTP `200`, lista UE pusta.

## Co jest pokryte

- `attach` (sukces + walidacja zakresu),
- `detach` (sukces + brak UE po detach),
- `traffic start/stop`,
- `traffic stats` dla pojedynczego bearera,
- `bearer add/delete`,
- ochrona domyślnego bearera `9`,
- globalny reset stanu.

## Co świadomie pominięto w wersji `v0`

To jest wersja skrócona, więc nie obejmuje pełnego przekroju błędów i wariantów z rozbudowanej suite (np. duplikat attach, dodatkowe walidacje formatów payloadu, przypadki nieistniejącego bearera przy starcie ruchu itp.).

## Wynik ostatniego uruchomienia

- **10 testów**
- **10 zaliczonych**
- **0 błędów**
