# Goofy Veil Girl roll image resources

Four directional dodge-roll sprite sheets for the existing Goofy Veil Girl player. `goofy_veil_girl_roll_frames.tres` cuts them into four non-looping six-frame animations and is used by `VisualSortOrigin/RollSprite2D` in `res://scenes/characters/goofy_veil_girl.tscn`.

| Direction | Image |
| --- | --- |
| Down | `goofy_veil_girl_roll_down_v1.png` |
| Right | `goofy_veil_girl_roll_right_v1.png` |
| Left | `goofy_veil_girl_roll_left_v1.png` |
| Up | `goofy_veil_girl_roll_up_v1.png` |

Each PNG is 1536 × 1024 RGBA, arranged as three columns and two rows of 512 × 512 frames. Read frames 1–3 across the top row, then 4–6 across the bottom row:

1. Crouch and load the roll.
2. Bend forward and tuck the head.
3. Dive onto the shoulder.
4. Inverted, compact tumble.
5. Plant a hand and rise to a knee.
6. Return to the standing directional pose.

The images were made with the built-in image generation tool. Prompt set: preserve the existing flower crown, pale blue long hair, large eyes where visible, white robe, low-saturation colors, and thick pixel outlines; create a grounded six-pose evasive roll toward each of the four facing directions; use a transparent background and no extra equipment or scenery. The matching directional walk sheets and the four-direction turnaround were used as visual references.

The current walk sheets use 543 × 724 frame regions, while these roll sheets use 512 × 512 cells. The player scene uses a roll scale multiplier of 1.35 and an image offset of `(0, -185)` to align the two sets. Adjust `Roll Image Scale Multiplier` and `Roll Image Offset` on the player root to tune their appearance.

Space starts the roll. Its movement, stamina cost, duration, invulnerability window, and attack/repeat-roll recovery time are configured on the player root. The animation speed follows the configured roll duration. See `docs/人物体力与翻滚配置说明.md` in the workspace for all properties and controls.
