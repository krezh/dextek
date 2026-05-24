#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=${1:-}

: "${APPRISE_RADARR_GOTIFY_URL:?Gotify URL required}"

echo "[DEBUG] Radarr Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local event_type
    event_type=$(_jq '.eventType')

    case "${event_type}" in
        "Download")
            printf -v GOTIFY_TITLE "Movie %s" \
                "$( [[ "$(_jq '.isUpgrade')" == "true" ]] && echo "Upgraded" || echo "Added" )"
            printf -v GOTIFY_MESSAGE "**%s (%s)**\n%s\n\n**Client:** %s\n[View Movie](%s/movie/%s)" \
                "$(_jq '.movie.title')" \
                "$(_jq '.movie.year')" \
                "$(_jq '.movie.overview')" \
                "$(_jq '.downloadClient')" \
                "$(_jq '.applicationUrl')" \
                "$(_jq '.movie.tmdbId')"
            GOTIFY_PRIORITY=2
            ;;
        "ManualInteractionRequired")
            printf -v GOTIFY_TITLE "Movie Requires Manual Interaction"
            printf -v GOTIFY_MESSAGE "**%s (%s)**\n**Client:** %s\n[View Queue](%s/activity/queue)" \
                "$(_jq '.movie.title')" \
                "$(_jq '.movie.year')" \
                "$(_jq '.downloadClient')" \
                "$(_jq '.applicationUrl')"
            GOTIFY_PRIORITY=8
            ;;
        "Test")
            printf -v GOTIFY_TITLE "Test Notification"
            printf -v GOTIFY_MESSAGE "Howdy this is a test notification"
            GOTIFY_PRIORITY=2
            ;;
        *)
            echo "[ERROR] Unknown event type: ${event_type}" >&2
            return 1
            ;;
    esac

    apprise -vv --title "${GOTIFY_TITLE}" --body "${GOTIFY_MESSAGE}" \
        "${APPRISE_RADARR_GOTIFY_URL}?format=markdown&priority=${GOTIFY_PRIORITY}"
}

notify
