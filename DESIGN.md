---
name: NetChecker
description: Sequential reachability instrument on moreweb.ir type — hairline grid, chase cell, no neon.
colors:
  ink: "#030005"
  paper: "#D1D1D1"
  mute: "#8C8C8C"
  hairline: "#242428"
  ok: "#7EBA88"
  timeout: "#C4A35A"
  fail: "#C45C5C"
  live: "#F2F2F2"
  panel: "#0C0A10"
  wash-live: "rgba(255, 255, 255, 0.08)"
  wash-hot: "rgba(255, 255, 255, 0.13)"
typography:
  title:
    fontFamily: "Poppins, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.2
  body:
    fontFamily: "Poppins, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "Poppins, sans-serif"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "0.04px"
  mono:
    fontFamily: "Space Mono, ui-monospace, monospace"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
    fontFeature: "tnum"
rounded:
  none: "0px"
  sheet: "16px"
  pill: "999px"
spacing:
  cell: "3px 6px"
  sm: "8px"
  md: "12px"
  lg: "16px"
components:
  button-primary:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "8px 16px"
    height: "40px"
  cell:
    backgroundColor: "transparent"
    textColor: "{colors.paper}"
    typography: "{typography.mono}"
    rounded: "{rounded.none}"
    padding: "{spacing.cell}"
  cell-live:
    backgroundColor: "{colors.live}"
    textColor: "{colors.ink}"
    typography: "{typography.mono}"
    rounded: "{rounded.none}"
    padding: "{spacing.cell}"
  input-underline:
    backgroundColor: "transparent"
    textColor: "{colors.paper}"
    typography: "{typography.body}"
    rounded: "{rounded.none}"
    padding: "4px 0"
  toolbar-desktop:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    height: "32px"
  sheet:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.paper}"
    typography: "{typography.title}"
    rounded: "{rounded.sheet}"
    padding: "{spacing.lg}"
---

# Design System: NetChecker

## Overview

**Creative North Star: "The Chase-Light Instrument"**

NetChecker is a running step-row on moreweb.ir type: Poppins and Space Mono on near-black violet ink. The screen is one dense board of live probe truth. Chrome is native and thin; the grid is the product. A single cell is in motion — the chase — while every other cell holds last-known readout. There is no dashboard, no card stack, no glow.

The world is a bench instrument, not a consumer app and not cyberpunk. Paper is the interactive voice (buttons, focus, selected tracks). Status is written in Space Mono (`42ms`, `ok`, `to`, `fail`, `…`, `·`) and only then tinted. Android is a Material 3 one-screen with a 48dp app bar and a modal settings sheet. Windows and Linux keep native window chrome and add a 32px instrument toolbar (run, pin, copy, settings, NIC). Pinning shrinks the window and keeps it above other apps; the board is the same widget on every platform.

**Key Characteristics:**
- Ink ground `{colors.ink}` with hairline `{colors.hairline}` as the only structure
- Poppins for UI; Space Mono tabular figures for measurements and status words
- Chase cell only: live paper, 1px top stroke, 8% white wash (off when Reduce Motion)
- Status inks are muted sage / brass / dust — never neon, never glow
- One Apply pill; settings are sliders, switches, and underline fields

## Colors

A restrained dark instrument: one paper foreground, one hairline, three muted status inks, and a chase paper. Primary in the Material scheme is the paper, not a brand chroma.

### Primary
- **Instrument Paper** (`paper`): Body text, app-bar foreground, filled Apply, slider thumb and active track, focused underline, selected switch track. The only bright fill. Rarity on the board is the point; the grid itself stays ink.

### Secondary
- **Dim Mute** (`mute`): Captions, strip labels, idle readout, unselected switch thumb, cell sub-lines (hunt detail at 10px). Secondary in the scheme; never a fill for a live result.

### Neutral
- **Violet Ink** (`ink`): Scaffold, canvas, app bar, desktop toolbar, strip-label rail, system navigation bar. moreweb.ir ground, `rgb(3, 0, 5)`.
- **Hairline** (`hairline`): Every 1px grid stroke, dividers, input rest underline, inactive slider track, unselected switch track.
- **Raised Panel** (`panel`): Settings sheet, settings rail, snackbar, dropdown menus. One step off ink; not a card.
- **Chase Paper** (`live`): The checking cell’s type and top stroke. Near-white, still flat.

