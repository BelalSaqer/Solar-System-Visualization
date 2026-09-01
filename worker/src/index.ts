export interface Env {
  ANTHROPIC_API_KEY: string;
  RATE_LIMIT_KV: KVNamespace;
}

const SYSTEM_PROMPT =
  'You are the friendly astronomy assistant built into the "Solar System ' +
  'Visualization" app, a Flutter app that lets people explore the solar ' +
  "system, browse an astronomy timeline, and take a quiz. Answer questions " +
  "about planets, moons, space missions, and astronomy in general. Keep " +
  "replies conversational and concise (a few sentences, occasionally a " +
  "short paragraph for something that needs more detail) since this is a " +
  "compact in-app chat panel, not a long-form document. If a question is " +
  "unrelated to space or astronomy, politely steer the conversation back.";

const MAX_MESSAGE_LENGTH = 500;
const MAX_HISTORY_MESSAGES = 10;
const MAX_RESPONSE_TOKENS = 600;
const RATE_LIMIT_PER_WINDOW = 20;
const RATE_LIMIT_WINDOW_SECONDS = 60 * 60; // 1 hour

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

interface ChatTurn {
  role?: string;
  content?: string;
}

interface ChatRequestBody {
  message?: string;
  history?: ChatTurn[];
  selectedPlanet?: string;
}

interface AnthropicMessage {
  role: "user" | "assistant";
  content: string;
}

function sanitizeHistory(history: unknown): AnthropicMessage[] {
  if (!Array.isArray(history)) return [];
  return (history as ChatTurn[]).slice(-MAX_HISTORY_MESSAGES).map((turn) => ({
    role: turn.role === "assistant" ? "assistant" : "user",
    content: String(turn.content ?? "").slice(0, MAX_MESSAGE_LENGTH),
  }));
}

/**
 * KV-backed rate limit, keyed by client IP. Persists across cold starts and
 * edge locations — this endpoint is publicly reachable and calls a billed
 * API, so this is the main defense against runaway spend (alongside a
 * spend limit set directly on the Anthropic console, which is the real
 * backstop no amount of app-side code can substitute for).
 */
async function checkRateLimit(kv: KVNamespace, ip: string): Promise<boolean> {
  const key = `rl:${ip}`;
  const raw = await kv.get(key);
  const count = raw ? parseInt(raw, 10) : 0;

  if (count >= RATE_LIMIT_PER_WINDOW) {
    return false;
  }

  await kv.put(key, String(count + 1), { expirationTtl: RATE_LIMIT_WINDOW_SECONDS });
  return true;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

    try {
      const allowed = await checkRateLimit(env.RATE_LIMIT_KV, ip);
      if (!allowed) {
        return jsonResponse(
          { error: "You've reached the chat limit for this hour — please try again later." },
          429,
        );
      }
    } catch (error) {
      // Fail open on infra hiccups rather than blocking legitimate users.
      console.error("Rate limit check failed", error);
    }

    let body: ChatRequestBody;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const message = (body.message ?? "").trim();
    if (!message) {
      return jsonResponse({ error: "message is required" }, 400);
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      return jsonResponse({ error: `message must be ${MAX_MESSAGE_LENGTH} characters or fewer` }, 400);
    }

    const history = sanitizeHistory(body.history);
    const contextNote = body.selectedPlanet
      ? `\n\nThe user currently has ${body.selectedPlanet} selected in the app.`
      : "";

    try {
      const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-opus-5",
          max_tokens: MAX_RESPONSE_TOKENS,
          system: SYSTEM_PROMPT + contextNote,
          output_config: { effort: "low" },
          messages: [...history, { role: "user", content: message }],
        }),
      });

      if (!anthropicResponse.ok) {
        const errText = await anthropicResponse.text();
        console.error("Anthropic API error", anthropicResponse.status, errText);
        return jsonResponse({ error: "The assistant is unavailable right now. Please try again." }, 502);
      }

      const data = (await anthropicResponse.json()) as {
        content: { type: string; text?: string }[];
      };
      const reply = data.content
        .filter((block) => block.type === "text" && block.text)
        .map((block) => block.text)
        .join("\n")
        .trim();

      return jsonResponse({
        reply: reply || "I'm not sure how to answer that — could you rephrase?",
      });
    } catch (error) {
      console.error("Anthropic API call failed", error);
      return jsonResponse({ error: "The assistant is unavailable right now. Please try again." }, 502);
    }
  },
};
