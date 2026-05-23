*** Settings ***
Documentation    Testy akceptacyjne sterowania transferem danych EPC.
...              Zakres: rozpoczecie transferu DL, zakonczenie dla jednego i wszystkich bearerow,
...              oraz obsluga bledow dla nieaktywnego bearera i wartosci spoza specyfikacji.
Library          EpcTransferApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}       http://localhost:8000

*** Test Cases ***
EPC-TC-001 Start transferu DL na domyslnym bearerze
    [Documentation]    Wymaganie 3: transfer DL mozna uruchomic dla aktywnego bearera domyslnego 9.
    [Tags]    transfer    start    happy_path    requirement_3
    When I attach UE with ID 51
    Then response status is    200
    When I start DL traffic for UE 51 on bearer 9 with protocol tcp at 25 Mbps
    Then response status is    200
    And field has value    status    traffic_started
    And field has integer value    target_bps    25000000
    When I get traffic stats for UE 51 and bearer 9
    Then response status is    200
    And field has value    protocol    tcp
    And field has integer value    target_bps    25000000

EPC-TC-002 Start transferu DL na dedykowanym bearerze
    [Documentation]    Wymaganie 3: transfer DL mozna uruchomic dla aktywnego bearera dedykowanego.
    [Tags]    transfer    start    bearer    happy_path    requirement_3
    When I attach UE with ID 52
    When I add bearer with ID 4 for UE 52
    Then response status is    200
    When I start DL traffic for UE 52 on bearer 4 with protocol udp at 10 Mbps
    Then response status is    200
    And field has value    status    traffic_started
    And field has integer value    target_bps    10000000
    When I get traffic stats for UE 52 and bearer 4
    Then response status is    200
    And field has value    protocol    udp

EPC-TC-003 Start transferu dla nieaktywnego bearera zwraca blad
    [Documentation]    Wymaganie 3: start transferu dla bearera, ktory nie jest aktywny, powinien zwrocic blad.
    [Tags]    transfer    start    negative    inactive_bearer    requirement_3
    When I attach UE with ID 53
    When I start DL traffic for UE 53 on bearer 4 with protocol tcp at 1 Mbps
    Then response status is    400
    And field has value    detail    Bearer not found

EPC-TC-004 Zakonczenie transferu dla jednego bearera
    [Documentation]    Wymaganie 5: mozna zakonczyc transfer dla wybranego bearera bez zatrzymywania pozostalych.
    [Tags]    transfer    stop    bearer    happy_path    requirement_5
    When I attach UE with ID 54
    When I add bearer with ID 4 for UE 54
    When I start DL traffic for UE 54 on bearer 9 with protocol tcp at 2 Mbps
    When I start DL traffic for UE 54 on bearer 4 with protocol udp at 3 Mbps
    When I stop traffic for UE 54 and bearer 4
    Then response status is    200
    And field has value    status    traffic_stopped
    When I get traffic stats for UE 54 and bearer 9
    Then response status is    200
    And field has value    protocol    tcp
    And field has integer value    target_bps    2000000

EPC-TC-005 Zakonczenie nieaktywnego transferu zwraca blad
    [Documentation]    Wymaganie 5: proba zatrzymania transferu, ktory nie zostal uruchomiony, powinna zwrocic blad.
    [Tags]    transfer    stop    negative    inactive_bearer    defect_candidate    requirement_5
    When I attach UE with ID 55
    When I stop traffic for UE 55 and bearer 9
    Then response is client error

EPC-TC-006 Zakonczenie transferu dla wszystkich bearerow UE
    [Documentation]    Wymaganie 5: mozna zakonczyc transfer calkowicie dla wszystkich bearerow UE.
    [Tags]    transfer    stop_all    defect_candidate    requirement_5
    When I attach UE with ID 56
    When I add bearer with ID 4 for UE 56
    When I start DL traffic for UE 56 on bearer 9 with protocol tcp at 2 Mbps
    When I start DL traffic for UE 56 on bearer 4 with protocol udp at 3 Mbps
    When I stop all traffic for UE 56
    Then response status is    200

EPC-TC-007 Transfer powyzej 100 Mbps jest odrzucany
    [Documentation]    Wymaganie 3: transfer dla UE nie moze przekroczyc 100 Mbps.
    [Tags]    transfer    validation    negative    defect_candidate    requirement_3
    When I attach UE with ID 57
    When I start DL traffic for UE 57 on bearer 9 with protocol tcp at 101 Mbps
    Then response is client error

EPC-TC-008 Transfer w kierunku innym niz DL jest odrzucany
    [Documentation]    Wymaganie 3: transfer mozna uruchomic tylko w kierunku DL.
    [Tags]    transfer    direction    negative    defect_candidate    requirement_3
    When I attach UE with ID 58
    When I start traffic for UE 58 on bearer 9 with protocol tcp at 1 Mbps and direction UL
    Then response is client error

*** Keywords ***
When I attach UE with ID ${ue_id}
    ${status_code}    ${body}=    Attach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I add bearer with ID ${bearer_id} for UE ${ue_id}
    ${status_code}    ${body}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I start DL traffic for UE ${ue_id} on bearer ${bearer_id} with protocol ${protocol} at ${mbps} Mbps
    ${status_code}    ${body}=    Start Traffic Mbps    ${ue_id}    ${bearer_id}    ${protocol}    ${mbps}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I start traffic for UE ${ue_id} on bearer ${bearer_id} with protocol ${protocol} at ${mbps} Mbps and direction ${direction}
    ${status_code}    ${body}=    Start Traffic With Direction    ${ue_id}    ${bearer_id}    ${protocol}    ${mbps}    ${direction}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I stop traffic for UE ${ue_id} and bearer ${bearer_id}
    ${status_code}    ${body}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I stop all traffic for UE ${ue_id}
    ${status_code}    ${body}=    Stop All Traffic For Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get traffic stats for UE ${ue_id} and bearer ${bearer_id}
    ${status_code}    ${body}=    Get Bearer Traffic Stats    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Then response status is
    [Arguments]    ${expected_status_code}
    Should Be Equal As Integers    ${status_code}    ${expected_status_code}

Then response is client error
    Should Be True    400 <= ${status_code} < 500

And field has value
    [Arguments]    ${field_name}    ${expected_value}
    Should Be Equal    ${body}[${field_name}]    ${expected_value}

And field has integer value
    [Arguments]    ${field_name}    ${expected_value}
    ${expected_int}=    Convert To Integer    ${expected_value}
    Should Be Equal As Integers    ${body}[${field_name}]    ${expected_int}
