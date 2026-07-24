---
name: glaze-byok-ai
description: Give Glaze app users a choice of AI engine - built-in Glaze AI (zero setup, uses their Glaze credits) or their own free API key (Google Gemini free tier, optionally OpenRouter free models). Use whenever an app built with glaze-coder gets an AI feature, so end users can decide whether using the app costs them anything. Covers the provider service, encrypted key storage, IPC handlers, settings UI, and blocked-state fallback.
---

# User-selectable AI engine for Glaze apps (Glaze AI or BYOK)

Default policy for apps built with glaze-coder: when an app calls AI, the end user
gets to pick the engine. Glaze AI works with zero setup but spends the user's Glaze
credits; a bring-your-own-key engine is free for them (Gemini has a real free tier).
Implement this choice unless the user building the app explicitly wants Glaze-only,
or the app targets users known to have Claude Code (then see `glaze-claude-cli`).

Reference implementation: the News Flow app (`ai-provider.ts` + "AI-motor" settings
section + onboarding engine step). This file contains everything needed to reproduce
it in any app.

## The three engines

| Engine | Cost for the user | Setup | Notes |
| --- | --- | --- | --- |
| `glaze` (default) | Glaze credits | none | Always the default and the fallback |
| `gemini` | free | paste a free AI Studio key | ~250 calls/day free tier; recommended free option |
| `openrouter` | free | paste an OpenRouter key | ~50 calls/day unfunded; `openrouter/free` auto-routes; optional third choice |

Rules that keep this correct and honest:

- Glaze stays the default. A missing or invalid BYOK key must silently fall back to
  Glaze AI, never break the feature.
- Keep `glaze.capabilities.ai` declared in `package.json` (grades matching the code),
  since Glaze remains default + fallback. Publish rejects AI apps without it.
- Keys are encrypted with `safeStorage`, stored in userData, and never sent to the
  renderer. Only boolean `hasKey` flags cross IPC.
- Key links: Gemini keys at `https://aistudio.google.com/apikey`, OpenRouter keys at
  `https://openrouter.ai/settings/keys`. Open via `shell.openExternal`. Automatic key
  provisioning is not possible; a deep link plus paste field is the simplest flow.
- The "Test" button makes one tiny `generateText` call against the user's own key,
  only when clicked. Never run it (or any AI call) yourself during verification;
  verify with type-check and build only.
- Do not put pricing copy next to AI controls beyond the engine descriptions; Glaze's
  own consent UI explains credits.

## Dependencies

From the app's `.glaze-sources/` (bundled Node on PATH, managed npmrc):

```bash
npm install --include=dev @ai-sdk/google @ai-sdk/openai-compatible
```

Both are pure JS and bundle cleanly. The SDK's bundled `ai` package accepts
third-party provider models (it upgrades provider spec v2/v3 internally), so these
plug straight into the `generateObject`/`generateText` re-exported by `@glaze/core/ai`.

## Backend: `main/services/ai-provider.ts`

Adapt storage to the app: if it already has a JSON store helper, reuse it; otherwise
keep the inline `readJson`/`writeJson` below. Everything else drops in as is.

