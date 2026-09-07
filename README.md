# Nightix v30 — Full Fixes

This build is based on the v28 source with the v29 UI-width/performance fixes retained and the requested older fixes consolidated.

Included fixes:
- ChinaHat size setting.
- Target ESP Circle: 3D world-space texture, head-to-feet endless motion, visible from above/below, fixed world brightness, 3 circle variants, independent world-stud size setting, default size 4.
- NameTags: health moved before donation texture, larger text, shorter tag height.
- AttackAura: immediate target reacquisition, restores AutoRotate when no target, target-dead option.
- HeadRotate with 8 directions + straight.
- Nightix Icon function with Single/Double modes, two color pickers, speed, ready themes, UI-scale reset.
- Theme presets: Nursultan 1.21.11 (216,148,245 -> 123,131,243) and Nursultan 1.16.5 (207,156,211 -> 94,74,103).
- Theme changes apply immediately to active/inactive sections, menu icons, logo, watermark, and Settings color pickers.
- One-way infinite gradient animation; no ping-pong.
- Watermark order: icon | Release | UID, two gray separators, colored Release, white UID, opaque background, no watermark glow.
- Third-person menu camera no longer zooms a player who was already in third person; first-person still gets temporary menu distance.
- UI scale persists while reopening the menu.
