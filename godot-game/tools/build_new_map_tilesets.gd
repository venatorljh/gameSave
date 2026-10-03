extends SceneTree

## Run with Godot --headless --path <project> --script after the PNGs are imported.
## The scene is created only once, so later runs preserve hand-painted cells.
## The existing outdoor TileSet is copied so its tree and water atlas setup stays intact.

const BASE_TILE_SET := "res://assets/tilesets/calciumtrice-outdoor/calciumtrice_outdoor_tileset.tres"
const PAINT_TILE_SET := "res://assets/tilesets/new_map_paint_tileset.tres"
const GRASSLAND_TILE_SET := "res://assets/tilesets/generated-grassland/grassland_draft_tileset.tres"
const MAP_SCENE := "res://scenes/maps/new_map.tscn"
const GRASSLAND_IMAGE := "res://assets/tilesets/generated-grassland/grassland_expansion_generated.png"
const CELL_SIZE := Vector2i(16, 16)
const DRAFT_CELL_SIZE := Vector2i(64, 64)

# The dungeon sheets contain text headings and a license footer. These rows are
# kept out of the paint palette; the source PNG files are left unchanged.
const DUNGEON_SIMPLE_TEXT_ROWS := [0, 3, 7, 11, 15, 18, 20, 22, 25, 28, 30, 31]
const DUNGEON_FULL_TEXT_ROWS := [0, 3, 6, 10, 14, 18, 21, 23, 25, 28, 31, 33, 34]

const ADDITIONAL_SHEETS := [
	{
		"path": "res://assets/tilesets/calciumtrice-medieval/medieval_tileset_exterior.png",
		"name": "Medieval Exterior",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/calciumtrice-medieval/medieval_tileset_interior.png",
		"name": "Medieval Interior",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/calciumtrice-spooky-outdoor/spooky_outdoor_tileset.png",
		"name": "Spooky Outdoor",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/calciumtrice-dungeon/dungeon_tileset_calciumtrice_simple.png",
		"name": "Dungeon Simple",
		"skip_rows": DUNGEON_SIMPLE_TEXT_ROWS,
	},
	{
		"path": "res://assets/tilesets/calciumtrice-dungeon/dungeon_tileset_calciumtrice.png",
		"name": "Dungeon Full",
		"skip_rows": DUNGEON_FULL_TEXT_ROWS,
	},
	{
		"path": "res://assets/tilesets/bart-castle/castle_16x16.png",
		"name": "Castle Gate and Walls (Bart)",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/erdut-castle/castle_tileset.png",
		"name": "Castle Stone (Erdut)",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/duasun-roguelike-castle/roguelike_castle_low_saturation.png",
		"name": "Castle Low Saturation (Duasun)",
		"skip_rows": [],
	},
	{
		"path": "res://assets/tilesets/duasun-roguelike-castle/roguelike_castle_high_contrast.png",
		"name": "Castle High Contrast (Duasun)",
		"skip_rows": [],
	},
]


func _initialize() -> void:
	var result := _build()
	quit(result)


func _build() -> int:
	var original := load(BASE_TILE_SET) as TileSet
	if original == null:
		push_error("Could not load outdoor TileSet: " + BASE_TILE_SET)
		return 1

	var paint_tiles := original.duplicate(true) as TileSet
	paint_tiles.resource_name = "New Map Painting Tiles"
	for sheet: Dictionary in ADDITIONAL_SHEETS:
		if not _add_regular_sheet(paint_tiles, sheet):
			return 1
	if not _add_castle_gate_macro(paint_tiles):
		return 1
	if ResourceSaver.save(paint_tiles, PAINT_TILE_SET) != OK:
		push_error("Could not save " + PAINT_TILE_SET)
		return 1

	var grassland_tiles := _build_grassland_tiles()
	if grassland_tiles == null:
		return 1
	if ResourceSaver.save(grassland_tiles, GRASSLAND_TILE_SET) != OK:
		push_error("Could not save " + GRASSLAND_TILE_SET)
		return 1

	if not FileAccess.file_exists(MAP_SCENE):
		if not _build_scene():
			return 1
		print("Built empty map scene: " + MAP_SCENE)
	else:
		print("Preserved existing map scene: " + MAP_SCENE)
	return 0


