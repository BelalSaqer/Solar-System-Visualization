# solar-system-chat (Cloudflare Worker)

Backend for the in-app "Ask AI" astronomy assistant. Runs entirely on
Cloudflare's free tier — no credit card, no third-party API key, no
ongoing cost:

- **Workers AI** runs the chat model (`@cf/meta/llama-3.2-3b-instruct`)
  directly on Cloudflare's infrastructure via the `AI` binding. No API key
  to manage — it's just part of the same Cloudflare account. Free
  allocation: 10,000 Neurons/day, resets daily.
- **Workers KV** (`RATE_LIMIT_KV`) rate-limits by IP (20 messages/hour) so
  one visitor can't exhaust the shared daily allocation for everyone else.

(An earlier version of this proxied to the Claude API instead — dropped
because Anthropic, like every other frontier LLM provider, requires a
funded account with no free tier. Workers AI avoids that entirely for a
still-solid open-source model.)

## One-time setup

```bash
cd worker
npm install
npx wrangler login                       # opens a browser to authorize — free account, no card
npx wrangler kv namespace create RATE_LIMIT_KV
# paste the printed "id" into wrangler.toml's kv_namespaces[0].id
```

## Deploy

```bash
npx wrangler deploy
```

First deploy prompts to register a `workers.dev` subdomain (say yes, pick
a name — it's account-wide, used for any future Workers too). Prints the
live URL (`https://solar-system-chat.<your-subdomain>.workers.dev`) — put
that in `lib/services/chat_service.dart`'s `_endpoint` constant.

## Local dev

```bash
npx wrangler dev
```

## Swapping the model

Change the `MODEL` constant in `src/index.ts` to any text-generation model
from the [Workers AI catalog](https://developers.cloudflare.com/workers-ai/models/).
Larger models answer better but cost more Neurons per request — check the
[pricing page](https://developers.cloudflare.com/workers-ai/platform/pricing/)
before switching if you want to stay comfortably inside the free daily
allocation.
