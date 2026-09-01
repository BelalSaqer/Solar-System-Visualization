import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import Anthropic from "@anthropic-ai/sdk";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

initializeApp();

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

const SYSTEM_PROMPT =
  "You are the friendly astronomy assistant built into the \"Solar System " +
  "Visualization\" app, a Flutter app that lets people explore the solar " +
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
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

interface ChatTurn {
  role?: string;
  content?: string;
}

interface ChatRequestBody {
  message?: string;
  history?: ChatTurn[];
  selectedPlanet?: string;
}

/**
 * Firestore-backed rate limit, keyed by client IP. Persists across cold
 * starts/instances (unlike an in-memory counter), which matters since this
 * endpoint is publicly reachable and calls a billed API.
 */
async function checkRateLimit(ip: string): Promise<boolean> {
  const db = getFirestore();
  const ref = db.collection("chatRateLimits").doc(ip);
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() as { windowStart?: number; count?: number } | undefined;

    if (!data || now - (data.windowStart ?? 0) > RATE_LIMIT_WINDOW_MS) {
      tx.set(ref, { windowStart: now, count: 1 });
      return true;
    }
    if ((data.count ?? 0) >= RATE_LIMIT_PER_WINDOW) {
      return false;
    }
    tx.update(ref, { count: FieldValue.increment(1) });
    return true;
  });
}

function sanitizeHistory(history: unknown): Anthropic.MessageParam[] {
  if (!Array.isArray(history)) return [];
  return history.slice(-MAX_HISTORY_MESSAGES).map((turn: ChatTurn) => ({
    role: turn.role === "assistant" ? "assistant" : "user",
    content: String(turn.content ?? "").slice(0, MAX_MESSAGE_LENGTH),
  }));
}

export const chatWithAssistant = onRequest(
  { secrets: [anthropicApiKey], cors: true, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const ip =
      (req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0]?.trim() ||
      req.ip ||
      "unknown";

    try {
      const allowed = await checkRateLimit(ip);
      if (!allowed) {
        res.status(429).json({
          error: "You've reached the chat limit for this hour — please try again later.",
        });
        return;
      }
    } catch (error) {
      // Fail open on infra hiccups rather than blocking legitimate users.
      logger.error("Rate limit check failed", error);
    }

    const body = req.body as ChatRequestBody;
    const message = (body.message ?? "").trim();

    if (!message) {
      res.status(400).json({ error: "message is required" });
      return;
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      res.status(400).json({ error: `message must be ${MAX_MESSAGE_LENGTH} characters or fewer` });
      return;
    }

    const history = sanitizeHistory(body.history);
    const contextNote = body.selectedPlanet
      ? `\n\nThe user currently has ${body.selectedPlanet} selected in the app.`
      : "";

    try {
      const client = new Anthropic({ apiKey: anthropicApiKey.value() });
      const response = await client.messages.create({
        model: "claude-opus-5",
        max_tokens: MAX_RESPONSE_TOKENS,
        system: SYSTEM_PROMPT + contextNote,
        output_config: { effort: "low" },
        messages: [...history, { role: "user", content: message }],
      });

      const reply = response.content
        .filter((block): block is Anthropic.TextBlock => block.type === "text")
        .map((block) => block.text)
        .join("\n")
        .trim();

      res.status(200).json({ reply: reply || "I'm not sure how to answer that — could you rephrase?" });
    } catch (error) {
      logger.error("Anthropic API error", error);
      res.status(502).json({ error: "The assistant is unavailable right now. Please try again." });
    }
  },
);
