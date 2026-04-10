#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <project-name> [up|down]"
    exit 1
fi

PROJECT_NAME="$1"
ACTION="${2:-up}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/${PROJECT_NAME}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "Error: .env file not found: $PROJECT_DIR/.env"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/.doco-cd/docker-compose.app.yaml" ]; then
    echo "Error: docker-compose.app.yaml not found: $PROJECT_DIR/.doco-cd/docker-compose.app.yaml"
    exit 1
fi

COMPOSE="docker compose --project-directory $PROJECT_DIR --env-file $PROJECT_DIR/.env -f $PROJECT_DIR/.doco-cd/docker-compose.app.yaml"

case "$ACTION" in
    up)
        if ! docker network inspect pangolin &>/dev/null; then
            docker network create pangolin
        fi
        echo "Deploying $PROJECT_NAME..."
        $COMPOSE up -d
        ;;
    down)
        echo "Stopping $PROJECT_NAME..."
        $COMPOSE down
        ;;
    *)
        echo "Error: Unknown action '$ACTION'. Use 'up' or 'down'."
        exit 1
        ;;
esac

echo "Done!"