```typescript
// AI engine selection: "glaze" (built-in, credits) | "gemini" | "openrouter" (BYOK).
// Keys are safeStorage-encrypted and never leave the backend.
import { generateText, glaze, type LanguageModel } from "@glaze/core/ai";
import { app, logger, safeStorage } from "@glaze/core/backend";
import { createGoogleGenerativeAI } from "@ai-sdk/google";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import fs from "fs/promises";
import path from "path";

export type AIProviderId = "glaze" | "gemini" | "openrouter";
export interface AISettings { provider: AIProviderId; openrouterModel: string; }
export interface AISettingsView extends AISettings { hasGeminiKey: boolean; hasOpenrouterKey: boolean; }

export const GEMINI_MODEL = "gemini-2.5-flash";
export const DEFAULT_OPENROUTER_MODEL = "openrouter/free";
const DEFAULTS: AISettings = { provider: "glaze", openrouterModel: DEFAULT_OPENROUTER_MODEL };

async function fileIn(name: string): Promise<string> {
  const dir = app.getPath("userData");
  await fs.mkdir(dir, { recursive: true });
  return path.join(dir, name);
}
async function readJson<T>(name: string, fallback: T): Promise<T> {
  try { return JSON.parse(await fs.readFile(await fileIn(name), "utf-8")) as T; }
  catch { return fallback; }
}
async function writeJson(name: string, value: unknown): Promise<void> {
  await fs.writeFile(await fileIn(name), JSON.stringify(value, null, 2), "utf-8");
}

const SETTINGS_FILE = "ai-settings.json";
const KEYS_FILE = "ai-keys.json"; // base64 of safeStorage-encrypted buffers

export async function getAISettings(): Promise<AISettingsView> {
  const s = { ...DEFAULTS, ...(await readJson<Partial<AISettings>>(SETTINGS_FILE, {})) };
  const keys = await readJson<Partial<Record<AIProviderId, string>>>(KEYS_FILE, {});
  return { ...s, hasGeminiKey: !!keys.gemini, hasOpenrouterKey: !!keys.openrouter };
}

export async function updateAISettings(patch: Partial<AISettings>): Promise<AISettingsView> {
  const current = { ...DEFAULTS, ...(await readJson<Partial<AISettings>>(SETTINGS_FILE, {})) };
  const provider: AIProviderId =
    patch.provider === "glaze" || patch.provider === "gemini" || patch.provider === "openrouter"
      ? patch.provider : current.provider;
  const openrouterModel = patch.openrouterModel?.trim() || current.openrouterModel || DEFAULT_OPENROUTER_MODEL;
  await writeJson(SETTINGS_FILE, { provider, openrouterModel });
  return getAISettings();
}

export async function setProviderKey(provider: AIProviderId, key: string): Promise<AISettingsView> {
  if (provider === "glaze") return getAISettings();
  const keys = await readJson<Partial<Record<AIProviderId, string>>>(KEYS_FILE, {});
  const trimmed = key.trim();
  if (!trimmed) delete keys[provider];
  else keys[provider] = (await safeStorage.encryptString(trimmed)).toString("base64");
  await writeJson(KEYS_FILE, keys);
  return getAISettings();
}

async function getProviderKey(provider: AIProviderId): Promise<string | null> {
  const keys = await readJson<Partial<Record<AIProviderId, string>>>(KEYS_FILE, {});
  const stored = keys[provider];
  if (!stored) return null;
  try { return await safeStorage.decryptString(Buffer.from(stored, "base64")); }
  catch (error) { logger.error("ai-provider", `Could not decrypt ${provider} key`, error); return null; }
}

export interface ResolvedModel { provider: AIProviderId; model: LanguageModel; }

/** Model for the engine the user picked. Missing key = silent fallback to Glaze. */
export async function resolveModel(): Promise<ResolvedModel> {
  const s = { ...DEFAULTS, ...(await readJson<Partial<AISettings>>(SETTINGS_FILE, {})) };
  if (s.provider === "gemini") {
    const apiKey = await getProviderKey("gemini");
    if (apiKey) return { provider: "gemini", model: createGoogleGenerativeAI({ apiKey })(GEMINI_MODEL) };
  } else if (s.provider === "openrouter") {
    const apiKey = await getProviderKey("openrouter");
    if (apiKey) {
      const openrouter = createOpenAICompatible({ name: "openrouter", baseURL: "https://openrouter.ai/api/v1", apiKey });
      return { provider: "openrouter", model: openrouter(s.openrouterModel || DEFAULT_OPENROUTER_MODEL) };
    }
  }
  return { provider: "glaze", model: glaze("fast") };
}

/** Map BYOK errors to blocked states so callers keep their non-AI fallbacks. */
export function byokBlockedState(error: unknown): string {
  const m = error instanceof Error ? `${error.message} ${String((error as { statusCode?: unknown }).statusCode ?? "")}` : String(error);
  if (/\b(401|403)\b|api.?key|unauthorized|forbidden/i.test(m)) return "byok-invalid-key";
  if (/\b429\b|rate.?limit|quota|resource.?exhausted/i.test(m)) return "byok-rate-limit";
  if (/fetch failed|network|enotfound|econnrefused|etimedout|socket/i.test(m)) return "byok-network";
  return "byok-error";
}

/** One tiny live call to confirm the stored key works. Only ever user-triggered. */
export async function testProvider(provider: AIProviderId): Promise<{ ok: boolean; error?: string }> {
  try {
    if (provider === "glaze") return { ok: true };
    const s = { ...DEFAULTS, ...(await readJson<Partial<AISettings>>(SETTINGS_FILE, {})) };
    const apiKey = await getProviderKey(provider);
    if (!apiKey) return { ok: false, error: "No key stored." };
    const model: LanguageModel = provider === "gemini"
      ? createGoogleGenerativeAI({ apiKey })(GEMINI_MODEL)
      : createOpenAICompatible({ name: "openrouter", baseURL: "https://openrouter.ai/api/v1", apiKey })(s.openrouterModel || DEFAULT_OPENROUTER_MODEL);
    const { text } = await generateText({ model, prompt: "Reply with the single word: ok", maxOutputTokens: 20 });
    return text.trim() ? { ok: true } : { ok: false, error: "Empty reply from the model." };
  } catch (error) {
    logger.error("ai-provider", `Key test failed for ${provider}`, error);
    const state = byokBlockedState(error);
    const messages: Record<string, string> = {
      "byok-invalid-key": "The key was rejected. Check that it is correct.",
      "byok-rate-limit": "The key works, but its free quota is used up right now.",
      "byok-network": "Could not reach the service. Check the network.",
    };
    return { ok: false, error: messages[state] ?? "The test failed. Try again." };
  }
}
```

