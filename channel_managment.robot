*** Settings ***
Documentation    Testy akceptacyjne API symulatora EPC - Obszar 2: Zarządzanie kanałami (Bearer).
...              Obejmuje funkcjonalności: 6 (Dodawanie), 7 (Sprawdzanie), 8 (Usuwanie).
...              Przed uruchomieniem: docker run -p 8000:8000 epc-simulator:1.0.0
Library          EpcApiLibrary.py    ${EPC_BASE_URL}
Library          Collections
Test Setup       Reset Simulator

*** Variables ***
${EPC_BASE_URL}    http://localhost:8000

*** Test Cases ***

06.01 Dodaj dedykowany bearer - Sukces
    [Documentation]    6. Możliwe jest dodanie dedykowanych bearer-ów dla UE.
    [Tags]    bearer    add    happy_path
    When I attach UE with ID 21
    When I add bearer with ID 4 for UE 21
    Then response is success
    And field has value    status    bearer_added
    When I get UE with ID 21
    And UE has bearer with ID    4

06.02 Dodaj bearer - Błąd gdy ID poza zakresem
    [Documentation]    6. Jeśli bearer jest spoza zakresu (1-9) - zostanie wyświetlony błąd.
    [Tags]    bearer    add    validation
    When I attach UE with ID 22
    # Próba dodania bearera poniżej zakresu
    When I add bearer with ID 0 for UE 22
    Then response is error
    # Próba dodania bearera powyżej zakresu
    When I add bearer with ID 10 for UE 22
    Then response is error

06.03 Dodaj bearer - Błąd gdy bearer został już dodany
    [Documentation]    6. Jeśli bearer został już dodany - zostanie wyświetlony błąd.
    [Tags]    bearer    add    error
    When I attach UE with ID 23
    # Próba dodania bearera 9, który jest przypisywany domyślnie przy attach
    When I add bearer with ID 9 for UE 23
    Then response is error
    # Dodanie poprawnego bearera, a następnie próba jego duplikacji
    When I add bearer with ID 5 for UE 23
    Then response is success
    When I add bearer with ID 5 for UE 23
    Then response is error

07.01 Sprawdzenie podłączonych bearer-ów - Sukces
    [Documentation]    7. Możliwe jest sprawdzenia aktualnie dostępnych bearerów dla UE.
    [Tags]    bearer    check    happy_path
    When I attach UE with ID 24
    When I add bearer with ID 2 for UE 24
    When I add bearer with ID 3 for UE 24
    When I get UE with ID 24
    Then response is success
    # Weryfikacja czy UE posiada domyślny bearer oraz dwa nowo dodane
    And UE has bearer with ID    9
    And UE has bearer with ID    2
    And UE has bearer with ID    3

08.01 Usuń dedykowany bearer - Sukces
    [Documentation]    8. Możliwe jest usunięcie dedykowanego bearer'a dla UE.
    [Tags]    bearer    delete    happy_path
    When I attach UE with ID 31
    When I add bearer with ID 5 for UE 31
    When I delete bearer with ID 5 for UE 31
    Then response is success
    And field has value    status    bearer_deleted

08.02 Usuń bearer - Błąd gdy ID poza zakresem
    [Documentation]    8. Jeśli bearer jest spoza zakresu - zostanie wyświetlony błąd.
    [Tags]    bearer    delete    validation
    When I attach UE with ID 32
    When I delete bearer with ID 0 for UE 32
    Then response is error
    When I delete bearer with ID 10 for UE 32
    Then response is error

08.03 Usuń bearer - Błąd gdy bearer nie jest aktywny
    [Documentation]    8. Jeśli bearer nie jest aktywny - zostanie wyświetlony błąd.
    [Tags]    bearer    delete    error
    When I attach UE with ID 33
    # Próba usunięcia bearera nr 5, który nie został wcześniej dodany
    When I delete bearer with ID 5 for UE 33
    Then response is error

08.04 Usuń bearer - Nie można usunąć domyślnego (9)
    [Documentation]    8. Nie ma możliwości usunięcia domyślnego bearera.
    [Tags]    bearer    delete    error
    When I attach UE with ID 34
    When I delete bearer with ID 9 for UE 34
    Then response is error



*** Keywords ***
When I attach UE with ID ${ue_id}
    ${status_code}    ${body}=    Attach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

When I get UE with ID ${ue_id}
    ${status_code}    ${body}=    Get Ue    ${ue_id}
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

When I reset the simulator
    Reset Simulator

Then response is success
    [Documentation]    Sprawdza, czy kod HTTP to sukces (od 200 do 299).
    Should Be True    200 <= ${status_code} < 300    msg=Oczekiwano sukcesu (2xx), ale otrzymano ${status_code}

Then response is error
    [Documentation]    Sprawdza, czy kod HTTP to błąd klienta/serwera (400 lub więcej).
    Should Be True    ${status_code} >= 400    msg=Oczekiwano błędu (>=400), ale otrzymano ${status_code}

And field has value
    [Arguments]    ${field_name}    ${expected_value}
    Should Be Equal    ${body}[${field_name}]    ${expected_value}

And UE has bearer with ID
    [Arguments]    ${bearer_id}
    Dictionary Should Contain Key    ${body}[bearers]    ${bearer_id}