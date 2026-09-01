# solar-system-chat (Cloudflare Worker)

Backend proxy for the in-app "Ask AI" astronomy assistant. Holds the
Anthropic API key server-side (via a Worker secret) and rate-limits by IP
(via Workers KV) so the key is never shipped in the Flutter app and a
single visitor can't run up the bill.

Chosen over Firebase Cloud Functions specifically because it has a genuine
free tier with **no credit card required** — Cloud Functions require the
Blaze (pay-as-you-go) plan even at zero usage.

## One-time setup

```bash
cd worker
npm install
npx wrangler login                       # opens a browser to authorize
npx wrangler kv namespace create RATE_LIMIT_KV
# paste the printed "id" into wrangler.toml's kv_namespaces[0].id
npx wrangler secret put ANTHROPIC_API_KEY # prompts for the key, hidden input
```

## Deploy

```bash
npx wrangler deploy
```

Prints the live URL (`https://solar-system-chat.<your-subdomain>.workers.dev`).
Put that in `lib/services/chat_service.dart`'s `_endpoint` constant.

## Local dev

```bash
npx wrangler dev
```
