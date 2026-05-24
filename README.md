# Hermes Secrets Vault

![License: MIT](https://img.shields.io/badge/license-MIT-green)

> Password-protected AES-256 encrypted vault for API keys, tokens, and passwords.

**Hermes Secrets Vault** is a lightweight CLI tool that stores your secrets in an encrypted vault on disk. A single human-memorable password protects all your secrets via PBKDF2 key derivation and AES-256-CBC encryption. Designed for developer machines, CI/CD runners, and Hermes Agent integration.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/collymoore/hermes-secrets-vault/main/install.sh | bash
```

## Features

- **AES-256 encryption** — every secret is encrypted with AES-256-CBC before touching disk
- **Password-protected** — a single vault password unlocks all secrets; no keyfiles to manage
- **CLI `vault` command** — intuitive subcommands for full vault lifecycle
- **SHA fingerprint index** — each secret is indexed by SHA-256 hash of its name for fast, deterministic lookups
- **Auto-store protocol** — `vault set` auto-creates entries; `vault get` auto-unlocks if the vault is locked
- **Hermes skill integration** — SKILL.md enables Hermes Agent to read/write secrets transparently
- **No plaintext on disk** — encrypted files are `chmod 600`; decrypted content lives only in memory

## How It Works

```
Password (human) ──▶ PBKDF2 (100k iterations, SHA-256) ──▶ Vault Key (256-bit)
                                                                 │
                                                    ┌────────────┤
                                                    ▼            ▼
                                           AES-256-CBC      AES-256-CBC
                                           (vault lock)     (per secret)
                                                    │            │
                                                    ▼            ▼
                                              .vault-key    *.enc files
```

1. **Initialization** — `vault init` generates a random salt and derives a 256-bit key from your password using PBKDF2 with 100,000 iterations.
2. **Wrapping** — The derived key encrypts itself with the password-derived key and stores the result in `.vault-key`. The raw key never exists on disk.
3. **Secrets** — Each secret is encrypted with AES-256-CBC using the vault key and stored as `name.enc`. A SHA-256 fingerprint of the secret name acts as the index.
4. **Unlocking** — `vault unlock` re-derives the vault key from your password, decrypts `.vault-key`, and holds the key in memory for subsequent `vault get`/`vault set` operations.

## CLI Reference

| Command | Description |
|---|---|
| `vault init` | Initialize a new vault in the current directory |
| `vault unlock` | Unlock the vault with your password |
| `vault lock` | Lock the vault (clear key from memory) |
| `vault set <name>` | Encrypt and store a secret (prompts for value) |
| `vault get <name>` | Decrypt and print a secret |
| `vault list` | List all stored secret names |
| `vault rm <name>` | Remove a secret from the vault |
| `vault check <name>` | Check if a secret exists |
| `vault index` | Show the SHA fingerprint index for all secrets |
| `vault status` | Show whether the vault is initialized, locked, or unlocked |
| `vault change-password` | Re-wrap the vault key with a new password |

## Security

- **PBKDF2 with 100,000 iterations** of HMAC-SHA-256 — strong defense against brute-force attacks
- **AES-256-CBC** — industry-standard symmetric encryption with a random IV per secret
- **chmod 600** — all sensitive files (`*.enc`, `.vault-key`) are locked to the owning user
- **No plaintext on disk** — secrets are only decrypted in memory; `vault lock` wipes the key from the process
- **Independent salt per vault** — the PBKDF2 salt is generated at init time and stored alongside the vault

## Environment Variable Mapping

The vault is designed to map secret names to common environment variable names used by frameworks and SDKs:

| Secret Name | Environment Variable | Typical Service |
|---|---|---|
| `supabase-token` | `SUPABASE_ACCESS_TOKEN` | Supabase |
| `supabase-url` | `SUPABASE_URL` | Supabase |
| `supabase-key` | `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_KEY` | Supabase |
| `stripe-key` | `STRIPE_SECRET_KEY` | Stripe |
| `stripe-publishable` | `STRIPE_PUBLISHABLE_KEY` | Stripe |
| `github-token` | `GITHUB_TOKEN` / `GH_TOKEN` | GitHub |
| `openai-key` | `OPENAI_API_KEY` | OpenAI |
| `anthropic-key` | `ANTHROPIC_API_KEY` | Anthropic |
| `aws-access-key` | `AWS_ACCESS_KEY_ID` | AWS |
| `aws-secret-key` | `AWS_SECRET_ACCESS_KEY` | AWS |
| `docker-token` | `DOCKER_TOKEN` | Docker Hub |
| `npm-token` | `NPM_TOKEN` | npm |
| `postgres-url` | `DATABASE_URL` / `POSTGRES_URL` | PostgreSQL |
| `redis-url` | `REDIS_URL` | Redis |
| `jwt-secret` | `JWT_SECRET` | Application |

## Hermes Agent Integration

When installed as a Hermes Agent skill, the vault provides:

- **`vault get <name>`** — Hermes can retrieve secrets during conversation
- **`vault set <name>`** — Hermes can store new secrets on your behalf
- **`vault check <name>`** — Hermes can verify secret existence before operations
- **Seamless unlock** — if the vault is locked, Hermes prompts for the password once

The SKILL.md file at the repository root defines the skill interface for Hermes Agent.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

All contributions are welcome — bug fixes, documentation improvements, and new features.

## License

MIT — see [LICENSE](LICENSE) for details.
