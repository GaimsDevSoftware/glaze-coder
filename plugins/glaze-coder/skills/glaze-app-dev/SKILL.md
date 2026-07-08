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
  (backend/frontend layout, window/tray/notification/global-shortcut recipes, bundling).
- `"$GLAZE_BASE/agent-resources/current/.claude/skills/"`, ~24 task skills:
  `glaze-component-patterns`, `glaze-frontend-rules`, `glaze-backend-rules`,
  `glaze-ipc-communication`, `glaze-data-storage`, `glaze-external-api`,
  `glaze-browser-window-recipes`, `glaze-theming`, `glaze-oauth`, etc.
- The app's own `"$SRC/CLAUDE.md"` and `"$SRC/.glaze_memory/PROJECT-CONTEXT.md"`
  (where `SRC="$GLAZE_BASE/apps/<app-folder>/.glaze-sources"`).

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
- **Forbidden imports** (runtime breakage): `backendNativeBridge`, `@glaze/core/backend/internal`, `GlazeIPCServer`, `GlazeLifecycle`, `registerNativeApiHandlers`, `wireProtocolHandlers`. Use the public `@glaze/core/backend` exports (`dialog`, `shell`, `clipboard`, `Notification`, `Menu`, `Tray`, ...). If an API isn't exported (e.g. `powerMonitor`), tell the user it's unavailable rather than reaching into internals.
- **Do not touch Glaze's managed `.npmrc`** (`~/Library/Application Support/app.glaze.macos.*/.npmrc`) or `NPM_CONFIG_USERCONFIG`, and don't set its keys (`min-release-age`, `before`, `registry`, `ignore-scripts`, ...) in a project `.npmrc`. If `npm install` fails because a version is too new, **pin an older version in `package.json`** instead of weakening policy.
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

## 6. Etiquette

You are editing code the user owns, with their own Claude subscription, this is
legitimate use, not a bypass of anything protected. Keep changes minimal and traceable
to the user's request, and prefer reading the local version-matched guide/skills over
guessing, since Glaze's SDK evolves.
