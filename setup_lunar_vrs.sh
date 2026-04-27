#!/bin/bash
# ==============================================================================
# LUNAR VIRTUAL ROUTER: "PATCH CABLE" DEPLOYMENT
# Target: X-ES XPedite2570 (Zynq MPSoC)
# ==============================================================================

# 1. Create Namespaces (The Virtual Routers)

# connect these routers using veth pairs. In a lunar environment, this is superior to a virtual switch because it’s deterministic and consumes less RAM.
ip netns add VR_FS_PRIMARY  # Fixed Site: Earth/Lunanet Comms
ip netns add VR_FS_LOCAL    # Fixed Site: Local Base Hub/Registry
ip netns add VR_FR_COMMS     # Hopper: Lunanet/Optical Pickup
ip netns add VR_FR_INTERNAL  # Hopper: GNC/O2 Harvesting/Accounting

# 2. Create "Virtual Patch Cables" (veth pairs)
# Fixed Site Internal Bridge
ip link add veth_fs_pri type veth peer name veth_fs_loc

# Hopper Internal Bridge
ip link add veth_fr_com type veth peer name veth_fr_int

# 3. Connect the Cables to the VRs
# "Plugging" the ends of the cables into their respective namespaces
ip link set veth_fs_pri netns VR_FS_PRIMARY
ip link set veth_fs_loc netns VR_FS_LOCAL

ip link set veth_fr_com netns VR_FR_COMMS
ip link set veth_fr_int netns VR_FR_INTERNAL

# 4. Bring up the Links (Fixed Site)
# Setting up a /30 subnet (Point-to-Point) for minimal overhead
echo "[+] Initializing Fixed Site VRs..."
ip netns exec VR_FS_PRIMARY ip addr add 192.168.10.1/30 dev veth_fs_pri
ip netns exec VR_FS_PRIMARY ip link set veth_fs_pri up
ip netns exec VR_FS_PRIMARY ip link set lo up

ip netns exec VR_FS_LOCAL ip addr add 192.168.10.2/30 dev veth_fs_loc
ip netns exec VR_FS_LOCAL ip link set veth_fs_loc up
ip netns exec VR_FS_LOCAL ip link set lo up

# 5. Bring up the Links (Hopper)
echo "[+] Initializing Hopper VRs..."
ip netns exec VR_FR_COMMS ip addr add 192.168.20.1/30 dev veth_fr_com
ip netns exec VR_FR_COMMS ip link set veth_fr_com up
ip netns exec VR_FR_COMMS ip link set lo up

ip netns exec VR_FR_INTERNAL ip addr add 192.168.20.2/30 dev veth_fr_int
ip netns exec VR_FR_INTERNAL ip link set veth_fr_int up
ip netns exec VR_FR_INTERNAL ip link set lo up

# 6. Verify Connectivity
echo "[+] Connectivity Check..."
ip netns exec VR_FS_PRIMARY ping -c 1 192.168.10.2 > /dev/null && echo "Fixed Site Patched."
ip netns exec VR_FR_COMMS ping -c 1 192.168.20.2 > /dev/null && echo "Hop
