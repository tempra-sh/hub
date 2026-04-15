# Tempra Hub

Community hardening modules for [Tempra](https://github.com/tempra-sh/tempra).

## How it works

```
registry.toml          → points to channel files
channels/stable.toml   → lists modules with versions + SHA256
modules/               → the actual module TOML files
```

The tempra binary clones this repo to `/etc/tempra/modules/`, reads `registry.toml` to find the active channel, then loads modules listed in that channel.

## Available Modules

| Module | Version | Rules | Standards |
|--------|---------|-------|-----------|
| `sshd_hardening` | 0.2.0 | 12 | CIS 5.2 |
| `basic_firewall` | 0.2.0 | 7 | CIS 3.5 |
| `fail2ban_setup` | 0.2.0 | 5 | CIS 5.2, NIST AC-7 |

## Channels

| Channel | Description | File |
|---------|-------------|------|
| **stable** | Production-ready, tested modules (default) | `channels/stable.toml` |
| testing | Under review, may have issues | `channels/testing.toml` |
| develop | Bleeding edge | `channels/develop.toml` |

## Module format

Modules are TOML files. Available check/remediate types:

| Type | Use case |
|------|----------|
| `config_line` | Key/value in config files (sshd_config) |
| `ini_value` | Key/value in INI sections (fail2ban jail.local) |
| `service_state` | systemd service enabled/active |
| `package` | apt package installed/absent |
| `sysctl` | Kernel parameter |
| `command` | Arbitrary command (escape hatch) |
| `template_file` | Render a template file with params (planned) |

## Contributing

1. Create module under `modules/<category>/<name>.toml`
2. Use declarative check/remediate types — avoid `command` when possible
3. Add handlers with `pre_check` for config validation before service restart
4. Test with `sudo tempra plan --modules-dir ./modules`
5. Submit PR — module gets added to `channels/testing.toml` first
6. After validation, promoted to `channels/stable.toml`
