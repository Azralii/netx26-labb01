# ITSX26 – Kursvecka 4

# Network Traffic Investigation

## 1. Syfte

Syftet med laborationen var att följa ett pakets väg genom en Linux-miljö och undersöka hur nätverkstrafik kan observeras och analyseras.

Laborationen omfattade:

* nätverkskonfiguration och routing
* trafikfångst med tcpdump
* analys av PCAP med TShark
* DNS
* TCP
* HTTP
* TLS/HTTPS
* CIA-triaden
* brandvägg och hardening

Analysen genomfördes i den egna Linux-VM:n och inga externa system scannades.

---

## 2. Miljö

Laborationen genomfördes på en Linux-VM i Oracle Cloud.

### Nätverksinformation

* Aktivt interface: `ens3`
* Privat IPv4-adress: `10.0.0.127/24`
* Default gateway: `10.0.0.1`
* Loopback: `127.0.0.1`

Default route visade att trafik utanför det lokala nätet skickades via `10.0.0.1` över `ens3`.

DNS-test med `getent hosts example.com` fungerade och returnerade IPv6-adresser.

Ett HTTPS-test med:

```text
curl -I https://example.com
```

returnerade `HTTP/2 200`, vilket visade att HTTPS-kommunikation kunde genomföras från miljön.

En kontroll med:

```text
curl -4 -s https://api.ipify.org
```

returnerade den publika adressen `129.151.199.190`, medan VM:n hade den privata adressen `10.0.0.127`. Detta är förenligt med att adressöversättning/NAT sker någonstans mellan VM:n och Internet. Testet visar dock inte exakt var eller hur NAT genomförs.

---

## 3. Fånga trafik

Tillgängliga nätverksinterface kontrollerades med `tcpdump -D`.

Trafiken fångades på:

```text
ens3
```

PCAP-filen skapades med ett tidsbegränsat tcpdump-kommando.

Resultatet blev:

```text
283 packets captured
283 packets received by filter
0 packets dropped by kernel
```

PCAP-filen sparades lokalt som:

```text
evidence/traffic_week38.pcap
```

En kopia användes för TShark-analysen:

```text
/tmp/traffic_week38.pcap
```

PCAP-filen publicerades inte eftersom rå nätverkstrafik kan innehålla känslig information.

---

## 4. Protokollanalys

TShark användes för att analysera protokollhierarkin.

Resultatet visade:

```text
283 IP-paket

TCP: 281 paket
UDP: 2 paket

SSH: 114 paket
TLS: 13 paket
HTTP: 6 paket
DNS: 2 paket
```

Den stora mängden SSH-trafik beror sannolikt på att Linux-VM:n administrerades via en aktiv SSH-session under trafikfångsten.

Detta är en viktig begränsning eftersom PCAP-filen därför innehåller trafik som inte var en del av den avsedda DNS/HTTP/HTTPS-analysen.

---

# 5. DNS-analys

I PCAP-filen observerades följande DNS-kommunikation:

```text
10.0.0.127 → 169.254.169.254
AAAA telemetry-ingestion.eu-stockholm-1.oci.oraclecloud.com
```

Därefter kom ett DNS-svar:

```text
169.254.169.254 → 10.0.0.127
DNS query response
```

### Observation

Linux-klienten skickade en DNS-fråga till `169.254.169.254` och fick ett svar.

Frågan var av typen `AAAA`, vilket används för att efterfråga en IPv6-adress.

### Slutsats

Det visar att DNS-kommunikation förekom mellan Linux-klienten och DNS-tjänsten under fångstperioden.

### Osäkerhet

DNS-paketen visar inte ensamma vad applikationen därefter gjorde med det upplösta namnet.

---

 # 6. TCP-analys

Ett TCP-flöde observerades mellan:

```text
10.0.0.127
```

och:

```text
129.149.82.80:443
```

I PCAP-filen observerades bland annat:

```text
10.0.0.127 → 129.149.82.80
35882 → 443 [SYN]
```

följt av:

```text
129.149.82.80 → 10.0.0.127
443 → 35882 [SYN, ACK]
```

och därefter ACK-trafik.

### Observation

Det finns tydliga paket som hör till TCP-anslutningens etablering.

### Slutsats

Den observerade trafiken visar att klienten försökte etablera en TCP-anslutning till servern på port 443 och att servern svarade på anslutningsförsöket. Därefter observerades fortsatt trafik i flödet.

