# BADASS

## Rebuild the Docker images (required before opening the projects)

GNS3 portable exports do not embed Docker images. From the repo root:

```
docker build -t badass-router -f Shared/router.Dockerfile Shared/
docker build -t badass-host   -f Shared/host.Dockerfile   Shared/
```

## Open a part

GNS3 → File → Import portable project → P1/P1.gns3project (or P2, P3).

## Notes

- Full tools are called by path: /sbin/ip, /usr/sbin/brctl
  (the GNS3 console busybox shadows "ip" and "brctl" with limited versions).
- P3: wait ~1 min after starting all nodes (OSPF → BGP → EVPN convergence).

## P2: switching between static and multicast mode

The exported project boots in **multicast mode** (`_mgoncalv-*_g`).
The static (unicast) variant is in `P2/_mgoncalv-*_s`.

### Option A: persistent (survives a restart)
For each router (`router_mgoncalv-1` and `-2`):
1. Stop the node.
2. Right click → **Edit config** (`/etc/network/interfaces`).
3. Replace the content with `P2/_mgoncalv-N_s` (or `_g` to go back).
4. Start the node.

### Option B: live, from the router console (lost on restart)
```
/sbin/ip link del vxlan10
# router 1 (on router 2, swap local/remote: local 10.1.1.2 remote 10.1.1.1)
/sbin/ip link add name vxlan10 type vxlan id 10 dev eth0 local 10.1.1.1 remote 10.1.1.2 dstport 4789
/sbin/ip link set vxlan10 up
/sbin/ip link set vxlan10 master br0
```

### Check which mode is active
```
/sbin/ip -d link show vxlan10
```
- static    → `remote 10.1.1.2`  (unicast tunnel to a single peer)
- multicast → `group 239.1.1.1`  (VTEPs join a group, BUM traffic goes to it)

In Wireshark, on the router↔switch link, ping between the hosts:
- static: ARP and ICMP are both encapsulated to `10.1.1.x`
- multicast: the first ARP (broadcast) goes to `239.1.1.1`, then the ICMP goes unicast
