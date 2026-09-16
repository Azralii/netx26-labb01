# ITSX26 – Kursvecka 3

## Secure Network Check

### 1. Miljö

Arbetet genomfördes i en Linux-miljö på Oracle Cloud Infrastructure (OCI).

* VM: `ITSX26-Linux`
* Operativsystem: Ubuntu 26.04 LTS
* Linux kernel: 7.0.0-1009-oracle
* Nätverksinterface: `ens3`
* Privat IPv4-adress: `10.0.0.127/24`
* Default gateway: `10.0.0.1`
* Arbetsmapp: `/home/ubuntu/training/secure-network-check`
* Python: 3.14.4

Den lokala testtjänsten kördes endast på `127.0.0.1:8080`.

Den privata IP-adressen används inne i OCI-nätverket. Den publika adressen observerades som `129.151.199.190` vid en extern kontroll. Skillnaden mellan den privata och publika adressen visar effekten av adressöversättning (NAT), men kontrollen visar inte exakt var eller hur NAT-tabellen är konfigurerad.

### 2. Manuella nätverkskontroller

#### `ip -br address`

Kontrollen visade två relevanta interface:

* `lo` med `127.0.0.1`
* `ens3` med `10.0.0.127/24`

Det visar vilka nätverksinterface och IP-adresser som finns i Linuxmiljön.

#### `ip route`

Default route var:

```text
default via 10.0.0.1 dev ens3
```

Det innebär att trafik till andra nätverk skickas via gateway `10.0.0.1`.

Den lokala routingen visar också att `10.0.0.0/24` är direkt anslutet via `ens3`.

#### `hostname -I`

Resultatet var:

```text
10.0.0.127
```

Det bekräftar den IP-adress som systemet rapporterar som lokal adress.

#### `getent hosts example.com`

DNS-uppslaget returnerade IPv6-adresser för `example.com`.

Det visar att namnupplösning fungerar. Ett lyckat DNS-uppslag bevisar däremot inte att HTTP/HTTPS eller en specifik applikationstjänst är tillgänglig.

#### `ss -tuln`

Kontrollen användes för att se vilka TCP- och UDP-sockets som lyssnar lokalt.

Bland annat observerades SSH på port 22. SSH behövs för den administrativa anslutningen till VM:n.

Kontrollen används som en lokal hardening-kontroll eftersom oväntade lyssnande tjänster kan behöva undersökas.

`ss -tuln` visar lokala lyssnande sockets, men bevisar inte ensamt vilka portar som är åtkomliga från Internet. OCI:s nätverksregler och andra brandväggslager påverkar också extern åtkomst.

### 3. Lokal testtjänst

En enkel Python HTTP-server startades med:

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

Genom att binda tjänsten till `127.0.0.1` begränsades den till lokal åtkomst.

Kontrollen:

```bash
curl -I http://127.0.0.1:8080
```

returnerade:

```text
HTTP/1.0 200 OK
```

Det visar att den lokala tjänsten svarade korrekt.

Kontrollen:

```bash
ss -tuln | grep 8080
```

visade att `127.0.0.1:8080` var i LISTEN-läge när testtjänsten kördes.

Efter testningen stoppades Python-servern med `Ctrl+C`.

### 4. Bash-skript

Skriptet finns i repositoryt som:

```text
scripts/secure_network_check.sh
```

Skriptets syfte är att kontrollera och dokumentera den egna Linuxmiljön. Säkerhetsavgränsningen är att endast lokala kontroller och godkända mål används. Skriptet gör inga ändringar av brandväggsregler och utför ingen extern nätverksskanning.

Den slutliga versionen av skriptet innehåller bland annat:

* variabler för loggfil, felräkning och DNS-namn
* funktion för loggning med tidsstämpel
* funktion för kontroll av nätverksmiljö
* funktion för DNS-kontroll
* funktion för kontroll av lokal HTTP-tjänst
* funktion för kontroll av lokalt lyssnande portar
* `if`-villkor för resultat och felhantering
* loop över en liten, fördefinierad lista av kontroller
* kontroll av tomt DNS-värde
* tydliga statusmeddelanden med `OK`, `FAIL` och `WARN`
* exitkod `0` när kontrollerna lyckas
* exitkod `1` när minst en kontroll misslyckas
* borttagning av den temporära fil som används vid portkontrollen

Scriptet skapar en timestampad logg med namnet:

```text
network_check.log
```

Loggen sparas lokalt och innehåller resultaten från kontrollerna. Loggfilen ska inte publiceras i repositoryt om den innehåller känslig information.

### 5. Testmatris

| Test                                  | Förväntat resultat      | Faktiskt resultat   | Status  |
| ------------------------------------- | ----------------------- | ------------------- | ------- |
| Normalfall 1 – DNS                    | DNS fungerar, exit 0    | DNS OK, exit 0      | Godkänt |
| Normalfall 2 – lokal tjänst           | Tjänsten svarar, exit 0 | HTTP 200 OK, exit 0 | Godkänt |
| Felfall 1 – ogiltigt DNS-namn         | FAIL, exit 1            | DNS FAIL, exit 1    | Godkänt |
| Felfall 2 – ingen tjänst på port 8080 | FAIL, exit 1            | Tjänst FAIL, exit 1 | Godkänt |

#### Normalfall 1 – DNS

`example.com` kunde lösas med DNS.

Scriptet rapporterade:

```text
OK: DNS fungerar för example.com
```

#### Normalfall 2 – lokal tjänst

En tillfällig Python HTTP-server startades på:

