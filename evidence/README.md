# Evidence – Secure Network Check

## Syfte

Den här mappen innehåller dokumentation och hänvisningar till testresultat från Secure Network Check.

Testerna genomfördes i den egna Oracle Cloud Linux-miljön.

## Genomförda kontroller

Följande kontroller genomfördes:

* Interface och IP med `ip -br address`
* Routing med `ip route`
* Lokalt lyssnande portar med `ss -tuln`
* DNS med `getent hosts`
* Lokal HTTP-tjänst på `127.0.0.1:8080`
* Felhantering med ogiltigt DNS-namn
* Felhantering när lokal tjänst saknas

## Testresultat

### Normaltest 1 – DNS

`example.com` kunde lösas med DNS.

Resultat:

```text
OK: DNS fungerar för example.com
```

### Normaltest 2 – lokal tjänst

En tillfällig Python HTTP-server kördes endast på:

```text
127.0.0.1:8080
```

Scriptet kunde därefter verifiera tjänsten:

```text
OK: Lokal tjänst svarar på port 8080
```

### Feltest 1 – ogiltigt DNS-namn

Ett ogiltigt DNS-namn användes:

```text
invalid-domain-that-does-not-exist.example
```

Resultat:

```text
FAIL: DNS fungerar inte för invalid-domain-that-does-not-exist.example
```

Scriptet fortsatte att köra övriga kontroller.

### Feltest 2 – ingen lokal tjänst

Den tillfälliga HTTP-servern stoppades innan testet.

Resultat:

```text
FAIL: Ingen fungerande tjänst på port 8080
```

## Säkerhet och sanering

Endast information från den egna labbmiljön används.

Inga privata nycklar, lösenord, tokens eller andra hemligheter ska placeras i denna mapp.

Råa PCAP-filer eller annan känslig nätverksevidence ska inte publiceras osanerad.

## Logg

Scriptet skapar en timestampad logg:

```text
network_check.log
```

Loggen används för att dokumentera när kontrollerna kördes och vilket resultat de gav.
