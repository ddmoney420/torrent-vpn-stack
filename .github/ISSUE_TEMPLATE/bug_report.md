---
name: Bug Report
about: Report a bug or issue with Torrent VPN Stack
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Environment

**Operating System:**
- [ ] Windows (version: ______)
- [ ] Linux (distribution: ______)
- [ ] macOS (version: ______)

**Docker Version:**
```
# Output of: docker --version
```

**Docker Compose Version:**
```
# Output of: docker compose version
```

**VPN Provider:**
- [ ] Mullvad
- [ ] ProtonVPN
- [ ] Private Internet Access (PIA)
- [ ] NordVPN
- [ ] Other: ______

**VPN Protocol:**
- [ ] WireGuard
- [ ] OpenVPN

## Steps to Reproduce

1.
2.
3.

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Logs

<details>
<summary>Gluetun Logs</summary>

```
# Output of: docker logs gluetun --tail 50
```

</details>

<details>
<summary>qBittorrent Logs</summary>

```
# Output of: docker logs qbittorrent --tail 50
```

</details>

<details>
<summary>Docker Compose Logs (if relevant)</summary>

```
# Output of: docker compose logs --tail 50
```

</details>

## Configuration

<details>
<summary>.env File (SANITIZED - remove credentials)</summary>

```bash
# Paste relevant .env variables here (REMOVE PASSWORDS AND PRIVATE KEYS)
VPN_SERVICE_PROVIDER=
VPN_TYPE=
VPN_PORT_FORWARDING=
# etc.
```

</details>

## Additional Context

Add any other context about the problem here (screenshots, error messages, etc.)

## Checklist

- [ ] I have searched existing issues to avoid duplicates
- [ ] I have tested with the latest version
- [ ] I have removed sensitive information from logs and configuration
- [ ] I have provided complete environment information
