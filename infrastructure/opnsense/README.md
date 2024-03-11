# Opnsense

## frr

### Install

```bash
pkg install frr8
```

### Directories and files for bgp.conf

```bash
vim /usr/local/etc/frr
```

```bash
vim /etc/rc.conf.d/frr # Enable bfdd and bgpd
```

```bash
service frr restart
```

## unbound

```bash
/var/unbound
```
