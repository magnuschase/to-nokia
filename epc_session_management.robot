*** Settings ***
Documentation    Testy: zarządzanie sesją UE (dok. pkt 1, 2, 9).
...              Symulator: docker run -p 8000:8000 epc-simulator:1.0.0
...              Uruchomienie: robot epc_session_management.robot
Library          EpcApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Library          String
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}          http://localhost:8000
${DOC_UE_ID_MIN}         0
${DOC_UE_ID_MAX}         100
${DOC_DEFAULT_BEARER}    9

*** Test Cases ***
# --- 1. Attach (pkt 1) - 4 testy ---

EPC-SM-1-001 Attach - sukces, bearer 9 i granice dokumentowane 0 oraz 100
    [Documentation]    1.1, 1.4, Założenia: attach w zakresie; po attach bearer 9; UE=0 i UE=100 na granicach.
    [Tags]    EPC-SM-1-001    req_1    attach    happy_path    boundary
    When I attach UE with ID 42
    Then response is success
    When I get UE with ID 42
    Then response is success
    And UE has default bearer per documentation
    When I attach UE with ID ${DOC_UE_ID_MIN}
    Then response is success
    When I attach UE with ID ${DOC_UE_ID_MAX}
    Then response is success

EPC-SM-1-002 Attach - błąd dla ID poza dokumentowanym zakresem
    [Documentation]    1.2, Założenia: -1, 101, 999 → błąd; sieć pozostaje pusta.
    [Tags]    EPC-SM-1-002    req_1    attach    validation
    FOR    ${invalid_id}    IN    -1    101    999
        When I attach UE with ID ${invalid_id}
        Then response is error
    END
    And simulator has no attached UEs

EPC-SM-1-003 Attach - duplikat oraz brak "pół-sesji" po odrzuconym attach
    [Documentation]    1.3: ponowny attach → błąd, pierwsza sesja bez zmian. 1.2: po błędzie 101 tylko poprawny attach w sieci.
    [Tags]    EPC-SM-1-003    req_1    attach    duplicate    state
    When I attach UE with ID 7
    Then response is success
    When I attach UE with ID 7
    Then response is error
    When I get UE with ID 7
    Then response is success
    And UE has default bearer per documentation
    When I attach UE with ID 101
    Then response is error
    When I attach UE with ID 50
    Then response is success
    When I list UEs
    Then response is success
    And UE list is exactly 7, 50

EPC-SM-1-004 Attach - wiele UE (10, 50, 90) i ponowny attach po detach
    [Documentation]    1.1: wiele UE w sieci. 1.1+2.1: ten sam ID po detach można ponownie dołączyć.
    [Tags]    EPC-SM-1-004    req_1    attach    multi_ue    reattach
    When I attach UE with ID 10
    Then response is success
    When I attach UE with ID 50
    Then response is success
    When I attach UE with ID 90
    Then response is success
    When I list UEs
    Then response is success
    And UE list is exactly 10, 50, 90
    When I attach UE with ID 50
    Then response is error
    When I detach UE with ID 50
    Then response is success
    When I attach UE with ID 50
    Then response is success

# --- 2. Detach (pkt 2) - 3 testy ---

EPC-SM-2-001 Detach - sukces i brak podłączenia po operacji
    [Documentation]    2.1: poprawny detach; odczyt stanu podłączonego UE → błąd.
    [Tags]    EPC-SM-2-001    req_2    detach    happy_path
    When I attach UE with ID 15
    Then response is success
    When I detach UE with ID 15
    Then response is success
    And field status has value detached
    When I query attached UE state for ID 15
    Then response is error

EPC-SM-2-002 Detach - scenariusze błędów (niepodłączony, powtórzenie, poza zakresem)
    [Documentation]    2.3 + Założenia: nigdy nie attachowany (88), drugi detach (16), ID 101 poza zakresem, UE=0 niepodłączony.
    [Tags]    EPC-SM-2-002    req_2    detach    validation    edge_case
    When I detach UE with ID 88
    Then response is error
    When I attach UE with ID 16
    Then response is success
    When I detach UE with ID 16
    Then response is success
    When I detach UE with ID 16
    Then response is error
    When I detach UE with ID 101
    Then response is error
    When I detach UE with ID ${DOC_UE_ID_MIN}
    Then response is error

EPC-SM-2-003 Detach - izolacja sesji i cykl attach/detach na UE=0
    [Documentation]    2.1: detach jednego UE nie usuwa drugiego. Założenia: attach/detach na granicy UE=100.
    [Tags]    EPC-SM-2-003    req_2    detach    multi_ue    boundary
    When I attach UE with ID 61
    Then response is success
    When I attach UE with ID 62
    Then response is success
    When I detach UE with ID 61
    Then response is success
    When I query attached UE state for ID 61
    Then response is error
    When I query attached UE state for ID 62
    Then response is success
    When I attach UE with ID ${DOC_UE_ID_MAX}
    Then response is success
    When I detach UE with ID ${DOC_UE_ID_MAX}
    Then response is success

# --- 9. Reset (pkt 9) - 2 testy ---

EPC-SM-9-001 Reset - stan początkowy i wyczyszczenie wielu sesji
    [Documentation]    9.1: reset na pustym symulatorze i po wielu attach - brak podłączonych UE.
    [Tags]    EPC-SM-9-001    req_9    reset
    And simulator has no attached UEs
    When I reset the simulator via API
    And simulator has no attached UEs
    When I attach UE with ID 41
    When I attach UE with ID 42
    When I attach UE with ID 43
    When I reset the simulator via API
    And simulator has no attached UEs

EPC-SM-9-002 Reset - brak poprzedniej sesji i ponowny attach z bearerem 9
    [Documentation]    9.1 + 1.4: po resecie stary UE niedostępny; możliwy attach z domyślnym bearerem.
    [Tags]    EPC-SM-9-002    req_9    reset    reattach
    When I attach UE with ID 77
    Then response is success
    When I reset the simulator via API
    When I query attached UE state for ID 77
    Then response is error
    When I attach UE with ID 77
    Then response is success
    When I get UE with ID 77
    Then response is success
    And UE has default bearer per documentation

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

When I query attached UE state for ID ${ue_id}
    When I get UE with ID ${ue_id}

When I list UEs
    ${status_code}    ${body}=    List Ues
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I reset the simulator via API
    Reset Simulator

Then response is success
    Should Be True    ${status_code} >= 200 and ${status_code} < 300    msg=Oczekiwano 2xx wg dokumentacji, otrzymano HTTP ${status_code}: ${body}

Then response is error
    Should Be True    ${status_code} >= 400    msg=Oczekiwano błędu wg dokumentacji, otrzymano HTTP ${status_code}: ${body}

And field ${field_name} has value ${expected_value}
    Should Be Equal    ${body}[${field_name}]    ${expected_value}

And UE has default bearer per documentation
    Dictionary Should Contain Key    ${body}[bearers]    ${DOC_DEFAULT_BEARER}

And simulator has no attached UEs
    When I list UEs
    Then response is success
    Should Be Empty    ${body}[ues]

And UE list is exactly ${ue_id_list}
    @{raw_ids}=    Split String    ${ue_id_list}    separator=,
    ${expected}=    Create List
    FOR    ${ue_id}    IN    @{raw_ids}
        ${trimmed}=    Strip String    ${ue_id}
        ${ue_int}=    Convert To Integer    ${trimmed}
        Append To List    ${expected}    ${ue_int}
    END
    Sort List    ${expected}
    ${actual}=    Copy List    ${body}[ues]
    Sort List    ${actual}
    Lists Should Be Equal    ${actual}    ${expected}
