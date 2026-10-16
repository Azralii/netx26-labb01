# Security Automation Report – Vecka 39

## Syfte
Syftet är att automatisera analys av säkerhetsloggar med Python och identifiera misstänkta IP-adresser genom jämförelse med en IOC-lista.

## Metod
Jag använde Python för att läsa loggfiler, identifiera misslyckade inloggningar och jämföra IP-adresser mot en lista med kända indikatorer (IOC).

Följande filer användes:
- docs/Data/auth.log
- docs/Data/access.log
- docs/Data/firewall.log
- docs/Data/suspicious_ips.txt

## Resultat
- Misslyckade inloggningar: 4
- Överhoppade felaktiga loggrader: 1

### IOC-träffar
- 198.51.100.44: 1 träff
- 203.0.113.15: 2 träffar

### IOC-träffar i brandväggsloggen
- 203.0.113.15: 1 träff
- 203.0.113.99: 1 träff

## Analys
Loggarna innehåller IP-adresser som finns i den givna IOC-listan. Dessa händelser kan behöva granskas vidare för att avgöra om de är säkerhetsrelaterade.

## Begränsningar
En IOC-träff innebär inte automatiskt att ett angrepp eller en säkerhetsincident har inträffat. Resultaten behöver sättas i sitt sammanhang.

## Slutsats
Python kan användas för att automatisera logganalys, identifiera misstänkta IP-adresser och skapa en enkel säkerhetsrapport.

## Evidens

Jag körde Python-skriptet `app/security_report.py` för att analysera loggfilerna.

Resultatet från körningen:

```text
Failed logins: 4
Skipped rows: 1

IOC matches:
198.51.100.44: 1
203.0.113.15: 2

Firewall IOC matches:
203.0.113.15: 1
203.0.113.99: 1
