# Credential Pattern Detection Reference

Quick identification chart for common API keys, tokens, and secrets by their prefix/format.

## Stripe

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `sk_live_` | 32+ chars | Secret key (live) | `stripe-key` |
| `sk_test_` | 32+ chars | Secret key (test) | `stripe-key` |
| `rk_live_` | 32+ chars | Restricted key | `stripe-restricted-key` |
| `whsec_` | 32+ chars | Webhook secret | `stripe-webhook` |
| `pk_live_` | 32+ chars | Publishable key (NOT secret, skip vault) | — |
| `ca_` | 24+ chars | Client ID | `stripe-client-id` |
| `price_` | 24+ chars | Price ID (not secret) | — |

## Supabase

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `sbp_` | 40+ chars | Personal Access Token | `supabase-token` |
| `sb_publishable_` | 50+ chars | Publishable/anon key (NOT secret, skip vault) | — |
| `eyJhbGciOiJIUzI1Ni` | JWT | Service role JWT | `supabase-service-key` |

## OpenAI / AI Providers

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `sk-` (not `sk_`) | 51+ chars | OpenAI API key | `openai-key` |
| `sk-or-v1-` | 60+ chars | OpenRouter key | `openrouter-key` |
| `sk-ant-` | 60+ chars | Anthropic key | `anthropic-key` |

## Twilio

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `AC` + 32 hex chars | 34 chars | Account SID | `twilio-account-sid` |
| `VA` + 32 hex chars | 34 chars | Verify Service SID | `twilio-verify-sid` |
| 40 hex chars (no prefix) | 40 chars | Auth Token | `twilio-auth-token` |

## GitHub

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `ghp_` | 40+ chars | Personal access token | `github-token` |
| `gho_` | 40+ chars | OAuth access token | `github-token` |
| `ghu_` | 40+ chars | User-to-server token | `github-token` |
| `ghs_` | 40+ chars | Server-to-server token | `github-token` |

## Email / Communication

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| `re_` | 40+ chars | Resend API key | `resend-key` |
| `SG.` | 80+ chars | SendGrid API key | `sendgrid-key` |

## Hostinger

| Pattern | Length | Type | Vault name |
|---|---|---|---|
| 32 hex chars | 32 chars | API Token | `hostinger-token` |

## Generic Patterns

| Pattern | Probable type | Vault name |
|---|---|---|
| 3 base64 segments separated by dots | JWT token | Use context naming |
| Base64 string ending in `=` or `==` | Generic key/secret | Use context |
| UUID format (8-4-4-4-12 hex) | ID, not a secret | Usually skip |
| `https://...` with key in URL | Endpoint URL | `*-url` |
| Password (any string < 128 chars) | Plain password | `*-password` |

## When to NOT vault

- Publishable keys (Stripe `pk_*`, Supabase `sb_publishable_*`)
- URLs without embedded secrets
- UUIDs and database IDs
- OAuth client IDs (without secret)
- Environment names (`production`, `staging`)

## Mapping conventions

```
# Vault name → env var → config.yaml usage
supabase-token → SUPABASE_ACCESS_TOKEN → ${SUPABASE_ACCESS_TOKEN}
stripe-key     → STRIPE_SECRET_KEY     → ${STRIPE_SECRET_KEY}
```

Auto-conversion for unmapped names: `kebab-case` → `UPPER_SNAKE_CASE`
