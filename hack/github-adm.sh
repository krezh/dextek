#!/usr/bin/env bash
# github-adm.sh — Manage GitHub repo topics and webhooks interactively
#
# Usage:
#   ./github-adm.sh [--all] [topics|webhooks]
#
# Options:
#   --all        Apply to all owned repos without prompting for repo selection
#   topics       Manage topics (default mode)
#   webhooks     Manage webhooks (add / remove / update)

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [--all] [topics|webhooks]

Commands:
  topics    Set topics on repos (default)
  webhooks  Add, remove, or update webhooks on repos

Options:
  --all     Apply to all owned repos without prompting for repo selection
  --help    Show this help message
EOF
}

ALL=false
MODE="topics"

for arg in "$@"; do
  case "$arg" in
    --help)    usage; exit 0 ;;
    --all)     ALL=true ;;
    topics)    MODE="topics" ;;
    webhooks)  MODE="webhooks" ;;
  esac
done

OWNER=$(gh api /user --jq '.login')

# --- Repo selection ---
ALL_REPOS=$(gh api "/users/$OWNER/repos?type=owner&per_page=100" --paginate --jq '.[].name' | sort)

if [[ "$ALL" == true ]]; then
  SELECTED_REPOS="$ALL_REPOS"
else
  SELECTED_REPOS=$(echo "$ALL_REPOS" | gum choose --no-limit --header "Select repos to update:")
fi

if [[ -z "$SELECTED_REPOS" ]]; then
  echo "No repos selected. Exiting."
  exit 0
fi

mapfile -t REPOS_ARRAY <<< "$SELECTED_REPOS"

