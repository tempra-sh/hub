# Changelog

## v0.0.1

### Modules
- **SSH hardening** (`sshd_hardening` v0.2.0): 12 rules, CIS 5.2, `sshd -t` pre-check handler
- **Firewall/UFW** (`basic_firewall` v0.2.0): 7 rules, CIS 3.5, correct rule ordering
- **Fail2ban** (`fail2ban_setup` v0.2.0): 5 rules, CIS 5.2 + NIST AC-7, declarative INI checks

### Infrastructure
- `registry.toml` — points to channel files
- `channels/stable.toml` — module catalog with versions and SHA256 checksums
- All modules use handlers with `notify` for batched service restarts
- Fail2ban uses `ini_value` type for section-aware INI file management
