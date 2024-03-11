#!/usr/bin/env bash

# Setup Salt Minion
cat <<EOF >/etc/salt/minion.d/minion.conf
master: salt.srv.int.plexuz.xyz
EOF
