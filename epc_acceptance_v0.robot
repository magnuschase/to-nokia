
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
    Gdy dołączam UE o ID 42
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    attached
    Gdy pobieram UE o ID 42
    Wtedy status odpowiedzi to    200
    Oraz UE ma bearer o ID    9

Attach UE — Błąd gdy UE ID poza zakresem (0 i 101)
    [Documentation]    1.2 Jeśli UE ID jest spoza zakresu - zostanie wyświetlony błąd.
    [Tags]    attach    validation
    Gdy dołączam UE o ID 0
    Wtedy status odpowiedzi to    422
    Gdy dołączam UE o ID 101
    Wtedy status odpowiedzi to    422

Detach UE — Sukces
    [Documentation]    2.1 UE może zostać odłączony od sieci.
    [Tags]    detach    happy_path
    Gdy dołączam UE o ID 15
    Wtedy status odpowiedzi to    200
    Gdy odłączam UE o ID 15
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    detached
    Gdy pobieram UE o ID 15
    Wtedy status odpowiedzi to    400
    Oraz pole ma wartość    detail    UE not found

Start ruchu DL — Sukces (Mbps)
    [Documentation]    3.1 Transfer danych można rozpocząć tylko w kierunku DL.
    [Tags]    traffic    happy_path
    Gdy dołączam UE o ID 33
    Gdy uruchamiam ruch dla UE 33 na bearerze 9 protokołem tcp z przepustowością 25.5 Mbps
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    traffic_started
    Oraz pole ma wartość liczbową    target_bps    25500000

Pobierz statystyki bearera
    [Documentation]    4.1 Można sprawdzić transfer dla pojedynczego bearera w ramach UE.
    [Tags]    stats
    Gdy dołączam UE o ID 77
    Gdy uruchamiam ruch dla UE 77 na bearerze 9 protokołem tcp z przepustowością 5 Mbps
    Gdy pobieram statystyki ruchu dla UE 77 i bearera 9
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość liczbową    ue_id    77
    Oraz pole ma wartość liczbową    bearer_id    9
    Oraz pole ma wartość    protocol    tcp

Zatrzymanie ruchu dla bearera
    [Documentation]    5.1 Transfer danych można zakończyć dla poszczególnego bearera.
    [Tags]    traffic    stop
    Gdy dołączam UE o ID 11
    Gdy uruchamiam ruch dla UE 11 na bearerze 9 protokołem tcp z przepustowością 12 Mbps
    Gdy zatrzymuję ruch dla UE 11 i bearera 9
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    traffic_stopped

Dodaj dedykowany bearer
    [Documentation]    6.1 Możliwe jest dodanie dedykowanych bearer-ów dla UE.
    [Tags]    bearer    happy_path
    Gdy dołączam UE o ID 21
    Gdy dodaję bearer o ID 4 dla UE 21
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    bearer_added
    Gdy pobieram UE o ID 21
    Oraz UE ma bearer o ID    4

Usuń dedykowany bearer
    [Documentation]    8.1 Możliwe jest usunięcie dedykowanego bearer'a dla UE.
    [Tags]    bearer    happy_path
    Gdy dołączam UE o ID 31
    Gdy dodaję bearer o ID 5 dla UE 31
    Gdy usuwam bearer o ID 5 dla UE 31
    Wtedy status odpowiedzi to    200
    Oraz pole ma wartość    status    bearer_deleted

Usuń bearer — nie można usunąć domyślnego (9)
    [Documentation]    8.4 Nie ma możliwości usunięcia domyślnego bearera.
    [Tags]    bearer    error
    Gdy dołączam UE o ID 32
    Gdy usuwam bearer o ID 9 dla UE 32
    Wtedy status odpowiedzi to    400
    Oraz pole ma wartość    detail    Cannot remove default bearer

Reset symulatora
    [Documentation]    9.1 Możliwe jest przywrócenie symulatora do stanu początkowego.
    [Tags]    reset
    Gdy dołączam UE o ID 41
    Gdy resetuję symulator
    Gdy pobieram listę UE
    Wtedy status odpowiedzi to    200
    Oraz lista UE jest pusta

*** Keywords ***
Gdy dołączam UE o ID ${ue_id}
    ${status_code}    ${body}=    Attach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy odłączam UE o ID ${ue_id}
    ${status_code}    ${body}=    Detach Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy pobieram UE o ID ${ue_id}
    ${status_code}    ${body}=    Get Ue    ${ue_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy pobieram listę UE
    ${status_code}    ${body}=    List Ues
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy dodaję bearer o ID ${bearer_id} dla UE ${ue_id}
    ${status_code}    ${body}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy usuwam bearer o ID ${bearer_id} dla UE ${ue_id}
    ${status_code}    ${body}=    Delete Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy uruchamiam ruch dla UE ${ue_id} na bearerze ${bearer_id} protokołem ${protocol} z przepustowością ${mbps} Mbps
    ${status_code}    ${body}=    Start Traffic Mbps    ${ue_id}    ${bearer_id}    ${protocol}    ${mbps}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy pobieram statystyki ruchu dla UE ${ue_id} i bearera ${bearer_id}
    ${status_code}    ${body}=    Get Bearer Traffic Stats    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy zatrzymuję ruch dla UE ${ue_id} i bearera ${bearer_id}
    ${status_code}    ${body}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Set Test Variable    ${status_code}
    Set Test Variable    ${body}

Gdy resetuję symulator
    Reset Simulator

Wtedy status odpowiedzi to
    [Arguments]    ${expected_status_code}
    Should Be Equal As Integers    ${status_code}    ${expected_status_code}

Oraz pole ma wartość
    [Arguments]    ${field_name}    ${expected_value}
    Should Be Equal    ${body}[${field_name}]    ${expected_value}

Oraz pole ma wartość liczbową
    [Arguments]    ${field_name}    ${expected_value}
    ${expected_int}=    Convert To Integer    ${expected_value}
    Should Be Equal As Integers    ${body}[${field_name}]    ${expected_int}

Oraz UE ma bearer o ID
    [Arguments]    ${bearer_id}
    Dictionary Should Contain Key    ${body}[bearers]    ${bearer_id}

Oraz lista UE jest pusta
    Should Be Empty    ${body}[ues]