# ===========================================================================
# Topics mode
# ===========================================================================
if [[ "$MODE" == "topics" ]]; then
  # Fetch current topics (union across selected repos)
  CURRENT_TOPICS=$(
    for repo in "${REPOS_ARRAY[@]}"; do
      gh api "/repos/$OWNER/$repo/topics" --jq '.names[]'
    done | sort -u
  )

  TOPICS_RAW=$(gum write \
    --placeholder "One topic per line" \
    --header "Edit topics (one per line):" \
    --value "$CURRENT_TOPICS")

  TOPICS=()
  while IFS=' ' read -ra words; do
    for word in "${words[@]}"; do
      [[ -n "$word" ]] && TOPICS+=("$word")
    done
  done <<< "$TOPICS_RAW"

  if [[ ${#TOPICS[@]} -eq 0 ]]; then
    echo "No topics entered. Exiting."
    exit 0
  fi

  gum style --bold "Topics:"; printf '  %s\n' "${TOPICS[@]}"
  gum style --bold "Repos:";  printf '  %s\n' "${REPOS_ARRAY[@]}"
  echo ""
  gum confirm "Apply these topics to the selected repos?" || exit 0
  printf '\033[A\033[2K'
  printf '%.0s─' $(seq 1 24); echo

  FIELDS=()
  for topic in "${TOPICS[@]}"; do
    FIELDS+=(--field "names[]=$topic")
  done

  for repo in "${REPOS_ARRAY[@]}"; do
    echo -n "$OWNER/$repo "
    gh api --method PUT "/repos/$OWNER/$repo/topics" "${FIELDS[@]}" --silent \
      && printf '\e[32m✓\e[0m\n' || printf '\e[31m✗ (failed)\e[0m\n'
  done

  echo "Done."
  exit 0
fi

# ===========================================================================
# Webhooks mode
# ===========================================================================

WEBHOOK_ACTION=$(gum choose \
  --header "What do you want to do with webhooks?" \
  "add" "remove" "update")

# ---------------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------------
if [[ "$WEBHOOK_ACTION" == "add" ]]; then
  HOOK_URL=$(gum input --placeholder "https://example.com/webhook" --header "Payload URL:")
  [[ -z "$HOOK_URL" ]] && echo "No URL provided. Exiting." && exit 0

  CONTENT_TYPE=$(gum choose --header "Content type:" "json" "form")

  SECRET=$(gum input --placeholder "(leave blank for none)" --header "Webhook secret (optional):")

  EVENTS_ALL=$(printf '%s\n' \
    push pull_request issues release create delete \
    fork star watch deployment deployment_status \
    pull_request_review pull_request_review_comment \
    issue_comment commit_comment member \
    repository workflow_run check_run check_suite \
    | gum choose --no-limit --header "Select events to subscribe to:")

  if [[ -z "$EVENTS_ALL" ]]; then
    echo "No events selected. Exiting."
    exit 0
  fi

  mapfile -t EVENTS_ARRAY <<< "$EVENTS_ALL"

  ACTIVE=$(gum choose --header "Activate webhook immediately?" "true" "false")

  gum style --bold "URL:";    echo "  $HOOK_URL"
  gum style --bold "Events:"; printf '  %s\n' "${EVENTS_ARRAY[@]}"
  gum style --bold "Repos:";  printf '  %s\n' "${REPOS_ARRAY[@]}"
  echo ""
  gum confirm "Add this webhook to the selected repos?" || exit 0
  printf '\033[A\033[2K'
  printf '%.0s─' $(seq 1 24); echo

  for repo in "${REPOS_ARRAY[@]}"; do
    echo -n "$OWNER/$repo "

    # Build JSON payload
    EVENTS_JSON=$(printf '"%s",' "${EVENTS_ARRAY[@]}")
    EVENTS_JSON="[${EVENTS_JSON%,}]"

    PAYLOAD=$(jq -n \
      --arg url    "$HOOK_URL" \
      --arg ct     "$CONTENT_TYPE" \
      --arg secret "$SECRET" \
      --arg active "$ACTIVE" \
      --argjson events "$EVENTS_JSON" \
      '{
        name: "web",
        active: ($active == "true"),
        events: $events,
        config: {
          url: $url,
          content_type: $ct,
          secret: (if $secret == "" then null else $secret end),
          insecure_ssl: "0"
        }
      }')

    gh api --method POST "/repos/$OWNER/$repo/hooks" \
      --input <(echo "$PAYLOAD") --silent \
      && printf '\e[32m✓\e[0m\n' || printf '\e[31m✗ (failed)\e[0m\n'
  done

  echo "Done."

# ---------------------------------------------------------------------------
# REMOVE
# ---------------------------------------------------------------------------
elif [[ "$WEBHOOK_ACTION" == "remove" ]]; then
  # Collect hooks across all selected repos, keyed as "owner/repo  id  url"
  HOOK_LIST=""
  for repo in "${REPOS_ARRAY[@]}"; do
    hooks=$(gh api "/repos/$OWNER/$repo/hooks" \
      --jq ".[] | \"$OWNER/$repo  id:\(.id)  \(.config.url)\"" 2>/dev/null || true)
    [[ -n "$hooks" ]] && HOOK_LIST+="$hooks"$'\n'
  done

  if [[ -z "$HOOK_LIST" ]]; then
    echo "No webhooks found on the selected repos."
    exit 0
  fi

  SELECTED_HOOKS=$(echo "$HOOK_LIST" | gum choose --no-limit --header "Select webhooks to remove:")

  if [[ -z "$SELECTED_HOOKS" ]]; then
    echo "Nothing selected. Exiting."
    exit 0
  fi

  gum style --bold "Will delete:"
  echo "$SELECTED_HOOKS"
  echo ""
  gum confirm "Delete the selected webhooks?" || exit 0
  printf '\033[A\033[2K'
  printf '%.0s─' $(seq 1 24); echo

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Extract "owner/repo" and "id:NNNN" from the display line
    repo_full=$(echo "$line" | awk '{print $1}')
    hook_id=$(echo "$line" | grep -oP 'id:\K[0-9]+')
    echo -n "$repo_full hook $hook_id "
    gh api --method DELETE "/repos/$repo_full/hooks/$hook_id" --silent \
      && printf '\e[32m✓\e[0m\n' || printf '\e[31m✗ (failed)\e[0m\n'
  done <<< "$SELECTED_HOOKS"

  echo "Done."

# ---------------------------------------------------------------------------
# UPDATE
# ---------------------------------------------------------------------------
elif [[ "$WEBHOOK_ACTION" == "update" ]]; then
  # Collect all hooks across selected repos to pick a template from
  HOOK_LIST=""
  for repo in "${REPOS_ARRAY[@]}"; do
    hooks=$(gh api "/repos/$OWNER/$repo/hooks" \
      --jq ".[] | \"$OWNER/$repo  id:\(.id)  \(.config.url)\"" 2>/dev/null || true)
    [[ -n "$hooks" ]] && HOOK_LIST+="$hooks"$'\n'
  done

  if [[ -z "$HOOK_LIST" ]]; then
    echo "No webhooks found on the selected repos."
    exit 0
  fi

  # Pick one hook as the template for the new config
  SELECTED_HOOK=$(echo "$HOOK_LIST" | gum choose --header "Select webhook to update (will apply to all repos that have a hook with the same URL):")
  TEMPLATE_REPO_FULL=$(echo "$SELECTED_HOOK" | awk '{print $1}')
  TEMPLATE_HOOK_ID=$(echo "$SELECTED_HOOK" | grep -oP 'id:\K[0-9]+')
  MATCH_URL=$(echo "$SELECTED_HOOK" | awk '{print $3}')

  # Fetch current config from the template hook
  CURRENT=$(gh api "/repos/$TEMPLATE_REPO_FULL/hooks/$TEMPLATE_HOOK_ID")
  CUR_URL=$(echo "$CURRENT"    | jq -r '.config.url')
  CUR_SECRET=$(echo "$CURRENT" | jq -r '.config.secret // ""')
  CUR_EVENTS=$(echo "$CURRENT" | jq -r '.events[]')

  HOOK_URL=$(gum input --placeholder "$CUR_URL" --header "New payload URL (enter to keep):" --value "$CUR_URL")
  [[ -z "$HOOK_URL" ]] && HOOK_URL="$CUR_URL"

  CONTENT_TYPE=$(gum choose --header "Content type:" "json" "form")

  SECRET=$(gum input --placeholder "(blank = keep existing)" --header "Webhook secret (leave blank to keep):")
  [[ -z "$SECRET" ]] && SECRET="$CUR_SECRET"

  EVENTS_ALL=$(printf '%s\n' \
    push pull_request issues release create delete \
    fork star watch deployment deployment_status \
    pull_request_review pull_request_review_comment \
    issue_comment commit_comment member \
    repository workflow_run check_run check_suite \
    | gum choose --no-limit --header "Select events (current: $(echo "$CUR_EVENTS" | tr '\n' ' ')):")

  if [[ -z "$EVENTS_ALL" ]]; then
    echo "No events selected. Exiting."
    exit 0
  fi

  mapfile -t EVENTS_ARRAY <<< "$EVENTS_ALL"

  ACTIVE=$(gum choose --header "Active?" "true" "false")

  gum style --bold "URL:";    echo "  $HOOK_URL"
  gum style --bold "Events:"; echo "  ${EVENTS_ARRAY[*]}"
  gum style --bold "Repos:";  printf '  %s\n' "${REPOS_ARRAY[@]}"
  echo ""
  gum confirm "Apply update to all repos with a hook matching \"$MATCH_URL\"?" || exit 0
  printf '\033[A\033[2K'
  printf '%.0s─' $(seq 1 24); echo

  EVENTS_JSON=$(printf '"%s",' "${EVENTS_ARRAY[@]}")
  EVENTS_JSON="[${EVENTS_JSON%,}]"

  PAYLOAD=$(jq -n \
    --arg url    "$HOOK_URL" \
    --arg ct     "$CONTENT_TYPE" \
    --arg secret "$SECRET" \
    --arg active "$ACTIVE" \
    --argjson events "$EVENTS_JSON" \
    '{
      active: ($active == "true"),
      events: $events,
      config: {
        url: $url,
        content_type: $ct,
        secret: (if $secret == "" then null else $secret end),
        insecure_ssl: "0"
      }
    }')

  for repo in "${REPOS_ARRAY[@]}"; do
    # Find hooks on this repo whose URL matches the selected template
    matching=$(gh api "/repos/$OWNER/$repo/hooks" \
      --jq ".[] | select(.config.url == \"$MATCH_URL\") | .id" 2>/dev/null || true)
    if [[ -z "$matching" ]]; then
      echo "$OWNER/$repo  (no matching hook, skipped)"
      continue
    fi
    while IFS= read -r hid; do
      echo -n "$OWNER/$repo hook $hid "
      gh api --method PATCH "/repos/$OWNER/$repo/hooks/$hid" \
        --input <(echo "$PAYLOAD") --silent \
        && printf '\e[32m✓\e[0m\n' || printf '\e[31m✗ (failed)\e[0m\n'
    done <<< "$matching"
  done

  echo "Done."
fi