## Wire the app's AI call sites

Every function that called `glaze("fast")` directly changes to:

```typescript
const { provider, model } = await resolveModel();
try {
  const { object } = await generateObject({ model, /* schema, prompt as before */ });
} catch (error) {
  if (error instanceof GlazeAIError) return { ok: false, blocked: error.state };
  if (provider !== "glaze") return { ok: false, blocked: byokBlockedState(error) };
  throw error;
}
```

Keep (or add) the app's non-AI fallback for blocked results; with the mapping above
it now covers every engine. Extend the app's blocked-message map with the four
`byok-*` states, in the app's UI language, alongside Glaze's seven states from
`glaze-ai` (example: "byok-invalid-key": "The API key was rejected. Check it in
settings.").

## IPC handlers

```typescript
ipcMain.handle("ai:getSettings", async () => getAISettings());
ipcMain.handle("ai:updateSettings", async (_e, arg) => updateAISettings(arg ?? {}));
ipcMain.handle("ai:setKey", async (_e, arg) => setProviderKey(arg?.provider, arg?.key ?? ""));
ipcMain.handle("ai:testProvider", async (_e, arg) => testProvider(arg?.provider));
```

Validate `arg` with the app's usual guards (only accept known provider ids; an empty
key string clears the stored key). Add matching methods to the renderer's typed IPC
client.

## Settings UI

Add an "AI engine" FieldSet to the app's settings surface (dialog or settings
window), following the app's existing form patterns:

- `RadioGroup`/`RadioGroupItem` from `@glaze/core/components` with one option per
  engine: label + one-line honest cost hint ("No setup. Uses your Glaze credits." /
  "Free with your own Google key, about 250 AI calls per day.").
- When a BYOK engine is selected: a key status `Badge` ("Key stored" / "Missing
  key"), a button that opens the provider's key page via `openExternal`, a
  `type="password"` `Input` for pasting, a "Save key" button, and a "Test" button
  wired to `ai:testProvider`.
- For OpenRouter, an editable model field defaulting to `openrouter/free`.
- A short note when a key is missing: the app quietly falls back to Glaze AI.

If the app has a first-run onboarding flow, offer the engine choice there too (two
choice cards: Glaze AI vs the free option, with the guided key setup inline), and
keep OpenRouter in full settings only. Persist engine settings immediately, not on
wizard completion, so escaping the wizard keeps the choice.

## Verify (no AI calls)

- `npm run type-check` and `npm run build` pass.
- `grep -c "generativelanguage.googleapis.com" ../.glaze/build/main/index.js` and the
  same for `openrouter.ai/api/v1` both return at least 1 (providers really bundled).
- Launch, open settings, confirm the engine section renders; quit. Do not click Test
  and do not trigger AI features.
- Record the engine setup in the app's `.glaze_memory/PROJECT-CONTEXT.md`.
