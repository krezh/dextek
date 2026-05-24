#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=${1:-}

: "${APPRISE_SONARR_GOTIFY_URL:?Gotify URL required}"

echo "[DEBUG] Sonarr Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local event_type
    event_type=$(_jq '.eventType')

    case "${event_type}" in
        "Download")
            printf -v GOTIFY_TITLE \
                "Episode %s" "$( [[ "$(_jq '.isUpgrade')" == "true" ]] && echo "Upgraded" || echo "Added" )"
            printf -v GOTIFY_MESSAGE "**%s (S%02dE%02d)**\n%s\n\n**Client:** %s\n[View Series](%s/series/%s)" \
                "$(_jq '.series.title')" \
                "$(_jq '.episodes[0].seasonNumber')" \
                "$(_jq '.episodes[0].episodeNumber')" \
                "$(_jq '.episodes[0].title')" \
                "$(_jq '.downloadClient')" \
                "$(_jq '.applicationUrl')" \
                "$(_jq '.series.titleSlug')"
            GOTIFY_PRIORITY=2
            ;;
        "ManualInteractionRequired")
            printf -v GOTIFY_TITLE "Episode Requires Manual Interaction"
            printf -v GOTIFY_MESSAGE "**%s**\n**Client:** %s\n[View Queue](%s/activity/queue)" \
                "$(_jq '.series.title')" \
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

    apprise -vv --title "${GOTIFY_TITLE}" --body "${GOTIFY_MESSAGE}" --input-format markdown \
        "${APPRISE_SONARR_GOTIFY_URL}?priority=${GOTIFY_PRIORITY}"
}

notify
