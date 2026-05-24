---
name: secrets-vault
description: "Hermes Secrets Vault — Password-protected AES-256 encrypted secrets stored in ~/.hermes/vault/. Auto-store ALL credentials received from user."
version: 3.0.0
author: Hermes Agent
---

# Secrets Vault (Password-Protected)

AES-256-CBC encrypted vault for API keys, tokens, and passwords. Protected by user's master password.

**Critical rule: ANY credential the user shares must be vaulted immediately. Never leave a key/token/password only in conversation history.**

## Architecture

```
~/.hermes/vault/
├── .salt              # Random salt for key derivation (PBKDF2)
├── .keywrap           # Vault key encrypted with user password (AES-256)
├── supabase-token.enc # Encrypted secret
└── *.enc              # Any other secrets
```

**Key wrapping:** User password → PBKDF2(100k SHA-256 iters) → decrypts vault key → decrypts each `.enc` file.

## CLI Usage

```bash
# Initial setup (one-time)
vault init                    # Prompts for master password

# Daily use
vault-unlock                  # Prompts for password → exports all as env vars
vault-lock                    # Clears all secrets from environment
vault status                  # Shows locked/unlocked + count

# Manage secrets (vault must be unlocked)
echo 'sk-xxx' | vault set stripe-key    # Store
vault get supabase-token                 # Retrieve
vault list                               # List all
vault rm old-key                         # Delete
vault env supabase-token                 # Print as NAME=value

# Maintenance
vault change-password         # Change master password
vault export > ~/.env         # Bulk export all as .env format
```

## Auto-Store Protocol (Agent Behavior)

When user sends a credential via chat, the agent MUST:

1. **Identify** what service/key it belongs to (from conversation context + pattern)
2. **Unlock vault** — `eval "$(vault unlock 2>/dev/null)"` using password from user if needed
3. **Store** — `echo 'value' | vault set <service-name>`
4. **Confirm** — state the vault name and env var mapping

### Pattern recognition chart

| Pattern | Likely service | Vault name |
|---|---|---|
| `sbp_*` | Supabase personal access token | `supabase-token` |
| `sk_live_*` / `sk_test_*` | Stripe secret key | `stripe-key` |
| `whsec_*` | Stripe webhook secret | `stripe-webhook` |
| `rk_live_*` | Stripe restricted key | `stripe-restricted-key` |
| `re_*` | Resend API key | `resend-key` |
| `AC*` (32 chars) | Twilio Account SID | `twilio-account-sid` |
| `VA*` (34 chars) | Twilio Verify SID | `twilio-verify-sid` |
| `ghp_*` | GitHub personal access token | `github-token` |
| `gho_*` | GitHub OAuth token | `github-token` |
| `sk-*` | OpenAI API key | `openai-key` |
| `sk-or-v1-*` | OpenRouter key | `openrouter-key` |
| `ea*` (32 hex) | Hostinger API token | `hostinger-token` |
| Starts with `http://` or `https://` | URL (store as is if it's an endpoint) | `*-url` |
| JWT (3 dot-separated base64 segments) | Generic token | Use context |
| Base64 (40+ chars, ends with `=`) | Likely a key | Use context |

### Context disambiguation

When pattern alone isn't enough, use conversation context:
- "Aquí está mi Stripe..." → `stripe-key`
- "Twilio dice..." → `twilio-auth-token` or `twilio-account-sid`
- "Para el MCP..." → likely needs to go in config.yaml env var
- "Esta es la API de..." → use the service name

### After storing

- Add to `HERMES_ACCESS_TOKENS` or note the mapping in memory
- If it's needed for an MCP server, update `config.yaml` to reference `${ENV_VAR}`

## Security

- **No plaintext on disk** — vault key decrypted in memory only, never written
- **PBKDF2** — 100,000 iterations SHA-256, prevents brute force
- **AES-256-CBC** — FIPS 197 standard block cipher
- **chmod 600** — all vault files readable only by root
- **Lock on demand** — `vault-lock` unsets all env vars from the running shell
- **Without user password** — vault contents are unrecoverable

## Env Var Mapping (config.yaml)

Secrets become env vars with kebab-to-snake-case conversion:

| Vault name | Env var | Used in |
|---|---|---|
| `supabase-token` | `SUPABASE_ACCESS_TOKEN` | MCP server auth |
| `n8n-token` | `N8N_MCP_TOKEN` | MCP server auth |
| `stripe-key` | `STRIPE_SECRET_KEY` | API backend |
| `stripe-webhook` | `STRIPE_WEBHOOK_SECRET` | Webhook verification |
| `openai-key` | `OPENAI_API_KEY` | AI provider |
| `openrouter-key` | `OPENROUTER_API_KEY` | AI provider |
| `resend-key` | `RESEND_API_KEY` | Email service |
| `hostinger-token` | `HOSTINGER_API_TOKEN` | DNS/domain API |
| `github-token` | `GITHUB_TOKEN` | GitHub API |
| `twilio-account-sid` | `TWILIO_ACCOUNT_SID` | SMS/WhatsApp |
| `twilio-auth-token` | `TWILIO_AUTH_TOKEN` | Twilio auth |
| `twilio-verify-sid` | `TWILIO_VERIFY_SID` | OTP verification |
| *anything else* | `UPPER_SNAKE_CASE` | Generic |

In config.yaml:
```yaml
mcp_servers:
  supabase:
    headers:
      Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}
```

## Pitfalls

- **`local` keyword in bash**: Only valid inside functions. The `vault` CLI script's `case` block is NOT a function — never use `local` there.
- **Env vars in subprocess**: `vault unlock` sets env vars in its own process. Use `eval "$(vault unlock)"` or the `vault-unlock` bash function to load them into the parent shell.
- **Non-interactive shells**: `.bashrc` typically returns early when `[ -z "$PS1" ]`. Vault helper functions and status must be defined BEFORE the non-interactive return line.
- **Pipe to vault set**: Always `echo -n 'value' | vault set name` (no trailing newline). The `echo 'value'` adds a newline which becomes part of the encrypted secret.
