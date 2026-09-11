# Week 36 OCI Cloud Security Lab

## 1. Min OCI-miljö

* **Tenancy:** N/A
* **Compartment:** N/A
* **Region:** Sweden Central (Stockholm)
* **Availability Domain:** AD-1
* **VM-namn/hostname:** ITSX26-Linux / itsx26-linux
* **Operativsystem:** Ubuntu 26.04 LTS
* **Shape:** VM.Standard.E2.1.Micro
* **Hardware:** 1 OCPU, 1 GB RAM
* **Boot volume:** 50 GB
* **Inloggningsmetod:** SSH med SSH-nyckel
* **Användare:** ubuntu

Jag skapade en Linux-VM i Oracle Cloud Infrastructure (OCI) och anslöt till den via SSH. Syftet var att undersöka Linux-systemet och genomföra grundläggande säkerhetskontroller.

---

## 2. Linux-kommandon

| Kommando   | Vad visar det?                                              | Resultat / betydelse                                         | CIA-koppling                                                                    |
| ---------- | ----------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| `whoami`   | Visar vilken användare jag är inloggad som.                 | Resultatet var `ubuntu`.                                     | **Confidentiality:** hjälper till att kontrollera identitet och åtkomst.        |
| `hostname` | Visar datorns/VM:ns namn.                                   | Resultatet var `itsx26-linux`.                               | **Integrity:** hjälper till att säkerställa att jag arbetar mot rätt system.    |
| `pwd`      | Visar aktuell katalog.                                      | Resultatet var `/home/ubuntu`.                               | **Integrity:** minskar risken att ändra filer på fel plats.                     |
| `uname -a` | Visar information om kernel, operativsystem och arkitektur. | Ubuntu/Linux-system med Oracle-kernel och x86_64-arkitektur. | **Integrity:** hjälper till att identifiera systemets tekniska miljö.           |
| `uptime`   | Visar hur länge systemet varit igång och load average.      | Systemet hade varit igång cirka 34 minuter vid kontrollen.   | **Availability:** visar information om systemets tillgänglighet och belastning. |

Jag använde även `ls -la` för att visa filer, inklusive dolda filer, samt filernas ägare och rättigheter.

---

## 3. Hardening

| Kontroll              | Risk                                      | Vad gjorde jag?                                                                                     | Hur verifierade jag?                                                                      | CIA                            |
| --------------------- | ----------------------------------------- | --------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------ |
| Identity/behörigheter | Fel användare eller för mycket behörighet | Kontrollerade användaren med `whoami`, samt användar- och gruppinformation med `id` och `groups`.   | Kontrollerade vilken användare jag var inloggad som och vilka grupper användaren tillhör. | Confidentiality / Integrity    |
| Filrättigheter        | Obehörig åtkomst till filer               | Skapade en testfil och kontrollerade rättigheterna med `ls -l`. Ändrade testfilen till `chmod 600`. | Kontrollerade att endast ägaren hade läs- och skrivrättigheter.                           | Confidentiality                |
| Uppdateringar         | Kända säkerhetssårbarheter                | Kör­de `sudo apt update` och kontrollerade tillgängliga uppdateringar med `apt list --upgradable`.  | Kontrollerade resultatet från APT.                                                        | Integrity / Availability       |
| Processer             | Okända eller misstänkta processer         | Kontrollerade aktiva processer med `ps aux \| head`.                                                | Granskade vilka processer som kördes på systemet.                                         | Integrity                      |
| Loggar                | Säkerhetshändelser kan missas             | Kontrollerade systemloggar med `journalctl -n 20`.                                                  | Granskade de senaste loggraderna.                                                         | Integrity / Availability       |
| SSH                   | Obehörig fjärråtkomst                     | Använde SSH med SSH-nyckel för att ansluta till VM:n.                                               | SSH-inloggningen fungerade med min SSH-nyckel.                                            | Confidentiality / Availability |

### Filrättigheter

Jag använde följande typ av kontroll:

```bash
touch test.txt
ls -l test.txt
chmod 600 test.txt
ls -l test.txt
```

`chmod 600` innebär att ägaren får läsa och skriva filen medan andra användare inte får några rättigheter. Detta minskar risken för obehörig åtkomst.

---

## 4. Recovery-plan

### Vad kan gå fel?

Exempel på problem är:

* SSH-inloggningen fungerar inte.
* VM:n är inte tillgänglig.
* Nätverkskonfigurationen är fel.
* En uppdatering orsakar problem.
* Viktiga filer eller systeminställningar har ändrats.
* VM:n eller dess disk går förlorad.

### Hur upptäcker jag problemet?

Jag börjar med att kontrollera om VM:n fortfarande är igång och om nätverket fungerar. Därefter kontrollerar jag SSH, systemstatus och eventuella loggar.

Exempel på kontroller:

```bash
uptime
```

```bash
ss -tuln
```

```bash
journalctl -n 20
```

### Vad kontrollerar jag först?

