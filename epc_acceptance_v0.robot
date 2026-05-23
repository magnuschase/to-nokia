
*** Settings ***
Documentation    Skrócone testy akceptacyjne API symulatora EPC.
...              Przed uruchomieniem: docker run -p 8000:8000 epc-simulator:1.0.0
Library          EpcApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}       http://localhost:8000

*** Test Cases ***
# Dorzucic numeracje testow
Attach UE — Sukces i domyślny bearer 9
    [Documentation]    1.4 Podłączony do sieci UE automatycznie otrzymuje domyślny bearer o ID 9.
    [Tags]    attach    happy_path
    When I attach UE with ID 42
    Then response status is    200
    And field has value    status    attached
    When I get UE with ID 42
    Then response status is    200
    And UE has bearer with ID    9

Attach UE — Błąd gdy UE ID poza zakresem (0 i 101)
    [Documentation]    1.2 Jeśli UE ID jest spoza zakresu - zostanie wyświetlony błąd.
    [Tags]    attach    validation
    When I attach UE with ID 0
    Then response status is    422
    When I attach UE with ID 101
    Then response status is    422

Detach UE — Sukces
    [Documentation]    2.1 UE może zostać odłączony od sieci.
    [Tags]    detach    happy_path
    When I attach UE with ID 15
    Then response status is    200
    When I detach UE with ID 15
    Then response status is    200
    And field has value    status    detached
    When I get UE with ID 15
    Then response status is    400
    And field has value    detail    UE not found

Start ruchu DL — Sukces (Mbps)
    [Documentation]    3.1 Transfer danych można rozpocząć tylko w kierunku DL.
    [Tags]    traffic    happy_path
    When I attach UE with ID 33
    When I start traffic for UE 33 on bearer 9 with protocol tcp at 25.5 Mbps
    Then response status is    200
    And field has value    status    traffic_started
    And field has integer value    target_bps    25500000

Pobierz statystyki bearera
    [Documentation]    4.1 Można sprawdzić transfer dla pojedynczego bearera w ramach UE.
    [Tags]    stats
    When I attach UE with ID 77
    When I start traffic for UE 77 on bearer 9 with protocol tcp at 5 Mbps
    When I get traffic stats for UE 77 and bearer 9
    Then response status is    200
    And field has integer value    ue_id    77
    And field has integer value    bearer_id    9
    And field has value    protocol    tcp

Zatrzymanie ruchu dla bearera
    [Documentation]    5.1 Transfer danych można zakończyć dla poszczególnego bearera.
    [Tags]    traffic    stop
    When I attach UE with ID 11
    When I start traffic for UE 11 on bearer 9 with protocol tcp at 12 Mbps
    When I stop traffic for UE 11 and bearer 9
    Then response status is    200
    And field has value    status    traffic_stopped

Dodaj dedykowany bearer
    [Documentation]    6.1 Możliwe jest dodanie dedykowanych bearer-ów dla UE.
    [Tags]    bearer    happy_path
    When I attach UE with ID 21
    When I add bearer with ID 4 for UE 21
    Then response status is    200
    And field has value    status    bearer_added
    When I get UE with ID 21
    And UE has bearer with ID    4

Usuń dedykowany bearer
    [Documentation]    8.1 Możliwe jest usunięcie dedykowanego bearer'a dla UE.
    [Tags]    bearer    happy_path
    When I attach UE with ID 31
    When I add bearer with ID 5 for UE 31
    When I delete bearer with ID 5 for UE 31
    Then response status is    200
    And field has value    status    bearer_deleted

Usuń bearer — nie można usunąć domyślnego (9)
    [Documentation]    8.4 Nie ma możliwości usunięcia domyślnego bearera.
    [Tags]    bearer    error
    When I attach UE with ID 32
    When I delete bearer with ID 9 for UE 32
    Then response status is    400
    And field has value    detail    Cannot remove default bearer

Reset symulatora
    [Documentation]    9.1 Możliwe jest przywrócenie symulatora do stanu początkowego.
    [Tags]    reset
    When I attach UE with ID 41
    When I reset the simulator
    When I list UEs
    Then response status is    200
    And UE list is empty

*** Keywords ***
When I attach UE with ID ${ue_id}
    ${status_code}    ${body}=    Attach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I detach UE with ID ${ue_id}
    ${status_code}    ${body}=    Detach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get UE with ID ${ue_id}
    ${status_code}    ${body}=    Get Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I list UEs
    ${status_code}    ${body}=    List Ues
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I add bearer with ID ${bearer_id} for UE ${ue_id}
    ${status_code}    ${body}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I delete bearer with ID ${bearer_id} for UE ${ue_id}
    ${status_code}    ${body}=    Delete Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I start traffic for UE ${ue_id} on bearer ${bearer_id} with protocol ${protocol} at ${mbps} Mbps
    ${status_code}    ${body}=    Start Traffic Mbps    ${ue_id}    ${bearer_id}    ${protocol}    ${mbps}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get traffic stats for UE ${ue_id} and bearer ${bearer_id}
    ${status_code}    ${body}=    Get Bearer Traffic Stats    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I stop traffic for UE ${ue_id} and bearer ${bearer_id}
    ${status_code}    ${body}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I reset the simulator
    Reset Simulator

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

And UE has bearer with ID
    [Arguments]    ${bearer_id}
    Dictionary Should Contain Key    ${body}[bearers]    ${bearer_id}

And UE list is empty
    Should Be Empty    ${body}[ues]
