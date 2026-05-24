# Hermes Secrets Vault — Technical Documentation

## What It Is

A password-protected, AES-256-CBC encrypted secrets management system designed for AI agents. It stores API keys, tokens, and passwords in encrypted files that can only be decrypted with the user's master password.

The system has two components:
1. **`vault` CLI** (`/usr/local/bin/vault`) — Unix shell script for managing encrypted secrets
2. **Hermes skill** (`secrets-vault`) — Agent behavior that auto-detects credentials and vaults them

## How It Works (Key Wrapping)

```
User Password "Colly821014++"
        │
        ▼
  PBKDF2-SHA256 (100,000 iterations)
        │
        ▼
  Vault Key (256-bit random, stored encrypted as .keywrap)
        │
        ▼
  AES-256-CBC per secret file:
    ├── supabase-token.enc    →   ${SUPABASE_ACCESS_TOKEN}
    ├── stripe-key.enc        →   ${STRIPE_SECRET_KEY}
    └── *.enc                 →   ${ENV_VAR}
```

Each `.enc` file is independently encrypted with the same vault key. The vault key itself is encrypted with the user's password (key wrapping). Without the user's password, the vault key and all secrets are unrecoverable.

## File Structure

```
~/.hermes/vault/
├── .salt              # 32-byte random salt for PBKDF2 (NOT secret)
├── .keywrap           # Vault key encrypted with user password (AES-256-CBC)
├── .index             # Plain-text manifest: name | env_var | sha8 | description | date | location
├── supabase-token.enc # Single encrypted secret (90 bytes)
└── *.enc              # Any number of additional secrets
```

All files: `chmod 600`. Directory: `chmod 700`.

## CLI Reference

### Initialization (one-time)

| Command | Description |
|---|---|
| `vault init` | Creates `.salt`, `.keywrap`. Prompts for master password. Must run before anything else. |

### Session Management

| Command | Description | Auth needed? |
|---|---|---|
| `vault-unlock` | Alias: `eval "$(vault unlock)"`. Decrypts `.keywrap` with user password, then decrypts all `.enc` files and exports them as environment variables. | Password |
| `vault-lock` | Clears all vault-related environment variables. | No |
| `vault status` | Shows locked/unlocked state and secret count. | No |

### Secret Operations (vault must be unlocked)

| Command | Description |
|---|---|
| `echo 'value' \| vault set <name>` | Encrypts stdin value to `<name>.enc`. Computes SHA-256 fingerprint. Updates `.index`. |
| `vault get <name>` | Decrypts and prints `<name>.enc` to stdout. |
| `vault rm <name>` | Removes `<name>.enc` and its index entry. |
| `vault env <name>` | Prints `ENV_VAR=value` format for sourcing. |

### Querying (no unlock needed)

| Command | Description |
|---|---|
| `vault list` | Shows `.index` with all stored secrets, their env var names, SHA fingerprints, descriptions, dates, and usage locations. |
| `vault index` | Compact version: name + env var + SHA fingerprint. |
| `echo 'token' \| vault check` | Computes SHA-256 of input and compares against `.index` fingerprints. Returns name if match found. |

### Maintenance

| Command | Description |
|---|---|
| `vault change-password` | Decrypts vault key with old password, re-encrypts with new password. All `.enc` files remain intact. |

## SHA Fingerprint Index

Located at `~/.hermes/vault/.index`. Format:

```
name | env_var | sha8:XXXXXXXX | description | YYYY-MM-DD | usage_location
```

The `sha8:` prefix stores the first 8 hex characters of the secret's SHA-256 hash. This enables:

- **Deduplication**: When the user shares a credential, compute its SHA-8 and check if it's already stored
- **Verification**: Confirm the right secret is being used without exposing its value
- **Audit**: Track what's stored and where it's used, all without decrypting

Example:
```
supabase-token | SUPABASE_ACCESS_TOKEN | sha8:6b349b4c | Supabase API token | 2026-05-24 | MCP config.yaml
```

## Environment Variable Mapping

Secrets are exported as environment variables. The mapping follows a deterministic naming convention:

| Vault name | Environment variable |
|---|---|
| `supabase-token` | `SUPABASE_ACCESS_TOKEN` |
| `stripe-key` | `STRIPE_SECRET_KEY` |
| `stripe-webhook` | `STRIPE_WEBHOOK_SECRET` |
| `n8n-token` | `N8N_MCP_TOKEN` |
| `openai-key` | `OPENAI_API_KEY` |
| `openrouter-key` | `OPENROUTER_API_KEY` |
| `resend-key` | `RESEND_API_KEY` |
| `hostinger-token` | `HOSTINGER_API_TOKEN` |
| `github-token` | `GITHUB_TOKEN` |
| `twilio-account-sid` | `TWILIO_ACCOUNT_SID` |
| `twilio-auth-token` | `TWILIO_AUTH_TOKEN` |
| *anything-else* | `ANYTHING_ELSE` (kebab → UPPER_SNAKE) |

## Hermes Agent Integration

### Auto-Store Protocol

When a user shares a credential via chat, the agent automatically:

1. **Recognizes** the credential type from pattern and context
2. **Stores** it in the vault with a descriptive name
3. **Confirms** the mapping: `"✓ Guardado como ${SUPABASE_ACCESS_TOKEN}"`
4. **References** it later via env var without asking the user

Pattern recognition:

| Pattern | Vault name |
|---|---|
| `sbp_*` | `supabase-token` |
| `sk_live_*`, `sk_test_*` | `stripe-key` |
| `whsec_*` | `stripe-webhook` |
| `re_*` | `resend-key` |
| `AC` + 32 chars | `twilio-account-sid` |
| `ghp_*` | `github-token` |
| JWT (3 base64 segments) | context-dependent |

### config.yaml Integration

```yaml
mcp_servers:
  supabase:
    url: https://mcp.supabase.com/mcp?project_ref=xxx
    headers:
      Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}
    timeout: 120
    connect_timeout: 60
```

### Bash Integration

The `vault-unlock` and `vault-lock` functions are defined in `.bashrc` before the non-interactive return guard. A status indicator shows on login:

```
🔒 Vault: locked  (vault-unlock to open)
```

Or after unlocking:

```
🔓 Vault: unlocked
```

## Installation

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/install.sh | bash

# Shell functions (add to ~/.bashrc):
vault-unlock() { eval "$(vault unlock 2>/dev/null)"; }
vault-lock() { vault lock 2>/dev/null; unset VAULT_UNLOCKED; }

# Hermes skill:
hermes skills install https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/SKILL.md
```

## Security Model

| Threat | Mitigation |
|---|---|
| Disk theft / server compromise | All secrets encrypted with AES-256-CBC |
| Brute force password guessing | PBKDF2 with 100,000 iterations |
| Shoulder surfing | No TTY echo on password input |
| Process memory dump | Vault key only in memory while unlocked |
| Accidental exposure in chat | SHA fingerprint, never the actual value |
| Duplicate credential storage | `vault check` before storing |

## Limitations

- **Subprocess env vars**: `vault unlock` sets env vars in its own process. Use `eval "$(vault unlock)"` to load them into the parent shell. This is inherent to Unix process isolation.
- **Non-interactive environments**: Password input requires a TTY. In automated/headless environments, the vault must be unlocked before use.
- **Single user**: Designed for single-user workstations/VPS. Not suitable for multi-user secret sharing.
- **No key rotation**: Secrets are encrypted once. Changing the vault key requires re-encrypting all secrets (manual).

## Source Code

Repository: `github.com/collymoore/hermes-secrets-vault`
License: MIT
Language: Bash (~400 lines)
