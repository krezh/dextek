# yaml-language-server: $schema=https://raw.githubusercontent.com/siderolabs/talos/refs/heads/release-1.13/website/content/v1.13/schemas/config.schema.json
machine:
  install:
    image: {{ .Data.factoryRepoUrl }}/metal-installer/{{ .SchematicID }}:{{ .TalosVersion }}
  sysctls:
    fs.inotify.max_user_watches: "1048576" # Watchdog
    fs.inotify.max_user_instances: "8192" # Watchdog
    net.core.default_qdisc: fq # 10Gb/s
    net.core.rmem_max: "67108864" # 10Gb/s | Cloudflared / QUIC
    net.core.wmem_max: "67108864" # 10Gb/s | Cloudflared / QUIC
    net.ipv4.tcp_congestion_control: bbr # 10Gb/s
    net.ipv4.tcp_fastopen: "3" # Send and accept data in the opening SYN packet
    net.ipv4.tcp_mtu_probing: "1" # 10Gb/s | Jumbo frames
    net.ipv4.tcp_rmem: 4096 87380 33554432 # 10Gb/s
    net.ipv4.tcp_wmem: 4096 65536 33554432 # 10Gb/s
    net.ipv4.tcp_window_scaling: "1" # 10Gb/s
    sunrpc.tcp_slot_table_entries: "128" # 10Gb/s | NFS
    sunrpc.tcp_max_slot_table_entries: "128" # 10Gb/s | NFS
    vm.nr_hugepages: "1024" # PostgreSQL
    user.max_user_namespaces: "11255" # UserNamespacesSupport
    net.ipv4.ping_group_range: 0 2147483647 # Allow ping for all users
    net.ipv4.neigh.default.gc_thresh1: "4096" # ARP cache
    net.ipv4.neigh.default.gc_thresh2: "8192" # ARP cache
    net.ipv4.neigh.default.gc_thresh3: "16384" # ARP cache
    net.ipv4.tcp_notsent_lowat: "131072" # 10Gb/s
    net.ipv4.tcp_slow_start_after_idle: "0" # 10Gb/s
    net.ipv6.conf.all.disable_ipv6: "1" # Disable IPv6
    net.ipv6.conf.default.disable_ipv6: "1" # Disable IPv6
  udev:
    rules:
      # Intel GPU
      - SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="44", MODE="0660"
  kernel:
    modules:
      - name: nbd
      - name: nvme-tcp
  kubelet:
    disableManifestsDirectory: true
    defaultRuntimeSeccompProfileEnabled: true
    extraConfig:
      maxPods: 150
      serializeImagePulls: false
    nodeIP:
      validSubnets:
        - 10.10.0.0/27
  certSANs: &sans
    - 192.168.25.20
    - dextek.plexuz.xyz
    - 127.0.0.1
    - localhost
  files:
    - op: overwrite
      path: /etc/nfsmount.conf
      permissions: 0o644
      content: |
        [ NFSMount_Global_Options ]
        nfsvers=4.2
        hard=True
        nconnect=16
        noatime=True
        async=True
        rsize=1048576
        wsize=1048576
    - path: /etc/cri/conf.d/20-customization.part
      op: create
      content: |-
        [metrics]
          address = "0.0.0.0:11234"
        [plugins."io.containerd.cri.v1.runtime"]
          device_ownership_from_security_context = true
  features:
    diskQuotaSupport: true
    kubePrism:
      enabled: true
      port: 7445
    hostDNS:
      enabled: true
      resolveMemberNames: true
      forwardKubeDNSToHost: false # Requires Cilium socketLB features
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles: ["os:admin", "os:reader"]
      allowedKubernetesNamespaces: ["kube-system", "ai"]

cluster:
  allowSchedulingOnControlPlanes: true
  clusterName: {{ .ClusterName }}
  controlPlane:
    endpoint: https://{{ .ClusterEndpoint }}:6443
  etcd:
    advertisedSubnets:
      - 10.10.0.0/27
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
      auto-compaction-mode: periodic
      auto-compaction-retention: "5m"
      quota-backend-bytes: "4294967296" # 4 GiB
  controllerManager:
    extraArgs:
      feature-gates: PersistentVolumeClaimUnusedSinceTime=true,HPAScaleToZero=true
      bind-address: 0.0.0.0
  network:
    cni:
      name: none
  coreDNS:
    disabled: true
  proxy:
    disabled: true
  apiServer:
    certSANs: *sans
    auditPolicy:
      apiVersion: audit.k8s.io/v1
      kind: Policy
      rules:
        - level: Metadata
    extraArgs:
      enable-aggregator-routing: "true"
      feature-gates: PersistentVolumeClaimUnusedSinceTime=true,HPAScaleToZero=true
      default-not-ready-toleration-seconds: "60"
      default-unreachable-toleration-seconds: "60"
      oidc-client-id: kubernetes
      oidc-groups-claim: groups
      oidc-issuer-url: https://sso.plexuz.xyz/application/o/kubernetes/
      oidc-username-claim: email
  scheduler:
    extraArgs:
      bind-address: 0.0.0.0
    config:
      apiVersion: kubescheduler.config.k8s.io/v1
      kind: KubeSchedulerConfiguration
      profiles:
        - schedulerName: default-scheduler
          plugins:
            score:
              disabled:
                - name: ImageLocality
          pluginConfig:
            - name: PodTopologySpread
              args:
                defaultingType: List
                defaultConstraints:
                  - maxSkew: 1
                    topologyKey: kubernetes.io/hostname
                    whenUnsatisfiable: ScheduleAnyway
---
apiVersion: v1alpha1
kind: ResolverConfig
nameservers:
  - address: 192.168.20.1
searchDomains:
  disableDefault: true
---
apiVersion: v1alpha1
kind: WatchdogTimerConfig
device: /dev/watchdog0
timeout: 5m
---
cluster:
  apiServer:
    admissionControl:
      $patch: delete
    extraArgs:
      authentication-token-webhook-config-file: /etc/kubernetes/webhook-auth/kauth.yaml
      authentication-token-webhook-cache-ttl: 30s # max revocation window
    extraVolumes:
      - hostPath: /var/kubernetes/webhook-auth
        mountPath: /etc/kubernetes/webhook-auth
        readonly: true
machine:
  files:
    - op: create
      path: /var/kubernetes/webhook-auth/kauth.yaml
      permissions: 0o644
      content: |
        apiVersion: v1
        kind: Config
        clusters:
          - name: kauth
            cluster:
              server: http://10.96.0.11:8081/webhook/token-review
        users:
          - name: apiserver
            user: {}
        contexts:
          - name: kauth
            context:
              cluster: kauth
              user: apiserver
        current-context: kauth
