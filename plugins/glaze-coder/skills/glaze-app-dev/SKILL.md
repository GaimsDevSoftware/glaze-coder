---
name: glaze-app-dev
description: Build, edit, run, and debug Glaze (Raycast) desktop apps directly from Claude Code, for free, using your own Claude subscription instead of Glaze's paid credits. Use whenever the user wants to create, modify, style, fix, or add features to a Glaze app, mentions Glaze, a Glaze app, or an app under Glaze's apps folder.
---

# Developing Glaze apps from Claude Code (credit-free)

Glaze (by Raycast) builds macOS desktop apps with an AI agent. That built-in agent
is what costs **Glaze credits**. But every Glaze app is an ordinary **Claude Code
project on disk**, you own the code (Glaze states this explicitly). So you can edit,
build and run it with your own Claude Code and local tooling and spend **zero Glaze
credits**. Building/compiling is fully local and free.

This skill teaches you to do exactly that safely.

## 0. Locate Glaze, its apps, and its bundled Node

Run this once per task to set up the environment (works on any Mac):

```bash
# Find Glaze's data dir (handles profile-name variants)
GLAZE_BASE="$(for d in "$HOME/Library/Application Support/"app.glaze.macos.*; do [ -d "$d/apps" ] && echo "$d" && break; done)"
echo "BASE=$GLAZE_BASE"
ls "$GLAZE_BASE/apps"                 # each subfolder is one app

# Glaze bundles Node >= 24, REQUIRED for builds (system node is often too old)
NODE_BIN="$(ls -d "$GLAZE_BASE"/node/runtime/*/bin 2>/dev/null | head -1)"
export PATH="$NODE_BIN:$PATH"
node -v                                # should print v24.x
# Match Glaze's npm policy without editing its config:
[ -f "$GLAZE_BASE/.npmrc" ] && export NPM_CONFIG_USERCONFIG="$GLAZE_BASE/.npmrc"
```

An app lives at `"$GLAZE_BASE/apps/<app-folder>/"` and contains:

```
<app-folder>/
├── .glaze-sources/      ← EDIT HERE (the real source)
├── .glaze/              ← build output, NEVER touch
├── .claude/             ← project Claude config (settings.local.json)
└── <ProductName>.app    ← symlink to the installed app in /Applications/Glaze/
```

## 1. Read the version-matched guidance first (don't rely only on this skill)

Each Glaze install ships its own always-current guide + skills. Read them before coding:

- `"$GLAZE_BASE/agent-resources/current/GLAZE-APP-GUIDE.md"`, full structure guide
  (backend/frontend layout, window/tray/notification/global-shortcut recipes, bundling,
  publishing, and an "SDK API Reference" section that tells you how to look up exact
  `@glaze/core` exports and `window.glazeAPI` symbols instead of enumerating `sdk/current`).
- `"$GLAZE_BASE/agent-resources/current/.claude/skills/"`, the task skills that ship with
  the user's Glaze install (the set grows with each SDK release, so list the folder rather
  than trusting a fixed count). Core ones: `glaze-component-patterns`, `glaze-frontend-rules`,
  `glaze-backend-rules`, `glaze-ipc-communication`, `glaze-data-storage`, `glaze-external-api`,
  `glaze-browser-window-recipes`, `glaze-theming`, `glaze-oauth`. Newer ones you should know
  exist:
  - `glaze-ai`: built-in AI via the user's Glaze account (see "Newer SDK capabilities" below).
  - `glaze-claude-cli`: integrate the user's local Claude Code CLI via `claude -p` / `--print`.
    Not the default AI path; only for users known to have Claude Code installed.
  - `glaze-mcp-server`: expose an app's data/actions as an MCP server (standalone stdio by
    default, in-app HTTP for live control) so the app is usable from Claude Code, Codex, etc.
  - `glaze-native-images`: native app icons, file icons, and Quick Look thumbnails via
    `getFileIconUrl()` / `getFileThumbnailUrl()` from `@glaze/core/utils`.
- The app's own `"$SRC/CLAUDE.md"` and `"$SRC/.glaze_memory/PROJECT-CONTEXT.md"`
  (where `SRC="$GLAZE_BASE/apps/<app-folder>/.glaze-sources"`).

### Newer SDK capabilities (read the matching skill before using)

