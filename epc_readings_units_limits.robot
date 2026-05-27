
*** Settings ***
Documentation    Testy akceptacyjne odczytów, jednostek i limitów transferu EPC.
...              Zakres: odczyt pojedynczy i sumaryczny (Wymaganie 4),
...              zmiana jednostek (kbps/Mbps), testy brzegowe transferu (max 100 Mbps)
...              oraz zakresu UE ID (1–100).
...              Przed uruchomieniem: docker run -p 8000:8000 epc-simulator:1.0.0
Library          EpcApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Library          BuiltIn
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}       http://localhost:8000

*** Test Cases ***

EPC-RUL-001 Odczyt pojedynczy — domyślna jednostka kbps
    [Documentation]    Wymaganie 4: brak parametru unit zwraca statystyki bearera w kbps (jednostka domyślna).
    [Tags]    EPC-RUL-001    req_4    stats    units    happy_path
    When I attach UE with ID 50
    When I start traffic for UE 50 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 50 bearer 9 with unit ${EMPTY}
    Then response status is    200
    And field has integer value    ue_id        50
    And field has integer value    bearer_id    9
    And field has value            unit         kbps
    And field has integer value    throughput   10000

EPC-RUL-002 Odczyt pojedynczy — jawna jednostka kbps
    [Documentation]    Wymaganie 4: parametr unit=kbps daje wynik tożsamy z odczytem bez podanego parametru unit.
    [Tags]    EPC-RUL-002    req_4    stats    units    happy_path
    When I attach UE with ID 51
    When I start traffic for UE 51 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 51 bearer 9 with unit kbps
    Then response status is    200
    And field has value            unit         kbps
    And field has integer value    throughput   10000

EPC-RUL-003 Odczyt pojedynczy — jednostka Mbps
    [Documentation]    Wymaganie 4: parametr unit=Mbps powoduje przeliczenie throughput do megabitów na sekundę.
    [Tags]    EPC-RUL-003    req_4    stats    units    happy_path
    When I attach UE with ID 52
    When I start traffic for UE 52 on bearer 9 with protocol tcp at 10 Mbps
    When I get traffic stats for UE 52 bearer 9 with unit Mbps
    Then response status is    200
    And field has value    unit         Mbps
    And field has value    throughput   10

EPC-RUL-004 Odczyt sumaryczny — suma transferów ze wszystkich bearerów
    [Documentation]    Wymaganie 4: GET /ues/{ue_id}/traffic zwraca łączny throughput wszystkich aktywnych bearerów UE.
    ...                Bearer 9 (10 Mbps) + bearer 3 (5 Mbps) = 15 000 kbps.
    [Tags]    EPC-RUL-004    req_4    stats    summary    happy_path
    When I attach UE with ID 53
    When I add bearer with ID 3 for UE 53
    When I start traffic for UE 53 on bearer 9 with protocol tcp at 10 Mbps
    When I start traffic for UE 53 on bearer 3 with protocol tcp at 5 Mbps
    When I get summary traffic stats for UE 53 with unit ${EMPTY}
    Then response status is    200
    And field has integer value    ue_id        53
    And field has value            unit         kbps
    And field has integer value    throughput   15000

EPC-RUL-005 Odczyt sumaryczny — jednostka Mbps
    [Documentation]    Wymaganie 4: sumaryczny odczyt z unit=Mbps sumuje throughput wszystkich bearerów i zwraca wartość w Mbps.
    [Tags]    EPC-RUL-005    req_4    stats    summary    units    happy_path
    When I attach UE with ID 54
    When I add bearer with ID 2 for UE 54
    When I start traffic for UE 54 on bearer 9 with protocol tcp at 20 Mbps
    When I start traffic for UE 54 on bearer 2 with protocol tcp at 10 Mbps
    When I get summary traffic stats for UE 54 with unit Mbps
    Then response status is    200
    And field has value    unit         Mbps
    And field has value    throughput   30

EPC-RUL-006 Testy brzegowe transferu — dokładnie 100 Mbps jest poprawne
    [Documentation]    Założenia: transfer dokładnie 100 Mbps mieści się w dozwolonym zakresie i powinien zostać przyjęty.
    [Tags]    EPC-RUL-006    req_4    traffic    boundary    happy_path
    When I attach UE with ID 60
    When I start traffic for UE 60 on bearer 9 with protocol tcp at 100 Mbps
    Then response status is    200
    And field has value    status    traffic_started

EPC-RUL-007 Testy brzegowe transferu — powyżej 100 Mbps jest odrzucane
    [Documentation]    Założenia: transfer 100.1 Mbps przekracza limit 100 Mbps i powinien zwrócić błąd walidacji.
    [Tags]    EPC-RUL-007    req_4    traffic    boundary    validation    defect_candidate
    When I attach UE with ID 61
    When I start traffic for UE 61 on bearer 9 with protocol tcp at 100.1 Mbps
    Then response status is    422

EPC-RUL-008 Testy brzegowe transferu — ujemna wartość jest odrzucana
    [Documentation]    Założenia: ujemna prędkość transferu jest poza dozwolonym zakresem i powinna zwrócić błąd walidacji.
    [Tags]    EPC-RUL-008    req_4    traffic    boundary    validation    defect_candidate
    When I attach UE with ID 62
    When I start traffic for UE 62 on bearer 9 with protocol tcp at -1 Mbps
    Then response status is    422

EPC-RUL-009 Testy brzegowe UE ID — minimum (1) jest poprawne
    [Documentation]    1.2, Założenia: UE ID = 1 to minimalna poprawna wartość w dozwolonym zakresie 1–100.
    [Tags]    EPC-RUL-009    req_1    attach    boundary    happy_path
    When I attach UE with ID 1
    Then response status is    200
    And field has value    status    attached

EPC-RUL-010 Testy brzegowe UE ID — maksimum (100) jest poprawne
    [Documentation]    1.2, Założenia: UE ID = 100 to maksymalna poprawna wartość w dozwolonym zakresie 1–100.
    [Tags]    EPC-RUL-010    req_1    attach    boundary    happy_path
    When I attach UE with ID 100
    Then response status is    200
    And field has value    status    attached

EPC-RUL-011 Testy brzegowe UE ID — poniżej zakresu (0) jest odrzucane
    [Documentation]    1.2, Założenia: UE ID = 0 jest poniżej dozwolonego zakresu 1–100 i powinien zwrócić błąd.
    [Tags]    EPC-RUL-011    req_1    attach    boundary    validation
    When I attach UE with ID 0
    Then response status is    422

EPC-RUL-012 Testy brzegowe UE ID — powyżej zakresu (101) jest odrzucane
    [Documentation]    1.2, Założenia: UE ID = 101 przekracza dozwolony zakres 1–100 i powinien zwrócić błąd.
    [Tags]    EPC-RUL-012    req_1    attach    boundary    validation
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
