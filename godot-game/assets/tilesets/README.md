# Additional tileset downloads

Downloaded into this Godot project from the source pages below. The image files keep their original filenames where possible.

## Redshrike forest

- Files: `redshrike-forest-dark/dark_forest.png` and `redshrike-forest-dark/light_forest_tileset_0.png`
- Author: Stephen Challener (Redshrike) and the Open Surge team
- License: CC BY 3.0; attribution and a link to the source page are required.
- Source: <https://opengameart.org/content/32x32-rpg-tiles-forest-and-some-interior-tiles>

Suggested attribution: “Forest tiles by Stephen Challener (Redshrike) and the Open Surge team, via OpenGameArt.org, CC BY 3.0.”

## Calciumtrice outdoor set

- Files: beach, forest, trees, water, and water animation frames in `calciumtrice-outdoor/`
- Author: Calciumtrice
- License: CC BY 4.0; attribution is required.
- Source: <https://opengameart.org/content/outdoor-tileset-0>
- The original readme is included as `calciumtrice-outdoor/outdoor_tileset_readme_0.txt`.

Suggested attribution: “Outdoor Tileset by Calciumtrice, OpenGameArt.org, CC BY 4.0.”

## Viking Fjord Village free demo

- Files: original zip and extracted demo in `viking-fjord-demo/`
- Source: <https://bubbabba.itch.io/viking-fjord-village>
- This is the free demo only: it includes the day palette, 20 props, 5 animations, and one character. The paid autumn, torchlit-night, and storm palettes are not included.
- The author permits use in free and commercial projects and recoloring; credit is optional. Do not redistribute the assets as a separate or repackaged asset pack. The included `README.txt` has the full terms.
- The page discloses AI-assisted graphics and text.

The current Puny Dungeon tileset uses a 16×16 grid. Viking Fjord is also 16×16; the OpenGameArt forest and outdoor sheets may use different cell sizes, so check each sheet before slicing it in Godot.

## Calciumtrice medieval town and interiors

- Files: `calciumtrice-medieval/medieval_tileset_exterior.png` and `calciumtrice-medieval/medieval_tileset_interior.png`
- Author: Calciumtrice
- License: CC BY 3.0; attribution is required.
- Source: <https://opengameart.org/content/medieval-tileset>
- The exterior sheet has stackable/combinable half-timbered building pieces; the interior sheet has shop, tavern, and blacksmith furnishings.

Suggested attribution: “Medieval Tileset by Calciumtrice, OpenGameArt.org, CC BY 3.0.”

## Calciumtrice dungeon rooms and props

- Files: full and simple sheets, `ceilings.png`, `eggs0.png`–`eggs2.png`, the original source ZIP, and its instructions under `calciumtrice-dungeon/`
- Author: Calciumtrice
- License: CC BY 3.0; attribution is required.
- Source: <https://opengameart.org/content/dungeon-tileset-1?page=1>
- The source notes 16×16 tiles and includes walls, ceilings, floors, doors/gates, furniture, containers, characters, monsters, and items. Full and simple sheets are both included so either ceiling treatment can be chosen.

Suggested attribution: “Dungeon Tileset by Calciumtrice, OpenGameArt.org, CC BY 3.0.”

## Calciumtrice spooky outdoor set

- File: `calciumtrice-spooky-outdoor/spooky_outdoor_tileset.png`
- Author: Calciumtrice
- License: CC BY 3.0; attribution is required.
- Source: <https://opengameart.org/content/outdoor-tileset>
- A small, deliberately dingy outdoor sheet with grass/path pieces, trees, miscellaneous props, and animated campfire frames.

Suggested attribution: “Outdoor Tileset by Calciumtrice, OpenGameArt.org, CC BY 3.0.”

## Duasun roguelike castle

- Files: `duasun-roguelike-castle/roguelike_castle_low_saturation.png` and `duasun-roguelike-castle/roguelike_castle_high_contrast.png`
- Author: Duasun
- License: CC0; attribution is not required.
- Source: <https://opengameart.org/content/castletileset>
- These 16×16 castle variants provide extra walls and architectural pieces. Their blue stone palette is more saturated than the Calciumtrice sheets, so treat them as an optional supplement or recolor them to match.

## Bart castle gate and walls

- File: `bart-castle/castle_16x16.png`
- Author: bart
- License used here: CC BY 3.0; attribution is required. The source page also offers other licenses.
- Source: <https://opengameart.org/content/16x16-castle-tiles>
- This top-down 16×16 sheet includes a stone arch/gate and adjoining walls. The map TileSet offers both individual cells and one 4×4-cell gate block for quick placement.

Suggested attribution: “16x16 Castle Tiles by bart, OpenGameArt.org, CC BY 3.0.”

## Erdut castle stone

- File: `erdut-castle/castle_tileset.png`
- Author: Erdut Games
- License: CC BY 3.0; attribution is required.
- Source: <https://opengameart.org/content/castle-tileset>
- A small castle sheet inspired by Calciumtrice's dungeon set. It contributes muted stone pieces; it is less complete than the other atlases.

Suggested attribution: “Castle Tileset by Erdut Games, OpenGameArt.org, CC BY 3.0.”

## Generated grassland expansion draft

- File: `generated-grassland/grassland_expansion_generated.png`
- This is an original generated draft made for this project, with grass variants, dirt paths, reeds, shrubs, rocks, stumps, logs, and bare trees.
- It is a 1024×1536 concept sheet with a soft painted background; it is not yet a clean transparent 16×16 atlas. Use it as a visual resource/reference and check its pixels and background before slicing it for a TileSet.

## Map painting scene

- Scene: `res://scenes/maps/new_map.tscn`
- Main TileSet: `res://assets/tilesets/new_map_paint_tileset.tres`. It copies the existing Calciumtrice outdoor TileSet, including its tree and water atlas setup, then adds the medieval exterior/interior, spooky outdoor, both dungeon sheets, Bart castle, Erdut castle, and the low-saturation/high-contrast Duasun castle variants as 16×16 atlas sources. A separate Bart source offers the complete gate as one 4×4-cell tile. Transparent cells and the dungeon sheets' text-heading rows are omitted from the regular selectable tiles.
- Grassland draft TileSet: `res://assets/tilesets/generated-grassland/grassland_draft_tileset.tres`. It offers 64 px pieces and 128 px blocks from the original generated image. The `GeneratedGrasslandDraft` layer is scaled to 0.25, so one 64 px source cell occupies the same 16 px map grid as the other layers. Its soft background and irregular sprites can show seams when painted.
- Layers, back to front: `Ground`, `Water`, `TerrainDetails`, `GeneratedGrasslandDraft`, `Floors`, `WallsAndBuildings`, `Props`, `house`, `Overhead`. The `house` layer uses the main TileSet. The scene contains manually painted cells and should be preserved when rebuilding TileSets.
- The dungeon archive's `ceilings.png` and `eggs*.png` are usage examples rather than clean atlases; the source archive also duplicates the two main dungeon sheets. They remain in the project but are not repeated in the paint palette.
- To rebuild the TileSets after adding or changing images, open the project in Godot to import the PNGs, then run `res://tools/build_new_map_tilesets.gd` with `godot --headless --path <project> --script`. The script preserves an existing `new_map.tscn` so it cannot erase painted cells.

## Compatibility note

These are image assets only; no scenes or TileMap layouts were changed. The sheets are not all the same size or palette. Check each image's grid and spacing before slicing or combining it in Godot. The downloaded source files and licenses are kept with their respective packs.

## Import note

For crisp pixel art, set Godot's default texture filter to Nearest. The Viking demo page documents a 16×16 TileSet region size.