1. Att VM:n är igång i OCI.
2. Att nätverket fungerar.
3. Att SSH är tillgängligt.
4. Att rätt SSH-nyckel används.
5. Att användaren är korrekt.
6. Systemloggar och eventuell felinformation.

### Hur återställer jag åtkomst?

Om SSH inte fungerar kontrollerar jag först OCI-instansen, nätverksinställningar och SSH-konfigurationen. Om problemet inte går att lösa kan jag behöva använda recovery-metoder i OCI eller återskapa VM:n från en backup.

### När behöver jag hjälp?

Jag behöver hjälp om jag inte kan identifiera orsaken, om en systemändring har gjort VM:n otillgänglig eller om jag riskerar att förstöra data genom att försöka reparera systemet själv.

---

## 5. Backup

### Vad har jag sparat?

Jag har arbetat med backup-tänkande och skapade en OCI Boot Volume Backup före recovery-arbete.

Backupen heter:

`ITSX26-before-recovery`

Den användes som en säkerhetspunkt för boot-volymen.

### Vad finns i GitHub?

GitHub innehåller bland annat:

* dokumentation
* rapporter
* scripts
* kod och konfigurationsrelaterat material som jag själv har sparat i repot

### Vad kan återskapas?

Om VM:n försvinner kan delar av miljön återskapas genom att skapa en ny VM och installera/configurera program och inställningar igen. Dokumentation och scripts som finns i GitHub kan användas som underlag.

### Vad går inte automatiskt att återskapa?

GitHub innehåller inte automatiskt hela den körande OCI-miljön. Exempelvis kan aktuell VM-status, vissa manuella inställningar och data som endast fanns på VM:n gå förlorade om de inte har sparats separat.

En backup av boot-volymen kan därför vara viktig för recovery.

---

## 6. Cleanup

### VM-instans

Jag kontrollerar VM-instansen i OCI och ser vilka resurser som fortfarande finns kvar.

### Diskar

Jag kontrollerar boot-volymen och eventuella andra diskar som hör till VM:n.

### Backuper

Jag kontrollerar vilka boot volume backups som finns och om de fortfarande behövs.

### Publika IP-adresser

Jag kontrollerar om VM:n har en publik IP-adress och om den fortfarande behövs.

### GitHub-evidens

GitHub-repot behålls eftersom det innehåller kursens dokumentation och evidens.

Cleanup innebär att onödiga resurser ska tas bort, men resurser som fortfarande behövs för kursens arbete ska inte tas bort av misstag.

För att vara säker på att inga onödiga kostnader finns kvar behöver jag kontrollera OCI-resurserna efter labben, inklusive VM, boot-volymer, backups och eventuella publika resurser.

---

## 7. CIA-reflektion

### Konfidentialitet

Konfidentialitet handlar om att information bara ska vara tillgänglig för behöriga personer.

I labben kopplade jag detta till:

* SSH-nyckel för säker inloggning.
* kontroll av användare med `whoami`.
* kontroll av grupper och behörigheter med `id` och `groups`.
* kontroll av filrättigheter med `ls -la` och `chmod 600`.

### Integritet

Integritet handlar om att information och system inte ska ändras obehörigt.

I labben kopplade jag detta till:

* kontroll av systeminformation med `uname -a`.
* kontroll av processer med `ps aux`.
* kontroll av filägare och filrättigheter.
* kontroll av systemloggar med `journalctl`.
* uppdatering av systemet genom APT.

### Tillgänglighet

Tillgänglighet handlar om att systemet ska vara åtkomligt när det behövs.

I labben kopplade jag detta till:

* `uptime` för att se systemets uptime och belastning.
* SSH för fjärråtkomst.
* loggar för felsökning.
* backup för att kunna återställa systemet vid problem.

---

## 8. Reflektion

### Vad fungerade bra?

Det fungerade bra att skapa Linux-VM:n i OCI och ansluta till den med SSH. Jag kunde använda grundläggande Linux-kommandon för att undersöka användare, systeminformation, filer, processer och loggar.

### Vad var svårt?

Det svåraste var att förstå hur olika Linux-kommandon hänger ihop med säkerhet. Det var också viktigt att skilja mellan vad jag faktiskt hade verifierat och vad som bara var möjliga säkerhetsåtgärder.

### Vad lärde jag mig?

Jag lärde mig hur en Linux-server kan undersökas ur ett säkerhetsperspektiv. Jag fick bättre förståelse för användarbehörigheter, filrättigheter, SSH, uppdateringar, processer och loggar.

Jag lärde mig också att recovery och backup är viktiga delar av säkerhet. Säkerhet handlar inte bara om att förhindra problem utan även om att kunna upptäcka problem och återställa systemet.

---

## Frågor till handledningen

* Hur bör SSH skyddas ytterligare?
* Vilka portar behöver vara öppna på VM:n?
* Vilka hardening-åtgärder ska vi genomföra under labben?
* Hur verifierar vi att brandvägg och SSH-konfiguration är säkra?
