#!/bin/bash

LOG_FILE="./network_check.log"
FAILURES=0
DNS_NAME="${DNS_NAME:-example.com}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

check_dns() {
    log "Kontrollerar DNS..."

    if getent hosts "$DNS_NAME" > /dev/null 2>&1; then
        log "OK: DNS fungerar"
        return 0
    else
        log "FAIL: DNS fungerar inte"
        return 1
    fi
}

check_local_service() {
    local port="$1"

    log "Kontrollerar lokal tjänst på 127.0.0.1:$port..."

    if curl -s --head --fail "http://127.0.0.1:$port" > /dev/null; then
        log "OK: Lokal tjänst svarar på port $port"
        return 0
    else
        log "FAIL: Ingen fungerande tjänst på port $port"
        return 1
    fi
}

log "Secure Network Check startar"

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
    esac
done

if [ "$FAILURES" -eq 0 ]; then
    log "RESULTAT: Alla kontroller OK"
    exit 0
else
    log "RESULTAT: $FAILURES kontroll(er) misslyckades"
    exit 1
fi
