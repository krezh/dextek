#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=${1:-}

: "${APPRISE_ALERTMANAGER_GOTIFY_URL:?Gotify URL required}"

echo "[DEBUG] Alertmanager Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local status alert_count alertname severity priority title message

    status=$(_jq '.status')
    alert_count=$(_jq '.alerts | length')
    alertname=$(_jq '.commonLabels.alertname // "Unknown"')
    severity=$(_jq '.commonLabels.severity // "none"')

    if [[ "${status}" == "firing" ]]; then
        printf -v title "[FIRING:%s] %s" "${alert_count}" "${alertname}"
        [[ "${severity}" == "critical" ]] && priority=8 || priority=5
    else
        printf -v title "[RESOLVED] %s" "${alertname}"
        priority=2
    fi

    local external_url
    external_url=$(_jq '.externalURL')

    message=$(_jq '
        [.alerts[] | (
            .annotations.description //
            .annotations.summary //
            .annotations.message //
            "No description available"
        )] | join("\n")
    ')
    message="${message}"$'\n\n'"[View in Alertmanager](${external_url})"

    apprise -vv --title "${title}" --body "${message}" \
        "${APPRISE_ALERTMANAGER_GOTIFY_URL}?format=markdown&priority=${priority}"
}

notify