```text
127.0.0.1:8080
```

Scriptet rapporterade:

```text
OK: Lokal tjänst svarar på port 8080
```

Scriptet avslutades med exitkod `0`.

#### Felfall 1 – ogiltigt DNS-namn

Följande ogiltiga DNS-namn användes:

```text
invalid-domain-that-does-not-exist.example
```

Scriptet rapporterade:

```text
FAIL: DNS fungerar inte för invalid-domain-that-does-not-exist.example
```

Scriptet fortsatte därefter med övriga kontroller och avslutades med exitkod `1`.

Det visar att ett DNS-fel kan upptäckas och rapporteras utan att scriptet kraschar okontrollerat.

#### Felfall 2 – ingen lokal tjänst

Den tillfälliga HTTP-servern stoppades innan testet.

Scriptet rapporterade:

```text
FAIL: Ingen fungerande tjänst på port 8080
```

Scriptet fortsatte att köra övriga kontroller och avslutades med exitkod `1`.

### 6. Koppling till vecka 36 – hardening

Arbetet bygger vidare på hardening från vecka 36.

Kommandot:

```bash
ss -tuln
```

kan användas för att kontrollera vilka portar och tjänster som lyssnar lokalt.

Efter hardening bör lyssnande tjänster motsvara systemets behov. SSH på port 22 behöver exempelvis finnas kvar i denna labbmiljö eftersom SSH används för administration av VM:n.

Kontrollen av lyssnande portar kan därför användas för att upptäcka oväntade tjänster som behöver undersökas.

Ingen ändring av OCI:s brandväggs- eller säkerhetsregler gjordes som en del av denna uppgift.

### 7. Backup och recovery

Efter en recovery bör grundläggande nätverksfunktion kontrolleras innan systemet betraktas som återställt.

Två av de första kontrollerna bör vara:

1. `ip -br address` och `ip route` för att verifiera interface, IP-adress och default route.
2. `getent hosts example.com` för att verifiera DNS-upplösning.

Därefter kan lokala tjänster och lyssnande portar kontrolleras med exempelvis `ss -tuln`.

### 8. CIA-triaden

#### Confidentiality – konfidentialitet

Nätverkskontroller kan visa information om systemets adresser, portar och tjänster. Därför ska känslig eller osanerad utdata inte publiceras.

Den lokala testtjänsten bands till:

```text
127.0.0.1
```

vilket begränsar tjänstens åtkomst till den lokala maskinen jämfört med att binda den till alla interface.

Råa PCAP-filer och känsliga loggar ska inte publiceras osanerade.

#### Integrity – integritet

Skriptet använder reproducerbara kontroller och loggar resultaten med tidsstämplar.

Exitkoder gör resultatet tydligare för andra verktyg och möjliggör framtida automatisering.

Git används för versionshantering av scriptet och dokumentationen, vilket gör förändringar spårbara.

#### Availability – tillgänglighet

Kontrollen av DNS, routing och den lokala tjänsten kan användas för att verifiera om grundläggande nätverksfunktioner och en förväntad tjänst fungerar.

Efter recovery kan samma typer av kontroller användas för att verifiera att systemet fungerar igen.

### 9. Begränsningar

Resultaten gäller den aktuella OCI-miljön och kan skilja sig från WSL eller lokal Linux.

Exempelvis kan tillgängliga interface, nätverksadresser, DNS-konfiguration och lyssnande tjänster skilja sig mellan miljöerna.

`ss -tuln` visar vilka portar som lyssnar lokalt men bevisar inte ensamt vilka portar som är åtkomliga från Internet. OCI:s nätverkslager, säkerhetsregler och eventuella brandväggar är separata lager.

Ett lyckat DNS-uppslag visar namnupplösning men bevisar inte att en webbtjänst eller annan applikation är tillgänglig.

Testerna är därför observationer från den aktuella labbmiljön och ska inte tolkas som en fullständig säkerhetskontroll av ett produktionssystem.

### 10. Cleanup och säkerhet

Den tillfälliga Python-testtjänsten på port 8080 stoppades efter testningen.

Port 8080 kontrollerades därefter och ingen tjänst lyssnade längre där.

Skriptets temporära portkontrollfil tas bort efter kontrollen.

Inga privata nycklar, lösenord eller tokens används av skriptet.

Råa PCAP-filer, känsliga loggar och annan osanerad evidence ska inte publiceras i repositoryt.

### 11. Evidence

Testresultaten och information om genomförda kontroller dokumenteras även i:

```text
evidence/README.md
```

Evidence-filen innehåller exempel på normaltester och feltester samt information om säkerhet och sanering.

### 12. AI-användning

AI användes som stöd för att förstå uppgiftens instruktioner, tolka Linux-kommandon, felsöka Bash-kod och strukturera dokumentationen.

Alla kommandon och tester kördes och verifierades i den egna Linuxmiljön.

Resultaten i rapporten bygger på de faktiska tester som genomfördes i VM:n.

AI användes som stöd och inte som ersättning för att själv genomföra och verifiera kontrollerna.

### 13. Slutsats

Secure Network Check visar hur Bash kan användas för reproducerbara och begripliga kontroller av en Linuxmiljö.

Arbetet omfattar nätverksinterface, routing, DNS, lokala lyssnande portar och en lokal testtjänst. Scriptet hanterar både normala och felaktiga situationer och använder tydliga statusmeddelanden samt exitkoder.

Kontrollerna är avgränsade till den egna labbmiljön och är därför utformade för säker användning utan extern scanning eller förändringar av brandväggsregler.
