
*** Settings ***
Documentation    Testy Odczyty, jednostki i limity.
...              Zakres: Sprawdzenie transferu (funkcjonalność 4), walidacja założeń,
...              odczyt pojedynczy i sumaryczny, zmiana jednostek (domyślnie kbps),
...              testy brzegowe dla transferu (max 100 Mbps) oraz ilości UE (0–100).
...
...              Przed uruchomieniem: docker run -p 8000:8000 epc-simulator:1.0.0
Library          EpcApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Library          BuiltIn
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}       http://localhost:8000

*** Test Cases ***

# ---------------------------------------------------------------------------
# 4.1  Odczyt pojedynczy — domyślna jednostka to kbps
# ---------------------------------------------------------------------------
EPC4.1 Odczyt pojedynczy — domyślna jednostka kbps
    [Documentation]    4.1 Gdy nie podamy parametru unit, statystyki bearera
    ...                są zwracane w kbps (domyślna jednostka per README).
    [Tags]    stats    units    happy_path
    When I attach UE with ID 50
    When I start traffic for UE 50 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 50 bearer 9 with unit ${EMPTY}
    Then response status is    200
    And field has integer value    ue_id        50
    And field has integer value    bearer_id    9
    And field has value            unit         kbps
    And field has integer value    throughput   10000

# ---------------------------------------------------------------------------
# 4.2  Odczyt pojedynczy — jawna jednostka kbps
# ---------------------------------------------------------------------------
EPC4.2 Odczyt pojedynczy — jawna jednostka kbps
    [Documentation]    4.2 Podanie unit=kbps daje taki sam wynik jak brak parametru.
    [Tags]    stats    units    happy_path
    When I attach UE with ID 51
    When I start traffic for UE 51 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 51 bearer 9 with unit kbps
    Then response status is    200
    And field has value            unit         kbps
    And field has integer value    throughput   10000

# ---------------------------------------------------------------------------
# 4.3  Odczyt pojedynczy — jednostka Mbps
# ---------------------------------------------------------------------------
EPC4.3 Odczyt pojedynczy — jednostka Mbps
    [Documentation]    4.3 Podanie unit=Mbps zwraca wartość przeliczoną do megabitów.
    [Tags]    stats    units    happy_path
    When I attach UE with ID 52
    When I start traffic for UE 52 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 52 bearer 9 with unit Mbps
    Then response status is    200
    And field has value    unit         Mbps
    And field has value    throughput   10

# ---------------------------------------------------------------------------
# 4.4  Odczyt sumaryczny — suma transferów ze wszystkich bearerów UE
# ---------------------------------------------------------------------------
EPC4.4 Odczyt sumaryczny — suma transferów ze wszystkich bearerów
    [Documentation]    4.4 GET /ues/{ue_id}/traffic zwraca sumaryczny transfer
    ...                ze wszystkich aktywnych bearerów danego UE.
    ...                Bearer 9 (10 Mbps) + bearer 3 (5 Mbps) = 15 000 kbps.
    [Tags]    stats    summary    happy_path
    When I attach UE with ID 53
    When I add bearer with ID 3 for UE 53
    When I start traffic for UE 53 on bearer 9 with protocol tcp at 10 Mbps
    When I start traffic for UE 53 on bearer 3 with protocol tcp at 5 Mbps
    When I get summary traffic stats for UE 53 with unit ${EMPTY}
    Then response status is    200
    And field has integer value    ue_id        53
    And field has value            unit         kbps
    And field has integer value    throughput   15000

# ---------------------------------------------------------------------------
# 4.5  Odczyt sumaryczny — jednostka Mbps
# ---------------------------------------------------------------------------
EPC4.5 Odczyt sumaryczny — jednostka Mbps
    [Documentation]    4.5 Sumaryczny odczyt z unit=Mbps — wynik w megabitach.
    [Tags]    stats    summary    units    happy_path
    When I attach UE with ID 54
    When I add bearer with ID 2 for UE 54
    When I start traffic for UE 54 on bearer 9 with protocol tcp at 20 Mbps
    When I start traffic for UE 54 on bearer 2 with protocol tcp at 10 Mbps
    When I get summary traffic stats for UE 54 with unit Mbps
    Then response status is    200
    And field has value    unit         Mbps
    And field has value    throughput   30

# ---------------------------------------------------------------------------
# 4.6  Test brzegowy transferu — dokładnie 100 Mbps (maksimum) → sukces
# ---------------------------------------------------------------------------
EPC4.6 Testy brzegowe transferu — dokładnie 100 Mbps
    [Documentation]    4.6 Transfer ustawiony na dokładnie 100 Mbps (limit górny)
    ...                powinien zakończyć się sukcesem.
    [Tags]    traffic    boundary    happy_path
    When I attach UE with ID 60
    When I start traffic for UE 60 on bearer 9 with protocol tcp at 100 Mbps
    Then response status is    200
    And field has value    status    traffic_started

