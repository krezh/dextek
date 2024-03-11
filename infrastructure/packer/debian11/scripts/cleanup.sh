#!/usr/bin/env bash

for service in syslog syslog-ng rsyslog systemd-journald; do
	{
		if [[ ! $UBUNTU_VERSION =~ ^(12|14).04$ ]]; then
			systemctl stop "$service"
		else
			service "$service" stop
		fi
	} || true
done

logrotate -f /etc/logrotate.conf || true

# Remove the Ubuntu Extended Security Maintenance (ESM)
# as it is a paid feature only available to Canonical
# Advantage subscribers.
apt-key adv --batch --yes --delete-keys 'esm@canonical.com' 2>/dev/null || true
find /etc/apt/sources.list.d -type f -name 'ubuntu-esm-*' -print0 |
	xargs -0 rm -f

# Remove everything (configuration files, etc.) left after
# packages were uninstalled (often unused files are left on
# the file system).
dpkg -l | grep '^rc' | awk '{ print $2 }' |
	xargs apt-get --assume-yes purge

# Remove not really needed Kernel source packages.
dpkg -l | awk '{ print $2 }' |
	grep -E '(linux-(source|headers)-[0-9]+|linux-aws-(source|headers)-[0-9]+)' |
	grep -v "$(uname -r | sed -e 's/\-generic//;s/\-lowlatency//;s/\-aws//')" |
	xargs apt-get --assume-yes purge

# Remove old Kernel images and modules that are not the current one.
dpkg -l | awk '{ print $2 }' |
	grep -E 'linux-(image|modules)-.*-(generic|aws)' |
	grep -v "$(uname -r)" | xargs apt-get --assume-yes purge

# Remove development packages.
dpkg -l | awk '{ print $2 }' | grep -E -- '.*-dev:?.*' |
	grep -v -E "(libc|$(dpkg -s g++ &>/dev/null && echo 'libstdc++')|gcc)" |
	xargs apt-get --assume-yes purge

# A list of packages to be purged.
PACKAGES_TO_PURGE=($(cat "${COMMON_FILES}/packages-purge.list" 2>/dev/null))

if [[ -n $AMAZON_EC2 || -n $PROXMOX ]]; then
	# Remove packages that are definitely not needed in EC2 or Proxmox ...
	PACKAGES_TO_PURGE+=(
		'^wireless-*'
		'crda'
		'iw'
		'linux-firmware'
		'mdadm'
		'open-iscsi'
	)
fi

if [[ -n $AMAZON_EC2 ]]; then
	# Remove packages that are definitely not needed in EC2 ...
	PACKAGES_TO_PURGE+=(
		'lvm2'
	)
fi

if [[ ! $UBUNTU_VERSION =~ ^(12|14).04$ ]]; then
	# Remove LXD and LXCFS as Docker will be installed.
	PACKAGES_TO_PURGE+=(
		'lxd'
		'lxcfs'
	)
fi

for package in "${PACKAGES_TO_PURGE[@]}"; do
	apt-get --assume-yes purge "$package" 2>/dev/null || true
done

rm -f /usr/sbin/policy-rc.d

rm -f /.dockerenv \
	/.dockerinit

rm -f /etc/blkid.tab \
	/dev/.blkid.tab

rm -f /core*