Status inks tint the mono readout only. They do not fill cells, glow, or replace the word.
- **Sage Ok** (`ok`): Successful hit (`{ms}ms` or `ok`).
- **Brass Timeout** (`timeout`): `to`.
- **Dust Fail** (`fail`): `fail` or the short error detail; also the scheme error color.
- **Washes:** `wash-hot` on desktop toolbar hover and slider overlay. The chase cell is inverted paper, not a wash.

**The No-Neon Rule.** No glow, no gradient type, no mesh, no chromatic fill behind a result. If it looks like a scanner HUD, it is wrong.

**The Chase-Light Rule.** Only the live cell inverts: `live` fill, `ink` type. Settled cells are last-known status in mono; idle is mute `·`.

## Typography

**Display Font:** Poppins (bundled 400 / 500 / 700; sans-serif fallback)
**Body Font:** Poppins
**Label/Mono Font:** Space Mono (400, tabular figures)

**Character:** A geometric UI face next to a fixed-pitch measurement face. Poppins carries chrome and host names; Space Mono carries the truth of the probe. The pairing is moreweb.ir, not a system UI stack.

### Hierarchy
- **Title** (Poppins 500, 14px / 13px compact, line-height 1.2): Settings headings, Android app-bar title. Toolbar title on desktop is Poppins 500 at 12px (11px when pinned).
- **Body** (Poppins 400, 13px / 12px compact, line-height 1.35): Settings copy, list titles. Cell host names use the 11px body-small cut in 400, jumping to 500 only while that cell is live.
- **Label** (Poppins 500, 11px, mute): Strip keys (`DNS`, `NET`, `HUNT`) and the `SITES` count line. 36px rail.
- **Mono** (Space Mono 400, 11px, `tnum`): Probe readout. Sub-detail in the same face at 10px mute. NIC dropdown uses this face.

Android app-bar actions and the Apply control use Poppins 500 at 13px. Display roles exist in the theme at 28px / 22px compact but do not appear on the shipped board.

**The Status-Is-Type Rule.** A cell without `·` / `…` / `{ms}ms` / `ok` / `to` / `fail` is unfinished. Color seconds the word; it never replaces it. Honor the system text scaler.

## Layout

The board is a column: DNS wrap strip, NET wrap strip (proto 48px + edge 72px / 64px compact), HUNT wrap strip, then a `SITES` caption and a flush grid of domain tiles. Strips are a 36px label rail, a 1px vertical rule, and wrapping cells. Site tiles use `SliverGridDelegateWithMaxCrossAxisExtent` — 108×48 (96×42 when pinned) with zero gutter — so thirty hosts stay on one phone screen. DNS/hunt cells are 52px wide (48px pinned).

Spacing on the board is tight: cell pad 3×6 (wide cells 4×8), strip label pad 8/6/4, `SITES` caption 6/8/2. Settings use 16px side inset, 12px field gaps, 20px before Apply, 32px bottom. Android app bar is 48dp (40 when the compact theme is on) with 12px title inset and 48dp icon actions. Desktop instrument toolbar is 32px (28px pinned); action hits are 36×32. Desktop default window 480×720; pinned compact 420×640. Settings: Android modal sheet at 88% height; desktop a 360px right rail.

**The Same-Board Rule.** Android and desktop share one `ProbeBoard`. Platform chrome changes; the grid, type, and chase language do not.

## Elevation & Depth

Flat. App bar elevation and scrolled-under elevation are 0. Depth is a 1px hairline, the single `panel` tone for overlays, and the 8% wash on the chase cell. No drop shadows. The desktop settings rail sits on a 60% black barrier (`#99000000`); that dimmer is overlay, not a cast shadow.

**The Flat-Instrument Rule.** Surfaces do not lift. If a control needs priority, change hairline or paper, not blur or offset shadow.

## Shapes

