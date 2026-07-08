---
name: glaze
description: Develop a Glaze (Raycast) desktop app from Claude Code for free, list apps, then edit/build/run without spending Glaze credits.
---

Use the `glaze-app-dev` skill to help the user develop a Glaze app **for free** (with
their own Claude subscription, not Glaze's paid agent).

Argument (optional): `$ARGUMENTS` = the app the user wants to work on, and/or the change
they want to make.

Steps:
1. Detect the Glaze install and set the bundled Node on PATH (see the skill, step 0).
2. If no app was named, run the equivalent of `ls "$GLAZE_BASE/apps"` and read each
   app's `.glaze-sources/package.json` to list apps by product name, then ask which one.
3. Read the version-matched guidance for that app before coding: the app's
   `.glaze-sources/CLAUDE.md`, `.glaze_memory/PROJECT-CONTEXT.md`, the relevant skill in
   `"$GLAZE_BASE/agent-resources/current/.claude/skills/"`, and
   `GLAZE-APP-GUIDE.md` as needed.
4. Make surgical edits **only** inside `.glaze-sources/`, honoring every constraint in
   the skill (never touch `.glaze/`, `@glaze/core`, or the managed `.npmrc`; no CSS blur
   backgrounds; forbidden imports).
5. Validate with `npm run type-check`, then `npm run build`, then `open ../*.app`
   (or `npm run dev` for live iteration), all local, all free.
6. Tell the user manual edits aren't captured in Glaze's version history; if they want a
   checkpoint, they can make one small prompt to Glaze's agent afterward.
