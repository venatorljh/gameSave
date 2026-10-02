@tool
extends Node2D

## Builds a small, deterministic outdoor combat-map prototype from the
## Calciumtrice outdoor atlas. The atlas source cells are kept on TileMapLayer
## nodes so the layout can be replaced with hand-painted cells later.

const CELL_SIZE := Vector2i(16, 16)
const MAP_WIDTH := 44
const MAP_HEIGHT := 28

const SOURCE_BEACH := 0
const SOURCE_FOREST := 1
const SOURCE_TREES := 2

const BEACH_TEXTURE: Texture2D = preload("res://assets/tilesets/calciumtrice-outdoor/beach_tileset_0.png")
const FOREST_TEXTURE: Texture2D = preload("res://assets/tilesets/calciumtrice-outdoor/forest_tileset_0.png")
const TREES_TEXTURE: Texture2D = preload("res://assets/tilesets/calciumtrice-outdoor/trees_23.png")

const GROUND_TILE := Vector2i(3, 3)
const PATH_TILE := Vector2i(3, 4)
const SHORE_TILE := Vector2i(3, 3)
const WATER_TILE := Vector2i(4, 4)


func _ready() -> void:
	_build_map()


func _build_map() -> void:
	var tile_set := _make_tile_set()
	var ground: TileMapLayer = $Ground
	var ground_details: TileMapLayer = $GroundDetails
	var trail: TileMapLayer = $Trail
	var shore: TileMapLayer = $Shore
	var water: TileMapLayer = $Water
	var trees: TileMapLayer = $Trees

	for layer: TileMapLayer in [ground, ground_details, trail, shore, water, trees]:
		layer.tile_set = tile_set
		layer.clear()

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			ground.set_cell(Vector2i(x, y), SOURCE_FOREST, GROUND_TILE)

	_paint_trail(trail)
	_paint_lake(shore, water)
	_paint_ground_details(ground_details, trail, shore, water)
	_place_trees(trees)

	# Keep generated cell data in the scene tree for useful inspection in-editor.
	trail.update_internals()
	shore.update_internals()
	water.update_internals()
	trees.update_internals()
	ground_details.update_internals()
	ground.update_internals()


func _make_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = CELL_SIZE
	tile_set.add_source(_make_regular_atlas(BEACH_TEXTURE), SOURCE_BEACH)
	tile_set.add_source(_make_regular_atlas(FOREST_TEXTURE), SOURCE_FOREST)
	tile_set.add_source(_make_tree_atlas(), SOURCE_TREES)
	return tile_set


func _make_regular_atlas(texture: Texture2D) -> TileSetAtlasSource:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = CELL_SIZE
	var columns := int(texture.get_width() / CELL_SIZE.x)
	var rows := int(texture.get_height() / CELL_SIZE.y)
	for y in range(rows):
		for x in range(columns):
			atlas.create_tile(Vector2i(x, y))
	return atlas


func _make_tree_atlas() -> TileSetAtlasSource:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TREES_TEXTURE
	atlas.texture_region_size = CELL_SIZE
	for origin: Vector2i in [
		Vector2i(0, 0), Vector2i(6, 0),
		Vector2i(0, 7), Vector2i(6, 7),
		Vector2i(0, 14), Vector2i(6, 14),
	]:
		atlas.create_tile(origin, Vector2i(6, 7))
	return atlas


func _paint_trail(layer: TileMapLayer) -> void:
	var route: Array[Vector2i] = [
		Vector2i(1, 24),
		Vector2i(7, 22),
		Vector2i(13, 19),
		Vector2i(19, 16),
		Vector2i(24, 16),
		Vector2i(29, 15),
	]

	for segment in range(route.size() - 1):
		var start: Vector2i = route[segment]
		var finish: Vector2i = route[segment + 1]
		var delta := finish - start
		var steps := maxi(absi(delta.x), absi(delta.y))
		for step in range(steps + 1):
			var progress := float(step) / float(steps)
			var center := Vector2i(
				roundi(lerpf(float(start.x), float(finish.x), progress)),
				roundi(lerpf(float(start.y), float(finish.y), progress))
			)
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if offset_x * offset_x + offset_y * offset_y > 2:
						continue
					var cell := center + Vector2i(offset_x, offset_y)
					if _inside_map(cell):
						layer.set_cell(cell, SOURCE_BEACH, PATH_TILE)

	# Widen the trail into a compact open clearing for an encounter or camp.
	for y in range(13, 20):
		for x in range(16, 24):
			var dx := float(x - 20) / 4.0
			var dy := float(y - 16) / 3.5
			if dx * dx + dy * dy <= 1.0:
				layer.set_cell(Vector2i(x, y), SOURCE_BEACH, PATH_TILE)


func _paint_lake(shore_layer: TileMapLayer, water_layer: TileMapLayer) -> void:
	var center := Vector2i(35, 12)
	var radius_x := 5.5
	var radius_y := 3.5
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var dx := float(x - center.x) / radius_x
			var dy := float(y - center.y) / radius_y
			var distance := dx * dx + dy * dy
			var cell := Vector2i(x, y)
			if distance <= 1.0:
				water_layer.set_cell(cell, SOURCE_FOREST, WATER_TILE)
			elif distance <= 1.42:
				shore_layer.set_cell(cell, SOURCE_BEACH, SHORE_TILE)


func _paint_ground_details(
	layer: TileMapLayer,
	trail_layer: TileMapLayer,
	shore_layer: TileMapLayer,
	water_layer: TileMapLayer
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 640041314
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell := Vector2i(x, y)
			if trail_layer.get_cell_source_id(cell) != -1:
				continue
			if shore_layer.get_cell_source_id(cell) != -1 or water_layer.get_cell_source_id(cell) != -1:
				continue
			if rng.randf() > 0.045:
				continue
			# The first atlas block contains small terrain color and texture variants.
			var atlas_cell := Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 7))
			layer.set_cell(cell, SOURCE_FOREST, atlas_cell)


func _place_trees(layer: TileMapLayer) -> void:
	var placements: Array[Array] = [
		[Vector2i(0, -2), Vector2i(0, 0)],
		[Vector2i(9, -2), Vector2i(6, 0)],
		[Vector2i(19, -2), Vector2i(0, 7)],
		[Vector2i(30, -2), Vector2i(6, 7)],
		[Vector2i(38, -2), Vector2i(0, 0)],
		[Vector2i(-3, 7), Vector2i(6, 7)],
		[Vector2i(-3, 17), Vector2i(0, 7)],
		[Vector2i(39, 7), Vector2i(0, 14)],
		[Vector2i(39, 17), Vector2i(6, 14)],
		[Vector2i(2, 22), Vector2i(6, 0)],
		[Vector2i(13, 22), Vector2i(0, 7)],
		[Vector2i(27, 22), Vector2i(6, 7)],
		[Vector2i(37, 22), Vector2i(0, 0)],
	]
	for placement: Array in placements:
		layer.set_cell(placement[0], SOURCE_TREES, placement[1])


func _inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT
