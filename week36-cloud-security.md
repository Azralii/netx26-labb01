# Week 36 – Cloud Security

## 1. VM-information

* Projekt: ITSX26 Cloud Security Foundations
* VM-namn: ITSX26-Linux
* Cloud provider: Oracle Cloud Infrastructure (OCI)
* Region: Sweden Central (Stockholm)
* Availability Domain: AD-1
* OS: Ubuntu 26.04
* Inloggningsmetod: SSH med SSH-nyckel
* Användare: ubuntu

## 2. Linux-kommandon

### whoami

Visar vilken användare jag är inloggad som.

Resultat:

```text
ubuntu
```

**Säkerhetskoppling:** Hjälper till att kontrollera identitet och åtkomst.

### hostname

Visar namnet på den dator/VM som jag är ansluten till.

Resultat:

```text
itsx26-linux
```

**Säkerhetskoppling:** Hjälper till att identifiera rätt system.

### pwd

Visar vilken katalog jag befinner mig i.

Resultat:

```text
/home/ubuntu
```

**Säkerhetskoppling:** Ger kontroll över var jag arbetar i filsystemet.

### ls -la

Visar filer och kataloger, inklusive dolda filer, samt information om rättigheter och ägare.

**Säkerhetskoppling:** Kan användas för att kontrollera filrättigheter och ägarskap.

### uname -a

Visar information om Linux-systemet, bland annat kernel, operativsystem och arkitektur.

Resultat:

```text
Linux itsx26-linux 7.0.0-1009-oracle x86_64 GNU/Linux
```

**Säkerhetskoppling:** Hjälper till att identifiera systemversion och teknisk miljö.

### uptime

Visar hur länge systemet har varit igång samt systemets load average.

Resultat:

```text
09:24:26 up 34 min, 1 user, load average: 0.11, 0.15, 0.17
```

**Säkerhetskoppling:** Ger information om systemets tillgänglighet och belastning.

## 3. Hardening-checklista

| Område         | Risk                             | Åtgärd                                      | Verifiering                            |
| -------------- | -------------------------------- | ------------------------------------------- | -------------------------------------- |
| SSH            | Obehörig inloggning              | Använd SSH-nyckel och begränsa åtkomst      | Testa SSH-inloggning                   |
| Användare      | För mycket behörighet            | Begränsa sudo och använd minsta privilegium | Kontrollera sudo-behörigheter          |
| Uppdateringar  | Kända sårbarheter                | Installera säkerhetsuppdateringar           | Kontrollera tillgängliga uppdateringar |
| Brandvägg      | Oönskad nätverkstrafik           | Konfigurera brandvägg                       | Kontrollera brandväggens status        |
| Loggar         | Säkerhetshändelser upptäcks inte | Kontrollera systemloggar                    | Använd `journalctl`                    |
| Backup         | Data kan gå förlorad             | Använd snapshots/backup                     | Kontrollera backup/snapshot            |
| Filrättigheter | Obehörig åtkomst                 | Kontrollera ägare och rättigheter           | Använd `ls -la`                        |

## 4. CIA-triaden

### Confidentiality

Skydda information från obehörig åtkomst.

Exempel från labben:

* SSH-nyckel för inloggning
* kontroll av användare med `whoami`
* kontroll av filrättigheter med `ls -la`

### Integrity

Säkerställa att system och information inte ändras på ett obehörigt sätt.

Exempel:

* kontroll av systeminformation med `uname -a`
* kontroll av filägare och rättigheter

### Availability

Säkerställa att systemet är tillgängligt när det behövs.

Exempel:

* `uptime` visar systemets tillgänglighet och belastning
* backup och snapshots kan hjälpa till vid återställning

## 5. Frågor till handledningen

* Hur bör SSH skyddas ytterligare?
* Vilka portar behöver vara öppna på VM:n?
* Vilka hardening-åtgärder ska vi genomföra under labben?
* Hur verifierar vi att brandvägg och SSH-konfiguration är säkra?