- **AI**: apps declare `glaze.capabilities.ai` in `package.json` (grades + purpose + mode;
  publish rejects apps that call AI without it), call `generateText` from the backend or the
  `useGlazeAI` hook in the renderer, and pick a grade (`"fast"`/`"smart"`/`"powerful"`), never
  a raw model id. Glaze owns consent/credits/blocked-state UI. Do not trigger AI calls just to
  verify a build. Details: `glaze-ai`.
  **Default for apps built with this plugin: give the end user an AI engine choice.** Whenever
  you add an AI feature, also implement the engine picker from this plugin's `glaze-byok-ai`
  skill (Glaze AI as default + the user's own free Gemini key, optionally OpenRouter), so users
  decide whether using the app costs them anything. Skip it only if the user building the app
  asks for Glaze-only AI, or the app targets Claude Code users (`glaze-claude-cli`).
- **Local Claude Code CLI**: an app can call the user's own Claude Code subscription via
  `claude -p`. Backend only, no credential collection. Details: `glaze-claude-cli`.
- **App as MCP server**: give an app MCP tools so outside agents can read/write its data.
  Details: `glaze-mcp-server`.
- **Native images**: display-density-aware icon/thumbnail URLs for the renderer; never spawn
  JXA/`sips` or push base64 icons over IPC. Details: `glaze-native-images`.

Read the matching skill BEFORE writing code that touches: UI components, IPC handlers,
data storage, external APIs, native permissions, windows/tray, CLI tools, or perf-sensitive code.

## 2. Architecture (quick model)

Frontend (React 19 + Vite + TanStack Router/Query + Tailwind v4, in `.glaze-sources/renderer/`)
renders in a macOS WebView and talks over a JSON-RPC IPC bridge to the Backend
(Node.js, in `.glaze-sources/main/`, which calls Swift host APIs). The SDK `@glaze/core`
mirrors much of Electron's API surface, use Electron as a *starting point* but verify each
API is actually exported here. Renderer calls the backend via `window.glazeAPI`
(exposed through `renderer/preload.ts`); only `preload.ts` may import `ipcRenderer`.

## 3. Hard constraints (violating these breaks the app)

<critical>
- Edit **only** inside `.glaze-sources/`. **Never** edit/create files in `.glaze/` (build output), change `glaze.config.ts` instead.
- **Never** modify `@glaze/core` (the SDK) and never `npm install` it or the `glaze` CLI, they resolve via tsconfig paths + the bundled SDK at `sdk/current/@glaze/core`.
- **Forbidden imports** (runtime breakage): `backendNativeBridge`, `@glaze/core/backend/internal`, `GlazeIPCServer`, `GlazeLifecycle`, `registerNativeApiHandlers`, `wireProtocolHandlers`. Use the public `@glaze/core/backend` exports (`dialog`, `shell`, `clipboard`, `systemPreferences`, `globalShortcut`, `nativeTheme`, `screen`, `powerMonitor`, `powerSaveBlocker`, `safeStorage`, `Notification`, `Menu`, `Tray`, ...). If a feature has no public API in `@glaze/core/backend`, it is not implemented yet: tell the user it's unavailable rather than reaching into internals.
- **Do not touch Glaze's managed `.npmrc`** (`~/Library/Application Support/app.glaze.macos.*/.npmrc`) or `NPM_CONFIG_USERCONFIG`, and don't set its keys (`min-release-age`, `allow-git`, `registry`, `ignore-scripts`, ...) in a project `.npmrc`. If `npm install` fails because a version is too new, **pin an older version in `package.json`** instead of weakening policy.
- **No CSS/WebKit blur as a window background** (`backdrop-filter`, `-webkit-backdrop-filter`, Tailwind `backdrop-blur-*`). For frosted/glass windows use native `BrowserWindow` vibrancy with `frame: true` and hide traffic lights via `setWindowButtonVisibility(false)`. Use `frame: false` only for true custom-shaped transparent overlays.
- Styling = Tailwind v4 utilities + the design system (semantic colors, `Text` variants, `rounded-*` roles), don't hand-roll CSS files or use raw Tailwind color palette. See `glaze-component-patterns`.
- Surgical edits only; never ship mock/placeholder data.
</critical>

## 4. The free build / test loop

From `.glaze-sources/` (with the bundled Node on PATH from step 0):

```bash
cd "$GLAZE_BASE/apps/<app-folder>/.glaze-sources"
npm install --include=dev     # only if you added deps (NODE_ENV=production prunes devDeps otherwise)
npm run type-check            # fast correctness check
npm run build                 # local, free, builds backend + renderer + manifest
open ../*.app                 # launch the installed app to verify
# For live iteration instead of rebuild-each-time:
npm run dev                   # backend + renderer dev servers (Ctrl-C to stop)
```

Never run `glaze build` as a raw binary, always go through `npm run build`
(it's `node glaze.ts build`, which resolves the CLI from the local SDK). This uses
**your** machine only, no network call to Glaze, no credits.

## 5. Making a brand-new app

The `glaze-dev new "<Name>"` and `glaze-dev start "<Name>"` commands create a new app
with zero Glaze credits: they clone an existing app you own as a template, assign a new
id, build locally, and produce a signed launcher in `/Applications/Glaze/`. `start` also
opens Claude Code in the new source folder so you can build it out right away.

To do it by hand: copy an app folder under `apps/`, change `name`, `productName`, `id`,
and `description` in `.glaze-sources/package.json`, run `npm run build`, then copy the
template's `/Applications/Glaze/<App>.app`, re-point its `Contents/Resources/glaze-runtime`
symlink at the new app's `.glaze`, and ad-hoc sign it. New apps are ad-hoc signed for
your own use; publishing to the Glaze Store is a separate step in Glaze and does not cost
credits. Confirm with the user before duplicating.

When publishing matters: only `.glaze/build/` is zipped and shipped, `node_modules/` is
not. The app must run from `build/main/index.js` alone. For native `.node` addons or
packages that read files from their own directory at runtime, use `copyNativeBindings` /
`externalizePackage` from `@glaze/core/build` in `glaze.config.ts` (see the guide's
"Bundling & Publishing" section). Never patch `.glaze/` by hand; fix the build config.
Apps that call AI must declare `glaze.capabilities.ai` in `package.json` or publish rejects them.

## 6. Etiquette

You are editing code the user owns, with their own Claude subscription, this is
legitimate use, not a bypass of anything protected. Keep changes minimal and traceable
to the user's request, and prefer reading the local version-matched guide/skills over
guessing, since Glaze's SDK evolves.