The board is orthogonal: square cells, 0 radius, 1px joins. The only round forms are the Apply pill (`StadiumBorder`) and the Android settings sheet’s 16px top corners. Inputs are underline, not boxed. Switches and sliders are the Material 3 dark-scheme controls, paper on hairline, not custom geometry.

**The Hairline-Grid Rule.** Structure is the 1px `{colors.hairline}` stroke on the right and bottom of every cell, plus row underlines. Do not fake the grid with cards, gaps, or radius.

## Components

### Buttons
- **Shape:** Pill (`rounded.pill`) for filled Apply. Android chrome actions are 48×48 icon hits, not pills.
- **Primary:** Paper fill, ink type, min 48×40, Poppins 500 13px. One per settings surface (`Apply`).
- **Hover / Focus:** Desktop chrome uses `wash-hot` on hover. Apply uses the theme overlay; focus follows paper, not a colored ring.
- **Ghost:** Paper type on ink; 48×48 minimum on Android.

### Cards / Containers
- **Corner Style:** None on the board (`rounded.none`). Settings sheet 16px top on Android; square 360px rail on desktop.
- **Background:** Ink for the instrument; `panel` for settings, snackbars, and menus.
- **Shadow Strategy:** None. See Elevation.
- **Border:** 1px hairline. Live cell adds a 1px `live` top stroke.
- **Internal Padding:** `{spacing.cell}` in the grid; `{spacing.lg}` in settings.

### Inputs / Fields
- **Style:** Dense, unfilled, underline hairline at rest.
- **Focus:** Underline turns paper.
- **Error / Disabled:** Scheme error is `fail`. Hunt and extra-hosts fields are multiline-capable; values stay paper on ink.
- **Slider:** Paper thumb and active track, hairline inactive, `wash-hot` overlay. Value printed in Space Mono (`1200ms`) on the right.
- **Switch:** Selected track paper / thumb ink; off track hairline / thumb mute.

### Navigation
- **Android:** Material 3 `AppBar` on ink, title `NetChecker  {n} ok  {n} down  {k}/{total}`, actions `pause`/`run`, `copy`, `set` as text. `SafeArea` body under a 1px divider; edge-to-edge with a transparent status bar and ink nav bar.
- **Desktop:** Native window chrome plus the 32px instrument toolbar: title, NIC dropdown in Space Mono when more than one interface exists, then `pause`/`run`, `pin`/`unpin`, `copy`, `set`. Pin toggles always-on-top and compact density.
- **Settings:** Not a second product. Android: modal bottom sheet, drag handle, `panel`, 88% height. Desktop: right-aligned 360px `panel` rail.

### Probe Cell (signature)
Two lines minimum: Poppins host (11px, ellipsis) and Space Mono readout. Optional third line for hunt/site detail at 10px mute. Long-press copies the probe line. Live state (unless Reduce Motion): inverted `live` fill with `ink` type, label weight 500. Checking readout is `…`; idle is mute `·`.

### Strip Row (signature)
44px ink rail, mute 11px Poppins key, 1px vertical rule, one horizontally scrolling step-row, 1px bottom hairline. Keys in the build: `DNS`, `NET`, `HUNT`. Site counts live in the top bar, not a caption.

## Do's and Don'ts

### Do:
- **Do** keep the live probe as the only chase cell; every other cell is last-known truth.
- **Do** set status in Space Mono with tabular figures (`42ms`, `ok`, `to`, `fail`, `…`, `·`) and tint with the status inks.
- **Do** build strips as wrap rows and sites as a max-extent hairline grid (108×48, 96×42 compact).
- **Do** use paper as the single interactive fill (Apply, focus underline, selected tracks).
- **Do** keep Android chrome at 48dp hits and the desktop instrument toolbar at 32px (28px pinned).
- **Do** drop the chase wash when Reduce Motion / animation off is set.

### Don't:
- **Don't** neon, glow, gradient type, decorative mesh, or chromatic cell fills.
- **Don't** wrap results in cards, gutters, or radius on the board.
- **Don't** use color as the only status channel.
- **Don't** add product menus, about chrome, or a second screen of features; settings stay sliders and a host list.
- **Don't** cast shadows or raise elevation to imply hierarchy.
- **Don't** fill text fields; underlines only.
