![glaze-coder](banner.png)

# glaze-coder

Build [Glaze](https://www.glaze.app) (by Raycast) desktop apps from Claude Code, using
your own Claude subscription instead of Glaze's paid credits.

Glaze builds Mac apps with a built-in AI agent, and that agent is what spends Glaze
credits. Every Glaze app is a normal project on disk, and Glaze
[supports editing the source yourself](https://manual.glaze.app/advanced/editing-code).
glaze-coder points your own Claude Code at that source and builds it locally with the
Node runtime Glaze already ships. Editing and building cost you nothing in Glaze credits.

![macOS](https://img.shields.io/badge/macOS-Tahoe%2B-black)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-required-black)
![License](https://img.shields.io/badge/license-MIT-green)

## What you get

- A **skill** (`glaze-app-dev`) that gives Claude Code the Glaze project layout, the safety
  rules, and the local build and run loop. It also reads the guide and skills that ship
  with your own Glaze install, so it stays current with your version.
- A **command** (`/glaze-coder:glaze`) that lists your apps and starts building.
- A **launcher** (`glaze-dev`) for the terminal and Raycast, with commands to create,
  edit, build, run and remove apps.

## Requirements

- macOS (Tahoe or newer) on Apple Silicon, with Glaze installed and at least one app.
- [Claude Code](https://claude.com/product/claude-code) installed (`claude` on your PATH).

## Install

Pick whichever fits how you work. All three end up using the same free build loop.

### 1. Terminal

Clone the repo and run the installer. It links `glaze-dev` onto your PATH and links
Glaze's own skills into `~/.claude`.

```bash
git clone https://github.com/GaimsDevSoftware/glaze-coder
cd glaze-coder
./install.sh
```

![Install from the terminal](install-terminal.gif)

Then start a new app and jump straight into Claude Code:

```bash
glaze-dev start "Habit Tracker"
```

### 2. Claude Code plugin

Add the marketplace and install the plugin from inside Claude Code. This gives you the
`glaze-app-dev` skill and the `/glaze-coder:glaze` command in every session.

```
/plugin marketplace add GaimsDevSoftware/glaze-coder
/plugin install glaze-coder
```

![Install as a Claude Code plugin](install-plugin.gif)

Works the same whether you run Claude Code in a terminal or in the desktop app. They
share the same config and plugin system.

### 3. Raycast

In Raycast, open Settings, go to Extensions, then Script Commands, and add the folder
`glaze-coder/plugins/glaze-coder/scripts/raycast`. You get commands like "Glaze: New App",
"Glaze: Edit App" and "Glaze: Build & Run".

![Run from Raycast](install-raycast.gif)

## Usage

```
glaze-dev start "My App"     Create a new app and open Claude Code in it
glaze-dev new   "My App"     Create a new app (no editor)
glaze-dev list               List your Glaze apps
glaze-dev code  <app>        Open Claude Code in an app's source
glaze-dev dev   <app>        Start the dev server (live reload)
glaze-dev build <app>        Build the app locally
glaze-dev run   <app>        Open the built app
glaze-dev br    <app>        Build then run
glaze-dev rm    <app>        Remove an app (bundle, source, profile)
```

`<app>` matches on the folder name or product name, so partial names work.

## How it works

A Glaze app lives in `~/Library/Application Support/app.glaze.macos.main/apps/<app>/`.
Inside, `.glaze-sources/` holds the editable source: a React and Vite renderer, a Node
backend, and a `package.json`. `npm run build` compiles it with the `@glaze/core` SDK and
the Node runtime that Glaze bundles, so no network call to Glaze happens and no credits
are used. The installed launcher in `/Applications/Glaze/<App>.app` finds the built code
through a symlink, which is how `glaze-dev new` can create a working app on its own.

## Notes

- Apps created by `new` and `start` are ad-hoc signed for your own use.
- Publishing to the public Glaze Store still needs a Glaze account, but publishing does
  not cost credits.
- Manual edits are not saved as entries in Glaze's version history. Make one small prompt
  to Glaze's agent if you want a checkpoint.
- You own your app and its code, so this is supported use of your own project.

## License

MIT
