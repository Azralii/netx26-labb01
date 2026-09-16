#!/bin/bash

# Secure Network Check
# Syfte: Kontrollera och dokumentera den egna Linuxmiljön.
# Säkerhetsavgränsning: Endast lokala kontroller och godkända mål.
# Ingen extern scanning och inga förändringar av brandväggsregler.

LOG_FILE="./network_check.log"
FAILURES=0
DNS_NAME="${DNS_NAME:-example.com}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

check_environment() {
    log "Miljööversikt: interface och IP"
    ip -br address | tee -a "$LOG_FILE"

    log "Miljööversikt: default route"

    if ip route | grep -q '^default'; then
        ip route | grep '^default' | tee -a "$LOG_FILE"
        log "OK: Default route finns"
        return 0
    else
        log "FAIL: Ingen default route hittades"
        return 1
    fi
}

check_dns() {
    log "Kontrollerar DNS..."

    if [ -z "$DNS_NAME" ]; then
        log "WARN: DNS-namn saknas"
        return 1
    fi

    if getent hosts "$DNS_NAME" > /dev/null 2>&1; then
        log "OK: DNS fungerar för $DNS_NAME"
        return 0
    else
        log "FAIL: DNS fungerar inte för $DNS_NAME"
        return 1
    fi
}

check_local_service() {
    local port="$1"

    log "Kontrollerar lokal tjänst på 127.0.0.1:$port..."

    if curl -s --head --fail "http://127.0.0.1:$port" > /dev/null 2>&1; then
        log "OK: Lokal tjänst svarar på port $port"
        return 0
    else
        log "FAIL: Ingen fungerande tjänst på port $port"
        return 1
    fi
}

check_ports() {
    local temp_file="/tmp/secure_network_check_ports.txt"

    log "Kontrollerar lokalt lyssnande portar..."

    if ss -tuln > "$temp_file" 2>/dev/null; then
        ss -tuln | tee -a "$LOG_FILE"
        log "OK: Lokal portöversikt kunde hämtas"

        rm -f "$temp_file"
        return 0
    else
        log "FAIL: Kunde inte hämta lokal portöversikt"

        rm -f "$temp_file"
        return 1
    fi
}

log "Secure Network Check startar"

if ! check_environment; then
    FAILURES=$((FAILURES + 1))
fi

if ! check_ports; then
    FAILURES=$((FAILURES + 1))
fi

checks=("DNS" "LOCAL_SERVICE")

for check in "${checks[@]}"; do
    case "$check" in
        DNS)
            if ! check_dns; then
                FAILURES=$((FAILURES + 1))
            fi
            ;;

        LOCAL_SERVICE)
            if ! check_local_service 8080; then
                FAILURES=$((FAILURES + 1))
            fi
            ;;

        *)
            log "WARN: Okänd kontroll $check"
            ;;
    esac
done

if [ "$FAILURES" -eq 0 ]; then
    log "RESULTAT: Alla kontroller OK"
    exit 0
else
    log "RESULTAT: $FAILURES kontroll(er) misslyckades"
    exit 1
fi