### Osäkerhet

En enskild PCAP-fångst visar bara den observerade tidsperioden. Den bevisar inte att servern alltid är tillgänglig.




---

# 7. HTTP-analys

PCAP-filen innehåller HTTP-kommunikation mellan:

```text
10.0.0.127
```

och:

```text
169.254.169.254
```

Tre HTTP GET-förfrågningar observerades:

```text
GET /opc/v2/instance/metadata/runcommand-fast-poll HTTP/1.1
```

Servern svarade i de observerade flödena med:

```text
HTTP/1.1 404 Not Found
```

### Observation

HTTP-förfrågningen och URL-sökvägen kan läsas direkt i paketanalysen.

### Slutsats

Detta visar ett okrypterat HTTP-flöde i labbmiljön där klienten skickar en GET-förfrågan och får ett HTTP-svar.

### Osäkerhet

Detta är trafik mot OCI:s metadataadress `169.254.169.254` och ska därför inte betraktas som ett generellt exempel på vanlig publik webbsurfning.

---

# 8. TLS/HTTPS-analys

Ett TLS-flöde observerades mellan:

```text
10.0.0.127
```

och:

```text
129.149.82.80:443
```

TLS-handshaken innehöll:

```text
Client Hello
Server Hello
Certificate
Server Key Exchange
Server Hello Done
Client Key Exchange
Change Cipher Spec
Encrypted Handshake Message
```

Client Hello innehöll följande SNI:

```text
telemetry-ingestion.eu-stockholm-1.oraclecloud.com
```

Efter handshaken observerades:

```text
TLSv1.2 Application Data
```

i båda riktningarna.

### Observation

Kommunikationen använder TLSv1.2 och applikationsdata överförs efter TLS-handshaken.

### Slutsats

Trafiken visar en etablerad TLS-skyddad kommunikation över port 443. Applikationsdata är krypterad och kan därför inte läsas direkt i PCAP-filen.

### Osäkerhet

PCAP-filen visar inte det faktiska innehållet i den krypterade Application Data-trafiken. Utan relevant nyckelmaterial kan den krypterade datan inte analyseras som klartext.

---

# 9. HTTP jämfört med HTTPS

Analysen visar en tydlig skillnad mellan HTTP och HTTPS.

| Egenskap                | HTTP                           | HTTPS/TLS   |
| ----------------------- | ------------------------------ | ----------- |
| Observerad port         | 80                             | 443         |
| Kryptering              | Nej                            | Ja          |
| HTTP GET synlig         | Ja                             | Inte direkt |
| Applikationsdata läsbar | Ja, för observerad HTTP-trafik | Nej         |
| TLS-handshake           | Nej                            | Ja          |

I HTTP-flödet kunde exempelvis följande ses:

```text
GET /opc/v2/instance/metadata/runcommand-fast-poll
```

I TLS-flödet kunde i stället TLS-handshake och `Application Data` observeras.

Det illustrerar varför TLS används för att skydda applikationsdata under transport.

---

# 10. CIA-triaden

## Confidentiality – konfidentialitet

TLSv1.2 observerades tillsammans med krypterad Application Data.

Det visar att kommunikationen använder kryptering för att skydda applikationsdata under transport.

PCAP-filen visar däremot inte säkerheten i andra delar av systemet, exempelvis hur information skyddas efter att den har mottagits.

## Integrity – integritet

TLS-handshaken innehåller bland annat certifikat, nyckelutbyte och krypterade handshake-meddelanden.

TLS innehåller mekanismer för att skydda kommunikationen mot manipulation under transport.

PCAP-analysen visar att TLS används, men kan inte ensamt bevisa att all information i hela systemet är korrekt eller oförändrad.

## Availability – tillgänglighet

TCP-anslutningen till `129.149.82.80:443` etablerades och Application Data observerades i båda riktningarna.

Det visar att tjänsten var nåbar och kunde kommunicera under den observerade fångstperioden.

Det bevisar däremot inte permanent tillgänglighet.

---

# 11. Brandvägg och hardening

UFW var inte installerat på Linux-VM:n:

```text
sudo: 'ufw': command not found
```

Däremot visade kontroll av nftables att systemet har befintliga filtreringsregler.

Bland reglerna fanns exempelvis en tillåtelse för:

```text
169.254.169.254
TCP port 80
```

samt regler som avvisar annan TCP- och UDP-trafik mot delar av:

