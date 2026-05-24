#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=${1:-}

: "${APPRISE_SEERR_GOTIFY_URL:?Gotify URL required}"

echo "[DEBUG] Seerr Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local event_type
    event_type=$(_jq '.notification_type')

    case "${event_type}" in
        "TEST_NOTIFICATION")
            printf -v GOTIFY_TITLE "Test Notification"
            printf -v GOTIFY_MESSAGE "Howdy this is a test notification from **Seerr**"
            GOTIFY_PRIORITY=2
            ;;
        "*")
            echo "[ERROR] Unknown event type: ${event_type}" >&2
            return 1
            ;;
    esac

    apprise -vv --title "${GOTIFY_TITLE}" --body "${GOTIFY_MESSAGE}" --input-format markdown \
        "${APPRISE_SEERR_GOTIFY_URL}?priority=${GOTIFY_PRIORITY}"
}

notify
