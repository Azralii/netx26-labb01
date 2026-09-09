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
* Arbetsmapp: `/home/ubuntu/week3-secure-network-check`
* Python: 3.14.4

Testtjänsten kördes endast lokalt på `127.0.0.1:8080`.

### 2. Manuella nätverkskontroller

#### `ip address`

Kontrollen visade två interface:

* `lo` med `127.0.0.1`
* `ens3` med `10.0.0.127/24`

Det visar vilka nätverksinterface och IP-adresser som finns i Linuxmiljön.

#### `ip route`

Default route var:

`default via 10.0.0.1 dev ens3`

Det innebär att trafik till andra nätverk skickas via gateway `10.0.0.1`.

#### `hostname -I`

Resultatet var:

`10.0.0.127`

Det bekräftar VM:ns rapporterade IP-adress.

#### `getent hosts example.com`

DNS-uppslaget returnerade IPv6-adresser för `example.com`.

Det visar att namnupplösning fungerar. Ett lyckat DNS-uppslag bevisar däremot inte att HTTP/HTTPS eller en specifik tjänst är tillgänglig.

#### `ss -tuln`

Kontrollen visade bland annat:

* TCP port 22 – SSH
* TCP/UDP port 53 – lokal DNS/name resolution
* TCP/UDP port 111 – RPC-portmapper
* UDP port 68 – DHCP-relaterad trafik

SSH på port 22 behövs för den SSH-anslutning som används till VM:n.

### 3. Lokal testtjänst

En enkel Python HTTP-server startades med:

`python3 -m http.server 8080 --bind 127.0.0.1`

Genom att binda tjänsten till `127.0.0.1` begränsades den till lokal åtkomst.

Kontrollen:

`curl -I http://127.0.0.1:8080`

returnerade:

`HTTP/1.0 200 OK`

Det visar att den lokala tjänsten svarade korrekt.

Kontrollen:

`ss -tuln | grep 8080`

visade:

`127.0.0.1:8080`

i LISTEN-läge.

### 4. Bash-skript

Skriptet finns som:

`scripts/secure_network_check.sh`

Skriptet använder:

* variabler
* funktioner
* `if`-villkor
* loop
* loggning med tidsstämpel
* exitkoder

Skriptet kontrollerar DNS och en lokal tjänst på port 8080.

Resultaten loggas i:

`network_check.log`

Skriptet avslutar med exitkod `0` när kontrollerna lyckas och exitkod `1` när minst en kontroll misslyckas.

### 5. Testmatris

| Test                                  | Förväntat resultat      | Faktiskt resultat   | Status  |
| ------------------------------------- | ----------------------- | ------------------- | ------- |
| Normalfall 1 – DNS                    | DNS fungerar, exit 0    | DNS OK, exit 0      | Godkänt |
| Normalfall 2 – lokal tjänst           | Tjänsten svarar, exit 0 | HTTP 200 OK, exit 0 | Godkänt |
| Felfall 1 – ogiltigt DNS-namn         | FAIL, exit 1            | DNS FAIL, exit 1    | Godkänt |
| Felfall 2 – ingen tjänst på port 8080 | FAIL, exit 1            | Tjänst FAIL, exit 1 | Godkänt |

Det kontrollerade felfallet är värdefullt eftersom det visar att skriptet kan upptäcka ett problem och rapportera det utan att krascha okontrollerat.

### 6. Koppling till vecka 36

Arbetet bygger vidare på hardening från vecka 36.

`ss -tuln` kan användas för att kontrollera vilka portar och tjänster som är exponerade lokalt. Efter hardening bör endast nödvändiga tjänster finnas kvar.

Efter en recovery bör nätverkskontroller genomföras igen. IP-adress, default route, DNS och viktiga tjänster bör verifieras innan systemet betraktas som återställt.

Den lokala testtjänsten stoppades efter testningen för att lämna miljön i ett känt tillstånd.

### 7. CIA-triaden

#### Confidentiality – konfidentialitet

Nätverkskontroller kan visa information om systemets adresser, portar och tjänster. Därför ska känslig eller osanerad utdata inte publiceras.

Att testtjänsten binds till `127.0.0.1` minskar exponeringen jämfört med att lyssna på alla nätverksinterface.

#### Integrity – integritet

Skriptet använder reproducerbara kontroller och loggar resultaten med tidsstämplar. Det gör det lättare att se vad som har kontrollerats och vilket resultat som erhölls.

Exitkoder gör resultatet tydligare för andra verktyg och framtida automatisering.

#### Availability – tillgänglighet

Kontrollen av den lokala tjänsten visar om en förväntad tjänst svarar. Efter recovery kan liknande kontroller användas för att verifiera att systemets funktioner fungerar igen.

### 8. Begränsningar

Resultaten gäller den aktuella OCI-miljön och kan skilja sig från WSL eller lokal Linux.

`ss -tuln` visar vilka portar som lyssnar lokalt men bevisar inte ensam vilka portar som är åtkomliga från Internet. Molnets nätverkskontroller och Linux-systemets lokala tjänster är separata lager.

Ett lyckat DNS-uppslag visar namnupplösning men bevisar inte att en webbtjänst eller annan applikation är tillgänglig.

### 9. Cleanup

Den tillfälliga Python-testtjänsten på port 8080 stoppades efter testningen.

Port 8080 kontrollerades därefter och ingen tjänst lyssnade längre där.

Temporära testfiler och andra labbresurser ska hanteras enligt lärarens instruktioner innan miljön lämnas.

### 10. AI-användning

AI användes som stöd för att förstå uppgiftens instruktioner, tolka Linux-kommandon och strukturera dokumentationen.

Alla kommandon kördes och verifierades i den egna Linuxmiljön. Resultaten i rapporten bygger på de faktiska tester som genomfördes i VM:n.

AI användes som stöd och inte som ersättning för att själv genomföra och verifiera kontrollerna.
