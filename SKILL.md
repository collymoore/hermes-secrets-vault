---
name: secrets-vault
description: "🔐 Password-protected AES-256 encrypted vault for API keys, tokens, and secrets. Auto-store, SHA fingerprint index, CLI + Hermes skill."
version: 1.0.0
author: collymoore
license: MIT
tags: [security, secrets, vault, encryption, credentials]
metadata:
  source: https://github.com/collymoore/hermes-secrets-vault
  install: curl -fsSL https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/install.sh | bash
---

# Hermes Secrets Vault

**Never lose track of your API keys again.** Password-protected vault with automatic credential storage, SHA fingerprint indexing, and Hermes Agent integration.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/install.sh | bash
```

## What It Does

| Feature | Description |
|---|---|
| **Password-protected** | Your password encrypts everything — PBKDF2 100k iterations |
| **AES-256-CBC** | Military-grade encryption for every secret |
| **Auto-store** | Agent recognizes credentials and vaults them automatically |
| **SHA fingerprint** | Each secret gets a SHA-256 fingerprint — check duplicates without exposing values |
| **Zero plaintext** | Secrets never written to disk unencrypted |
| **Env var injection** | `vault-unlock` exports all secrets as shell env vars |

## CLI Commands

| Command | Description | Needs unlock? |
|---|---|---|
| `vault init` | Initialize vault with master password | No |
| `vault-unlock` | Unlock vault, export secrets as env vars | No (needs password) |
| `vault-lock` | Clear secrets from environment | No |
| `vault status` | Show locked/unlocked | No |
| `vault list` | Show index of stored secrets | No |
| `vault index` | Compact index with SHA fingerprints | No |
| `echo X \| vault check` | Check if a token is already stored | No |
| `vault set name` | Store a new secret | Yes |
| `vault get name` | Retrieve a secret | Yes |
| `vault rm name` | Delete a secret | Yes |
| `vault env name` | Print as NAME=value | Yes |
| `vault change-password` | Change master password | Yes |

## Hermes Integration

Load the skill:
```bash
hermes skills install secrets-vault
```

Or from the repo directly:
```bash
hermes skills install https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/SKILL.md
```

The agent will:
1. Auto-detect credentials you share in chat
2. Prompt to vault them with proper naming
3. Never ask for a token you've already stored

## How It Works

```
Your Password
      ↓ PBKDF2 (SHA-256, 100k iters)
   Vault Key (256-bit, in memory only)
      ↓ AES-256-CBC per secret
   stripe-key.enc → ${STRIPE_SECRET_KEY}
   supabase-token.enc → ${SUPABASE_ACCESS_TOKEN}
```

## Security

- **PBKDF2** — 100,000 iterations SHA-256 prevents brute force
- **No plaintext on disk** — vault key decrypted in memory only
- **chmod 600** — vault files readable only by owner
- **SHA fingerprint index** — check for duplicates without exposing values

## Env Var Mapping

| Vault name | Env var | Typical use |
|---|---|---|
| `supabase-token` | `SUPABASE_ACCESS_TOKEN` | MCP, CLI |
| `stripe-key` | `STRIPE_SECRET_KEY` | Payments |
| `n8n-token` | `N8N_MCP_TOKEN` | MCP server |
| `openai-key` | `OPENAI_API_KEY` | AI provider |
| `openrouter-key` | `OPENROUTER_API_KEY` | AI provider |
| `resend-key` | `RESEND_API_KEY` | Email |
| `github-token` | `GITHUB_TOKEN` | GitHub API |
| `hostinger-token` | `HOSTINGER_API_TOKEN` | DNS |
| `twilio-account-sid` | `TWILIO_ACCOUNT_SID` | SMS |
| `twilio-auth-token` | `TWILIO_AUTH_TOKEN` | Auth |
| *anything else* | `UPPER_SNAKE_CASE` | Generic |

## Auto-Store Protocol

When you share a credential in chat, the agent vaults it automatically:

| Pattern | Vault name |
|---|---|
| `sbp_*` | `supabase-token` |
| `sk_*` / `whsec_*` | `stripe-key` / `stripe-webhook` |
| `AC*` (32 chars) | `twilio-account-sid` |
| `re_*` | `resend-key` |
| `ghp_*` | `github-token` |
| JWT (3 dot-separated segments) | (context-dependent) |

## License

MIT
