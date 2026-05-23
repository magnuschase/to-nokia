# Evolved Packet Core (EPC) simulator

## Aplikacja umożliwia symulowanie sieci rdzeniowej dla 4G Long-Term Evolution (LTE).

### Założenia

- zakres dostępnych UE: 0-100
- zakres bearerów dla UE: 1-9, bearer numer 9 – domyślnie ustanawiamy przy podłączeniu
- zakres transferu – max 100 Mbps dla UE w kierunku DL

### Funkcjonalności

1. Podłączenie UE do sieci (attach)

- UE może zostać dołączony do sieci
- Procedura wymaga podania UE ID
- Jeśli UE ID jest spoza zakresu - zostanie wyświetlony błąd
- Jeśli UE jest już podłączony do sieci – zostanie wyświetlony błąd
- Podłączony do sieci UE automatycznie otrzymuje domyślny bearer o ID 9

2. Odłączenie UE od sieci (detach)

- UE może zostać odłączony od sieci
- Procedura wymaga podania UE ID
- Jeśli UE nie jest podłączony – zostanie wyświetlony błąd

3. Rozpoczęcie przesyłania danych

- Transfer danych można rozpocząć tylko w kierunku DL
- Procedura wymaga podania szybkości transferu, UE ID oraz bearer ID
- Jeśli szybkość jest spoza zakresu – zostanie wyświetlony błąd
- Jeśli bearer nie jest aktywny – zostanie wyświetlony błąd

4. Sprawdzenie aktualnego transferu

- Można sprawdzić transfer dla pojedynczego bearera w ramach UE lub sumaryczny dla wszystkich jego bearerów
- Procedura wymaga podania UE ID oraz opcjonalnych bearer ID oraz unit
- Domyślną jednostką jest kbps

5. Zakończenie przesyłania danych

- Transfer danych można zakończyć dla poszczególnego bearera w ramach UE lub całkowicie dla wszystkich bearerów
- Procedura wymaga podania UE ID oraz opcjonalnie bearer ID

6. Dodania kanału transportowego (bearer) dla UE

- Możliwe jest dodanie dedykowanych bearer-ów dla UE
- Procedura wymaga podania UE ID oraz bearer ID
- Jeśli bearer jest spoza zakresu – zostanie wyświetlony błąd
- Jeśli bearer został już dodany – zostanie wyświetlony błąd

7. Sprawdzenie podłączonych bearer-ów

- Możliwe jest sprawdzenia aktualnie dostępnych bearerów
- Procedura wymaga podania UE ID

8. Usunięcie kanału transportowego z UE

- Możliwe jest usunięcie dedykowanego bearer’a dla UE
- Procedura wymaga podania UE ID oraz bearer ID
- Jeśli bearer jest spoza zakresu – zostanie wyświetlony błąd
- Jeśli bearer nie jest aktywny – zostanie wyświetlony błąd
- Nie ma możliwości usunięcia domyślnego bearera

9. Zresetowanie symulatora

- Możliwe jest przywrócenie symulatora do stanu początkowego

### Słowniczek:

- UE – User Equipement – sprzęt użytkownika (np. telefon komórkowy)
- Bearer – kanał transportowy w systemach telefonii komórkowej
