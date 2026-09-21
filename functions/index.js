const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const model = "gemini-3.6-flash";
const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

const systemPrompt = `
You are the AIDHD support assistant.

Only discuss ADHD-related focus, routines, organization, study strategies,
emotional regulation, and general educational support.

Do not diagnose ADHD. Do not prescribe medication or give treatment
instructions. Do not pretend to be a doctor. For medical or treatment
questions, recommend speaking with a qualified healthcare professional.

Use supportive, practical, concise language. Do not make assumptions about the
user's diagnosis. If the user mentions immediate danger or self-harm, encourage
contacting local emergency services or a crisis line immediately.

Use the user's initial assessment, recent mood check-ins, and daily assessments
as context. Start with empathy and one practical next step. Ask a gentle
follow-up question instead of giving a long list of advice. Keep suggestions
small, concrete, and easy to try today.
`;

exports.chatWithGemini = onCall(
  { secrets: [geminiApiKey], region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before using the chat.");
    }

    const data = request.data || {};
    const message = typeof data.message === "string" ? data.message.trim() : "";
    if (!message || message.length > 4000) {
      throw new HttpsError("invalid-argument", "Your message is empty or too long.");
    }

    const suppliedHistory = Array.isArray(data.history) ? data.history : [];
    const history = suppliedHistory
      .filter((item) =>
        item &&
        (item.role === "user" || item.role === "model") &&
        typeof item.text === "string" &&
        item.text.trim().length > 0,
      )
      .slice(-20)
      .map((item) => ({
        role: item.role,
        parts: [{ text: item.text.slice(0, 4000) }],
      }));

    const userContext =
      data.userContext && typeof data.userContext === "object"
        ? JSON.stringify(data.userContext).slice(0, 12000)
        : "{}";

    const response = await fetch(`${endpoint}?key=${encodeURIComponent(geminiApiKey.value())}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: [
          ...history,
          {
            role: "user",
            parts: [
              {
                text: `User context:\n${userContext}\n\nUser message:\n${message}`,
              },
            ],
          },
        ],
        generationConfig: { temperature: 0.7, maxOutputTokens: 700 },
      }),
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      logger.error("Gemini request failed", { status: response.status, payload });
      throw new HttpsError(
        response.status === 429 ? "resource-exhausted" : "internal",
        response.status === 429
          ? "The assistant usage limit has been reached. Please try again later."
          : "The assistant is temporarily unavailable.",
      );
    }

    const reply = payload.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof reply !== "string" || !reply.trim()) {
      throw new HttpsError("internal", "Gemini returned an empty response.");
    }
    return { text: reply.trim() };
  },
);
