#!/usr/bin/env bash
# set-topics.sh — Set topics on GitHub repos interactively
#
# Usage:
#   ./set-topics.sh [--all]
#
# Options:
#   --all   Apply to all owned repos without prompting for repo selection

set -euo pipefail

ALL=false
[[ "${1:-}" == "--all" ]] && ALL=true

OWNER=$(gh api /user --jq '.login')

# --- Repos ---
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

# --- Fetch current topics (union across selected repos) ---
mapfile -t REPOS_ARRAY <<< "$SELECTED_REPOS"
CURRENT_TOPICS=$(
  for repo in "${REPOS_ARRAY[@]}"; do
    gh api "/repos/$OWNER/$repo/topics" --jq '.names[]'
  done | sort -u
)

# --- Topics ---
TOPICS_RAW=$(gum write \
  --placeholder "One topic per line" \
  --header "Edit topics (one per line):" \
  --value "$CURRENT_TOPICS")

# Parse into array — split on both newlines and spaces, filter blanks
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

# --- Confirm ---
gum style --bold "Topics:"; printf '  %s\n' "${TOPICS[@]}"
gum style --bold "Repos:";  printf '  %s\n' "${REPOS_ARRAY[@]}"
echo ""
gum confirm "Apply these topics to the selected repos?" || exit 0
# Eat the trailing newline gum confirm emits, then print separator flush against it
printf '\033[A\033[2K'
printf '%.0s─' $(seq 1 24); echo

# Build --field args for gh api
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