rm -f /boot/grub/menu.lst_* \
	/boot/grub/menu.lst~ \
	/boot/*.old*

rm -f /etc/network/interfaces.old

rm -f /etc/apt/apt.conf.d/99dpkg \
	/etc/apt/apt.conf.d/00CDMountPoint

rm -f VBoxGuestAdditions_*.iso \
	VBoxGuestAdditions_*.iso.?

rm -f /root/.bash_history \
	/root/.rnd* \
	/root/.hushlogin \
	/root/*.tar \
	/root/.*_history \
	/root/.lesshst \
	/root/.wget* \
	/root/.gemrc \
	/roor/.sudo*

rm -Rf /root/.cache \
	/root/.{gem,gems} \
	/root/.vim* \
	/root/.ssh \
	/root/.gnupg \
	/root/*

USERS=('vagrant')
if [[ -z $PROXMOX ]]; then
	USERS+=('ubuntu')
fi

for user in "${USERS[@]}"; do
	if getent passwd "$user" &>/dev/null; then
		rm -f /home/${user:?}/.bash_history \
			/home/${user:?}/.rnd* \
			/home/${user:?}/.hushlogin \
			/home/${user:?}/*.tar \
			/home/${user:?}/.*_history \
			/home/${user:?}/.lesshst \
			/home/${user:?}/.wget* \
			/home/${user:?}/.gemrc \
			/home/${user:?}/.sudo*

		rm -Rf /home/${user:?}/.cache \
			/home/${user:?}/.{gem,gems} \
			/home/${user:?}/.gnupg \
			/home/${user:?}/.vim* \
			/home/${user:?}/*
	fi
done

rm -Rf /etc/lvm/cache/.cache

# Clean if there are any Python software installed there.
if ls /opt/*/share &>/dev/null; then
	find /opt/*/share -type d \( -name 'man' -o -name 'doc' \) -print0 |
		xargs -0 rm -Rf
fi

rm -Rf /usr/share/{doc,man}/* \
	/usr/local/share/{doc,man}

rm -Rf /usr/share/groff/* \
	/usr/share/info/* \
	/usr/share/lintian/* \
	/usr/share/linda/* \
	/usr/share/bug/*

sed -i -e \
	'/^.\+fd0/d;/^.\*floppy0/d' \
	/etc/fstab

# Remove entry for "/mnt" from /etc/fstab,
# we do not want any extra volume (if
# available) to be mounted automatically.
sed -i -e \
	'/^.\+\/mnt/d;/^.\*\/mnt/d' \
	/etc/fstab

sed -i -e \
	'/^#/!s/\s\+/\t/g' \
	/etc/fstab

rm -Rf /var/lib/ubuntu-release-upgrader \
	/var/lib/update-notifier \
	/var/lib/update-manager \
	/var/lib/man-db \
	/var/lib/apt-xapian-index \
	/var/lib/ntp/ntp.drift \
	/var/lib/{lxd,lxcfs}

rm -Rf /lib/recovery-mode

rm -Rf /var/lib/cloud/data/scripts \
	/var/lib/cloud/scripts/per-instance \
	/var/lib/cloud/data/user-data* \
	/var/lib/cloud/instance \
	/var/lib/cloud/instances/*

rm -Rf /var/log/docker \
	/var/run/docker.sock

rm -Rf /var/log/unattended-upgrades

# Prevent storing of the MAC address as part of the network
# interface details saved by systemd/udev, and disable support
# for the Predictable (or "consistent") Network Interface Names.
UDEV_RULES=(
	'70-persistent-net.rules'
	'75-persistent-net-generator.rules'
	'80-net-setup-link.rules'
	'80-net-name-slot.rules'
)

for rule in "${UDEV_RULES[@]}"; do
	rm -f "/etc/udev/rules.d/${rule}"
	ln -sf /dev/null "/etc/udev/rules.d/${rule}"
done

rm -Rf /dev/.udev \
	/var/lib/{dhcp,dhcp3}/* \
	/var/lib/dhclient/*

find /etc /var /usr -type f -name '*~' -print0 |
	xargs -0 rm -f

find /var/log /var/cache /var/lib/apt -type f -print0 |
	xargs -0 rm -f

find /etc/alternatives /etc/rc[0-9].d -xtype l -print0 |
	xargs -0 rm -f

if [[ -n $AMAZON_EC2 || -n $PROXMOX ]]; then
	find /etc /root /home -type f -name 'authorized_keys' -print0 |
		xargs -0 rm -f
else
	# Only the Vagrant user should keep its SSH key. Everything
	# else will either use the user left form the image creation
	# time, or a new key will be fetched and stored by means of
	# cloud-init, etc.
	if ! getent passwd vagrant &>/dev/null; then
		find /etc /root /home -type f -name 'authorized_keys' -print0 |
			xargs -0 rm -f
	fi
fi

mkdir -p /var/lib/apt/periodic \
	/var/lib/apt/{lists,archives}/partial

chown -R root: /var/lib/apt
chmod -R 755 /var/lib/apt

# Re-create empty directories for system manuals,
# to stop certain package diversions from breaking.
mkdir -p /usr/share/man/man{1..8}

chown -R root: /usr/share/man
chmod -R 755 /usr/share/man

# Newer version of Ubuntu introduce a dedicated
# "_apt" user, which owns the temporary files.
if [[ ! $UBUNTU_VERSION =~ ^(12|14).04$ ]]; then
	chown _apt: /var/lib/apt/lists/partial
fi

apt-cache gencaches

touch /var/log/{lastlog,wtmp,btmp}

chown root: /var/log/{lastlog,wtmp,btmp}
chmod 644 /var/log/{lastlog,wtmp,btmp}

# ConfigDrive needs to come first (I think)
cat <<EOF >/etc/cloud/cloud.cfg.d/99-pve.cfg
datasource_list: [ConfigDrive, NoCloud]
EOF

cat /dev/null >/etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "Deleting /etc/salt/minion_id..."
rm -vf /etc/salt/pki/minion/*
rm -vf /etc/salt/minion_id

echo "Clean up udev rules..."
rm -f /etc/udev/rules.d/70*

echo "Clean up /tmp..."
rm -rvf /tmp/*

echo "Clean up urandom seed..."
rm -vf /var/lib/urandom/random-seed

echo "Cleaning up /var/mail..."
rm -vf /var/mail/*

echo "Clean up apt cache..."
find /var/cache/apt/archives -type f -exec rm -vf \{\} \;

echo "Clean up ntp..."
rm -vf /var/lib/ntp/ntp.drift
rm -vf /var/lib/ntp/ntp.conf.dhcp

echo "Clean up backups..."
rm -vrf /var/backups/*
rm -vf /etc/shadow- /etc/passwd- /etc/group- /etc/gshadow- /etc/subgid- /etc/subuid-

echo "Cleaning up /var/log..."
find /var/log -type f -name "*.gz" -exec rm -vf \{\} \;
find /var/log -type f -name "*.1" -exec rm -vf \{\} \;
find /var/log -type f -exec truncate -s0 \{\} \;

echo "Clearing bash history..."
cat /dev/null >/root/.bash_history
history -c

echo "Cloud-init clean..."
cloud-init clean
systemctl stop cloud-init
rm -rf /var/lib/cloud/

fstrim -av

echo "Clearing bash history (II)..."
cat /dev/null >/root/.bash_history
history -c

echo "Clear DHCP leases..."
dhclient -r -v
rm -f /etc/ssh/*key*
rm -f /var/lib/dhcp*/*leases*
rm -f /var/lib/dhcp/dhclient.*
