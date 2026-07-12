![glaze-coder](banner.png)

# glaze-coder

Build, edit and run [Glaze](https://www.glaze.app) (by Raycast) Mac apps from
[Claude Code](https://claude.com/product/claude-code) for free. You point your own
Claude at the app's source and build it on your machine, so editing and building never
spend Glaze credits.

Glaze builds Mac apps with a built-in AI agent, and that agent is what costs credits.
But every Glaze app is a normal project on disk, and Glaze
[lets you edit the source yourself](https://manual.glaze.app/advanced/editing-code).
glaze-coder wires your Claude Code into that source and builds it locally with the Node
runtime Glaze already ships. Nothing goes back to Glaze's agent, so nothing costs credits.

![macOS](https://img.shields.io/badge/macOS-Tahoe%2B-black)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-required-black)
![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-black)
![License](https://img.shields.io/badge/license-MIT-green)

## What you can do

- Create a new Mac app from a one-line description and open it in Claude Code, ready to build.
- Describe the changes you want in plain language and let Claude Code write the code.
- Open the source in your own editor when you want to change something by hand.
- Run a live dev server with reload while you work.
- Build the finished app and launch it, all on your machine.
- Publish to the Glaze Store when you are happy with it.

Creating, editing and building cost nothing in Glaze credits. Only Glaze's own AI agent
does, and glaze-coder never calls it.

## What you get

- A skill (`glaze-app-dev`) that teaches Claude Code the Glaze project layout, the build
  and run steps, and the safety rules. It also reads the guide and skills that ship with
  your own Glaze install, so it stays in step with your version.
- A command (`/glaze-coder:glaze`) that lists your apps and starts building.
- A launcher (`glaze-dev`) for the terminal and Raycast, with short commands to create,
  edit, build, run and remove apps.

## Requirements

- macOS (Tahoe or newer) on Apple Silicon, with Glaze installed and at least one app.
- [Claude Code](https://claude.com/product/claude-code) installed, with `claude` on your PATH.

## Install

### Easiest: download the installer

Download **glaze-coder-installer.dmg** from the
[latest release](https://github.com/GaimsDevSoftware/glaze-coder/releases/latest) and open
it. Right-click "Install glaze-coder.command" and choose Open, then click Open again in the
warning. A Terminal window opens and asks which parts you want:

- The core `glaze-dev` command is always installed.
- Glaze skills for Claude Code (recommended).
- The Claude Code plugin `/glaze-coder:glaze` (recommended).
- Raycast commands (optional, only if you use Raycast).

Press Enter to accept the suggestion for each one. The warning appears only the first time,
because the installer is not signed with a paid Apple certificate. The DMG contains a READ
ME FIRST file with the same steps.

### One command

If you are comfortable with the terminal, paste this line and press Enter instead. It does
the same thing.

```bash
curl -fsSL https://raw.githubusercontent.com/GaimsDevSoftware/glaze-coder/main/install.sh | zsh
```

![Install from the terminal](install-terminal.gif)

Either way, that is all you need. If you would rather set things up by hand, see
[Other ways to install](#other-ways-to-install) below.

## Get started in three steps

1. Create an app and open Claude Code in it:

   ```bash
   glaze-dev start "Habit Tracker"
   ```

2. In Claude Code, describe what the app should do. For example: "Track daily habits with
   a checklist, and show a streak counter." Claude Code writes and edits the code for you.

3. Build it and open it:

   ```bash
   glaze-dev br "Habit Tracker"
   ```

Repeat step 2 and 3 as often as you like. When the app is ready, publish it to the Glaze
Store from Glaze itself.

## Commands

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

`<app>` matches on the folder name or the product name, so a partial name works.

## Other ways to install

### Claude Code plugin

The one-command installer does this for you when `claude` is on your PATH. To do it by
hand from inside Claude Code:

```
/plugin marketplace add GaimsDevSoftware/glaze-coder
/plugin install glaze-coder
```

![Install as a Claude Code plugin](install-plugin.gif)

This gives you the `glaze-app-dev` skill and the `/glaze-coder:glaze` command. It works
the same in the Claude Code terminal and in the desktop app.

### Raycast

Raycast can only add a script folder from its own settings, so this step needs one click.
Run:

```bash
glaze-dev raycast
```

That copies the folder path and opens Raycast. Then:

1. Raycast Settings, Extensions, Script Commands, Add Directories.
2. In the file picker press Cmd+Shift+G, paste the path, press Enter, then Open.

You now have three Raycast commands, none of which need a terminal:

- "Glaze: New App" builds a new app and opens it.
- "Glaze: Build & Run" builds an app and opens it.
- "Glaze: Edit App" asks where to open the edit session, then launches Claude Code there.
  A small window lists the terminals you have installed (Terminal, iTerm, Ghostty, kitty,
  Alacritty, WezTerm), plus Auto (your running or last-used terminal) and Claude Code
  (Desktop app) if Claude.app is installed. Pick one and it opens Claude Code on the app's
  source. To force a terminal from a script, set `GLAZE_TERMINAL=iterm|ghostty|kitty` and
  so on.

![Run from Raycast](install-raycast.gif)

## How it works

A Glaze app lives in `~/Library/Application Support/app.glaze.macos.main/apps/<app>/`.
Inside, `.glaze-sources/` holds the source you can edit: a React and Vite renderer, a Node
backend, and a `package.json`. `npm run build` compiles it with the `@glaze/core` SDK and
the Node runtime Glaze bundles, so no request goes to Glaze and no credits are spent. The
installed app in `/Applications/Glaze/<App>.app` finds the built code through a symlink,
which is how `glaze-dev new` can create a working app on its own.

## Good to know

- Apps made by `new` and `start` are ad-hoc signed for your own use.
- Publishing to the Glaze Store still needs a Glaze account, but publishing does not cost
  credits.
- Manual edits are not saved in Glaze's version history. Send one small prompt to Glaze's
  agent if you want a checkpoint there.
- You own your app and its code, so this is a supported way to work on your own project.

## FAQ

**What is glaze-coder?**
A Claude Code plugin, skill and Raycast launcher for building, editing and running Glaze
(Raycast) Mac apps with your own Claude, instead of spending Glaze credits.

**Can I really build Glaze apps without spending credits?**
Yes. Editing the source and running `npm run build` happen on your machine with the Node
runtime Glaze already bundles. Glaze's own AI agent is what spends credits, and glaze-coder
never calls it. Publishing to the Glaze Store needs a Glaze account but does not cost
credits.

**Do I need to know how to code?**
No. You describe the app to Claude Code in plain words and it writes the code. You can also
open the source and edit it yourself when you want to.

**Which Claude model should I use?**
Any model Claude Code offers will work. Newer models like Claude Opus tend to produce
better app code, but the plugin behaves the same whichever you pick.

**Does it work in both the Claude Code terminal and desktop app?**
Yes. The plugin and the `/glaze-coder:glaze` command work the same in both. The Raycast
"Edit App" command can open either a terminal or the Claude Code desktop app.

**What do I need installed?**
macOS (Tahoe or newer) on Apple Silicon, Glaze with at least one app, and Claude Code with
`claude` on your PATH.

**Is this allowed?**
Yes. You own your app and its code, and Glaze supports editing the source yourself.
glaze-coder just automates that.

## License

MIT
