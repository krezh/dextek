#!/usr/bin/env python3

import os
import sys
import requests
import yaml

JELLYFIN_URL = os.environ["JELLYFIN_URL"]
JELLYFIN_APIKEY = os.environ["JELLYFIN_APIKEY"]
CONFIG_PATH = os.environ.get("CONFIG_PATH", "/config/config.yaml")


def load_config() -> dict:
    with open(CONFIG_PATH) as f:
        return yaml.safe_load(f) or {}


def configure_plugin(session: requests.Session, installed: dict, plugin: dict) -> bool:
    name = plugin["name"]
    desired = plugin.get("configuration", {})

    print(f"[{name}]")

    if name not in installed:
        print(f"  Plugin not installed")
        return False

    plugin_id = installed[name]
    resp = session.get(f"{JELLYFIN_URL}/Plugins/{plugin_id}/Configuration")
    resp.raise_for_status()
    current = resp.json()

    changed = [key for key, value in desired.items() if current.get(key) != value]
    if not changed:
        print(f"  Up to date")
        return True

    print(f"  Changed: {', '.join(changed)}")
    current.update(desired)

    update = session.post(f"{JELLYFIN_URL}/Plugins/{plugin_id}/Configuration", json=current)
    if update.status_code in (200, 204):
        print(f"  Configuration updated")
        return True
    else:
        print(f"  Update failed: {update.status_code} {update.text}")
        return False


def main():
    config = load_config()

    session = requests.Session()
    session.headers["Authorization"] = f'MediaBrowser Token="{JELLYFIN_APIKEY}"'

    resp = session.get(f"{JELLYFIN_URL}/Plugins")
    resp.raise_for_status()
    installed = {p["Name"]: p["Id"] for p in resp.json() if p["Status"] == "Active"}

    print(f"Found {len(installed)} installed plugins")

    ok = all([configure_plugin(session, installed, plugin) for plugin in config.get("plugins", [])])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