# ---------------------------------------------------------------------------
# 4.7  Test brzegowy transferu — powyżej 100 Mbps → błąd walidacji
# ---------------------------------------------------------------------------
EPC4.7 Testy brzegowe transferu — powyżej 100 Mbps (100.1) daje błąd
    [Documentation]    4.7 Transfer powyżej 100 Mbps jest poza dozwolonym zakresem
    ...                i powinien zwrócić HTTP 422.
    [Tags]    traffic    boundary    validation
    When I attach UE with ID 61
    When I start traffic for UE 61 on bearer 9 with protocol tcp at 100.1 Mbps
    Then response status is    422

# ---------------------------------------------------------------------------
# 4.8  Test brzegowy transferu — ujemny transfer → błąd walidacji
# ---------------------------------------------------------------------------
EPC4.8 Testy brzegowe transferu — ujemna wartość daje błąd
    [Documentation]    4.8 Ujemna prędkość transferu jest nieprawidłowa
    ...                i powinna zwrócić HTTP 422.
    [Tags]    traffic    boundary    validation
    When I attach UE with ID 62
    When I start traffic for UE 62 on bearer 9 with protocol tcp at -1 Mbps
    Then response status is    422

# ---------------------------------------------------------------------------
# 4.9  Test brzegowy UE ID — UE ID = 1 (minimum poprawne) → sukces
# ---------------------------------------------------------------------------
EPC4.9 Testy brzegowe UE — UE ID 1 (minimum) jest poprawne
    [Documentation]    4.9 UE ID = 1 jest minimalną poprawną wartością w zakresie 1–100.
    [Tags]    attach    boundary    happy_path
    When I attach UE with ID 1
    Then response status is    200
    And field has value    status    attached

# ---------------------------------------------------------------------------
# 4.10  Test brzegowy UE ID — UE ID = 100 (maksimum poprawne) → sukces
# ---------------------------------------------------------------------------
EPC4.10 Testy brzegowe UE — UE ID 100 (maksimum) jest poprawne
    [Documentation]    4.10 UE ID = 100 jest maksymalną poprawną wartością w zakresie 1–100.
    [Tags]    attach    boundary    happy_path
    When I attach UE with ID 100
    Then response status is    200
    And field has value    status    attached

# ---------------------------------------------------------------------------
# 4.11  Test brzegowy UE ID — UE ID = 0 → błąd walidacji
# ---------------------------------------------------------------------------
EPC4.11 Testy brzegowe UE — UE ID 0 jest poza zakresem
    [Documentation]    4.11 UE ID = 0 jest poniżej dozwolonego zakresu (1–100)
    ...                i powinien zwrócić HTTP 422.
    [Tags]    attach    boundary    validation
    When I attach UE with ID 0
    Then response status is    422

# ---------------------------------------------------------------------------
# 4.12  Test brzegowy UE ID — UE ID = 101 → błąd walidacji
# ---------------------------------------------------------------------------
EPC4.12 Testy brzegowe UE — UE ID 101 jest poza zakresem
    [Documentation]    4.12 UE ID = 101 przekracza dozwolony zakres (1–100)
    ...                i powinien zwrócić HTTP 422.
    [Tags]    attach    boundary    validation
    When I attach UE with ID 101
    Then response status is    422

*** Keywords ***
When I attach UE with ID ${ue_id}
    ${status_code}    ${body}=    Attach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I add bearer with ID ${bearer_id} for UE ${ue_id}
    ${status_code}    ${body}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I start traffic for UE ${ue_id} on bearer ${bearer_id} with protocol ${protocol} at ${mbps} Mbps
    ${status_code}    ${body}=    Start Traffic Mbps    ${ue_id}    ${bearer_id}    ${protocol}    ${mbps}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get traffic stats for UE ${ue_id} bearer ${bearer_id} with unit ${unit}
    ${status_code}    ${body}=    Get Bearer Traffic Stats    ${ue_id}    ${bearer_id}    ${unit}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get summary traffic stats for UE ${ue_id} with unit ${unit}
    ${status_code}    ${body}=    Get Ue Traffic Stats    ${ue_id}    ${unit}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Then response status is
    [Arguments]    ${expected_status_code}
    Should Be Equal As Integers    ${status_code}    ${expected_status_code}

And field has value
    [Arguments]    ${field_name}    ${expected_value}
    Should Be Equal    ${body}[${field_name}]    ${expected_value}

And field has integer value
    [Arguments]    ${field_name}    ${expected_value}
    ${expected_int}=    Convert To Integer    ${expected_value}
    Should Be Equal As Integers    ${body}[${field_name}]    ${expected_int}
