#!/usr/bin/env bash

# Install required packages for Salt Master
apt update
apt install -y salt-master

apt install python3-pip -y
pip install pygit2==1.6.1

KEYTYPE=ed25519

# Setup SSH Key
ssh-keygen -q -t $KEYTYPE -m PEM -N '' -f ~/.ssh/id_$KEYTYPE <<<y #>/dev/null 2>&1

# Setup Salt Gitfs
cat <<EOF >/etc/salt/master.d/gitfs.conf
fileserver_backend:
  - gitfs
  - roots
gitfs_global_lock: False
gitfs_privkey: /root/.ssh/id_$KEYTYPE
gitfs_pubkey:  /root/.ssh/id_$KEYTYPE.pub
gitfs_provider: pygit2
gitfs_update_interval: 60
gitfs_base: main
file_roots:
  base:
    - /srv/salt
gitfs_remotes:
  - git@github.com:krezh/saltstack.git:
    - mountpoint: salt://
EOF

echo "New Public Key. Add to github"
cat ~/.ssh/id_$KEYTYPE.pub
echo ""

read -p "Press enter to Continue"

echo "Restarting Salt Master Service"
echo ""
systemctl restart salt-master