```text
169.254.0.0/16
```

Detta är relevant eftersom PCAP-analysen samtidigt visade HTTP-kommunikation med:

```text
169.254.169.254:80
```

### Säkerhetsåtgärder

Under laborationen ändrades inga brandväggsregler.

Fokus låg på observation och dokumentation.

Relevanta hardening-principer är bland annat:

* begränsa onödig nätverkstrafik
* tillåt endast nödvändiga tjänster
* använda krypterade protokoll där det är möjligt
* minimera exponerade tjänster
* övervaka och dokumentera nätverkstrafik
* undvika onödiga privilegier

---

# 12. Observation, slutsats och osäkerhet

Laborationen följde principen:

```text
Observation → Slutsats → Osäkerhet
```

Exempel:

### DNS

**Observation:** DNS-fråga och DNS-svar observerades.

**Slutsats:** DNS-kommunikation fungerade under fångstperioden.

**Osäkerhet:** Fångsten visar inte vad applikationen gjorde efter DNS-upplösningen.

### TCP

**Observation:** SYN och SYN-ACK observerades mot port 443.

**Slutsats:** Den observerade trafiken visar att klienten försökte etablera en TCP-anslutning till servern på port 443 och att servern svarade på anslutningsförsöket. Därefter observerades fortsatt trafik i flödet.

**Osäkerhet:** Fångsten representerar endast en begränsad tidsperiod.

### HTTPS

**Observation:** TLSv1.2-handshake och Application Data observerades.

**Slutsats:** Applikationsdata transporterades över en TLS-skyddad anslutning.

**Osäkerhet:** Det faktiska innehållet kunde inte läsas från PCAP-filen.

### HTTP

**Observation:** HTTP GET-förfrågningar och `404 Not Found` observerades.

**Slutsats:** Ett HTTP-flöde förekom mot OCI:s metadataadress.

**Osäkerhet:** Det är specifik metadata-/labbtrafik och inte ett generellt test av publik HTTP-trafik.

---

# 13. Begränsningar

Laborationen hade flera begränsningar:

* PCAP-filen representerar endast en begränsad tidsperiod.
* SSH-trafik från administration av VM:n fångades samtidigt.
* All observerad trafik var inte en del av den avsedda testtrafiken.
* TLS Application Data kunde inte dekrypteras.
* PCAP-filen visar inte hela nätverkets fysiska eller logiska väg.
* NAT-testet visar effekten av adressöversättning men inte exakt vilken nätverksenhet som genomför den.
* Analysen visar observerad trafik och kan inte användas för att dra slutsatser om systemets säkerhet utanför den observerade miljön.

---

# 14. Evidens

Analysen genomfördes med TShark mot PCAP-filen:

```text
/tmp/traffic_week38.pcap
```

Original-PCAP:

```text
evidence/traffic_week38.pcap
```

Analysresultatet sparades som:

```text
docs/analysis_week38.txt
```

Analys-scriptet:

```text
03_analysera.sh
```

Scriptet analyserar:

* protokollhierarki
* DNS
* TCP
* TLS
* HTTP

PCAP-filen ändras inte av analys-scriptet.

---

# 15. AI-användning

AI användes som stöd under laborationen för:

* förståelse av Linux- och nätverkskommandon
* tolkning av TShark-resultat
* förklaring av DNS, TCP, HTTP och TLS
* strukturering av observationer och slutsatser
* kontroll av rapportens formuleringar

AI-genererade förklaringar verifierades mot den faktiska terminalutmatningen från den egna Linux-miljön.

Slutsatserna i rapporten baseras på observerad trafik och genomförda kommandon.

---

# 16. Sammanfattande slutsats

Laborationen visade hur nätverkstrafik kan följas från en Linux-klient genom adressinformation och routing till faktisk trafikfångst och protokollanalys.

PCAP-analysen identifierade DNS-, TCP-, HTTP-, TLS- och SSH-trafik.

HTTP-trafiken kunde analyseras direkt eftersom innehållet inte var TLS-krypterat. HTTPS-kommunikationen visade däremot en TLSv1.2-handshake följt av krypterad Application Data.

Analysen visade också hur trafikobservationer kan kopplas till säkerhetsprinciper som konfidentialitet, integritet och tillgänglighet.

En central slutsats från laborationen är att en nätverksanalys bör skilja mellan vad som faktiskt observerats, vilken slutsats observationen stöder och vad som fortfarande är osäkert.