func _add_regular_sheet(tile_set: TileSet, sheet: Dictionary) -> bool:
	var path: String = sheet["path"]
	var texture := load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if texture == null or image == null:
		push_error("Could not load image: " + path)
		return false

	var atlas := TileSetAtlasSource.new()
	atlas.resource_name = sheet["name"]
	atlas.texture = texture
	atlas.texture_region_size = CELL_SIZE
	var columns := image.get_width() / CELL_SIZE.x
	var rows := image.get_height() / CELL_SIZE.y
	var created := 0
	for y in range(rows):
		if y in sheet["skip_rows"]:
			continue
		for x in range(columns):
			var region := image.get_region(Rect2i(x * CELL_SIZE.x, y * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y))
			if region.get_used_rect().has_area():
				atlas.create_tile(Vector2i(x, y))
				created += 1
	var source_id := tile_set.add_source(atlas)
	print("Added source %d (%s): %d tiles" % [source_id, sheet["name"], created])
	return true


func _add_castle_gate_macro(tile_set: TileSet) -> bool:
	var path := "res://assets/tilesets/bart-castle/castle_16x16.png"
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Could not load castle gate image: " + path)
		return false
	var atlas := TileSetAtlasSource.new()
	atlas.resource_name = "Castle Gate Complete (Bart)"
	atlas.texture = texture
	atlas.texture_region_size = CELL_SIZE
	# The middle four columns form the stone arch and adjoining wall section.
	atlas.create_tile(Vector2i(3, 0), Vector2i(4, 4))
	var source_id := tile_set.add_source(atlas)
	print("Added source %d (complete castle gate)" % source_id)
	return true


func _build_grassland_tiles() -> TileSet:
	var texture := load(GRASSLAND_IMAGE) as Texture2D
	if texture == null:
		push_error("Could not load generated grassland image: " + GRASSLAND_IMAGE)
		return null
	var result := TileSet.new()
	result.resource_name = "Generated Grassland Draft"
	result.tile_size = DRAFT_CELL_SIZE
	var columns := texture.get_width() / DRAFT_CELL_SIZE.x
	var rows := texture.get_height() / DRAFT_CELL_SIZE.y

	# Single cells and 2x2 blocks make the irregular draft image selectable
	# without editing the original artwork. The layer is scaled to a 16 px grid.
	var singles := TileSetAtlasSource.new()
	singles.resource_name = "Grassland Draft 64 px Pieces"
	singles.texture = texture
	singles.texture_region_size = DRAFT_CELL_SIZE
	for y in range(rows):
		for x in range(columns):
			singles.create_tile(Vector2i(x, y))
	result.add_source(singles)

	var blocks := TileSetAtlasSource.new()
	blocks.resource_name = "Grassland Draft 128 px Blocks"
	blocks.texture = texture
	blocks.texture_region_size = DRAFT_CELL_SIZE
	for y in range(0, rows, 2):
		for x in range(0, columns, 2):
			blocks.create_tile(Vector2i(x, y), Vector2i(2, 2))
	result.add_source(blocks)
	print("Added generated grassland: %d small pieces and %d blocks" % [columns * rows, columns * rows / 4])
	return result


func _build_scene() -> bool:
	var paint_tiles := load(PAINT_TILE_SET) as TileSet
	var grassland_tiles := load(GRASSLAND_TILE_SET) as TileSet
	if paint_tiles == null or grassland_tiles == null:
		push_error("Could not reload the new TileSet resources")
		return false

	var root := Node2D.new()
	root.name = "NewMap"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add_layer(root, "Ground", -30, paint_tiles)
	_add_layer(root, "Water", -25, paint_tiles)
	_add_layer(root, "TerrainDetails", -20, paint_tiles)
	var draft_layer := _add_layer(root, "GeneratedGrasslandDraft", -15, grassland_tiles)
	draft_layer.scale = Vector2(0.25, 0.25)
	_add_layer(root, "Floors", -10, paint_tiles)
	_add_layer(root, "WallsAndBuildings", 0, paint_tiles)
	_add_layer(root, "Props", 10, paint_tiles)
	_add_layer(root, "Overhead", 20, paint_tiles)

	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Could not pack new map scene")
		root.free()
		return false
	var result := ResourceSaver.save(packed, MAP_SCENE)
	root.free()
	if result != OK:
		push_error("Could not save " + MAP_SCENE)
		return false
	return true


func _add_layer(root: Node2D, layer_name: String, draw_order: int, tiles: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = draw_order
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.tile_set = tiles
	root.add_child(layer)
	layer.owner = root
	return layer
