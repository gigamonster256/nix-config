#!/usr/bin/env python3
"""Generate ExtremeXOS VLAN configuration from JSON intermediate."""

import json
import sys


def expand_ports(ports: list[int]) -> str:
    """Convert a sorted list of port numbers to ranges string.
    [1, 2, 3, 5, 7, 8, 9] -> "1-3,5,7-9"
    """
    if not ports:
        return ""
    ports = sorted(ports)
    ranges = []
    start = ports[0]
    end = ports[0]
    for p in ports[1:]:
        if p == end + 1:
            end = p
        else:
            ranges.append(f"{start}-{end}" if start != end else str(start))
            start = end = p
    ranges.append(f"{start}-{end}" if start != end else str(start))
    return ",".join(ranges)


def generate(config: dict) -> str:
    networks = config["networks"]
    devices = config["devices"]
    max_ports = config["maxPorts"]
    all_ports = set(range(1, max_ports + 1))
    configured_ports = set(d["port"] for d in devices.values())
    disabled_ports = sorted(all_ports - configured_ports)

    # Build tag lookup: vlan_name -> tag
    vlan_tags = {name: net["tag"] for name, net in networks.items() if "tag" in net}

    lines = []

    # --- VLAN creation ---
    lines.append("# VLAN creation")
    for name, tag in sorted(vlan_tags.items(), key=lambda x: x[1]):
        if name != "Default":
            lines.append(f'create vlan "{name}"')
        lines.append(f"configure vlan {name} tag {tag}")
    lines.append("")

    # --- Port disabling ---
    lines.append("# Disable unused ports")
    for p in disabled_ports:
        lines.append(f"disable port {p}")
    lines.append("")

    # --- Determine which ports to remove from Default untagged ---
    remove_from_default = set()
    for dname, dconf in devices.items():
        pnum = dconf["port"]
        untagged = dconf.get("untagged")
        if untagged is None:
            # Tagged-only port — remove from Default untagged
            remove_from_default.add(pnum)
        elif untagged != "Default":
            # Untagged on a different VLAN — remove from Default untagged
            remove_from_default.add(pnum)

    if remove_from_default:
        lines.append("# Remove ports from Default untagged (now untagged elsewhere or tagged-only)")
        lines.append(
            f"configure vlan Default delete ports {expand_ports(sorted(remove_from_default))}"
        )
        lines.append("")

    # --- Port-VLAN assignments ---
    lines.append("# Port VLAN assignments")

    # Gather ports per vlan per mode
    untagged_map = {}  # vlan_name -> [ports]
    tagged_map = {}    # vlan_name -> [ports]

    for dname, dconf in sorted(devices.items(), key=lambda x: x[1]["port"]):
        pnum = dconf["port"]
        untagged = dconf.get("untagged")
        if untagged is not None:
            untagged_map.setdefault(untagged, []).append(pnum)
        for vlan in dconf.get("tagged", []):
            tagged_map.setdefault(vlan, []).append(pnum)

    # Output in VLAN order (by tag)
    vlan_order = sorted(vlan_tags.keys(), key=lambda v: vlan_tags[v])
    for vlan in vlan_order:
        if vlan in tagged_map:
            lines.append(
                f"configure vlan {vlan} add ports {expand_ports(tagged_map[vlan])} tagged"
            )
        if vlan in untagged_map:
            lines.append(
                f"configure vlan {vlan} add ports {expand_ports(untagged_map[vlan])} untagged"
            )
    lines.append("")

    # --- Summary ---
    lines.append("# --- VLAN Summary ---")
    lines.append(f"# VLANs: {', '.join(f'{name} (tag {tag})' for name, tag in sorted(vlan_tags.items(), key=lambda x: x[1]))}")
    lines.append(f"# Active ports: {len(configured_ports)}/{max_ports}")
    lines.append(f"# Disabled ports: {len(disabled_ports)}/{max_ports}")

    # --- IP addressing and DHCP ---
    has_network = any("ipv4" in n or "ipv6" in n or "dhcpOptions" in n for n in networks.values())
    if has_network:
        lines.append("")
        lines.append("# IP addressing")
        for vlan_name, vlan_net in sorted(networks.items()):
            ipv4 = vlan_net.get("ipv4")
            if ipv4:
                lines.append(f'configure vlan {vlan_name} ipaddress {ipv4["address"]} {ipv4["netmask"]}')

            ipv6 = vlan_net.get("ipv6")
            if ipv6:
                if ipv6.get("linkLocal"):
                    lines.append(f'configure {vlan_name} ipaddress eui64 fe80::/64')
                if "address" in ipv6:
                    lines.append(f'configure {vlan_name} ipaddress {ipv6["address"]}')

    # --- DNS name servers ---
    dns_servers = config.get("dnsServers", [])
    if dns_servers:
        lines.append("")
        lines.append("# DNS name servers")
        for server in dns_servers:
            lines.append(f"configure dns-client add name-server {server}")

    # --- Static routes ---
    routes = config.get("routes", {})
    if routes:
        lines.append("")
        lines.append("# Static routes")
        for dest, gateway in routes.items():
            if dest == "default":
                lines.append(f"configure iproute add default {gateway}")
            else:
                lines.append(f"configure iproute add {dest} {gateway}")

    return "\n".join(lines)


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            config = json.load(f)
    else:
        config = json.load(sys.stdin)

    print(generate(config))


if __name__ == "__main__":
    main()
