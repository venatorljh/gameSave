@tool
extends TileMapLayer

## Only the per-cell drawing copy changes; the painted cells and shared TileSet stay intact.
@export var depth_layout: MapDepthLayout:
	set(value):
		_disconnect_layout()
		depth_layout = value
		_connect_layout()
		_refresh_depth_layout()
@export var unmatched_tiles_are_ground := false:
	set(value):
		unmatched_tiles_are_ground = value
		_refresh_depth_layout()
@export_range(-100, -1, 1) var ground_z := -5:
	set(value):
		ground_z = value
		_refresh_depth_layout()

var _connected_regions: Array[MapDepthRegion] = []


func _ready() -> void:
	_connect_layout()
	_refresh_depth_layout()


func _use_tile_data_runtime_update(_coords: Vector2i) -> bool:
	return depth_layout != null


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	# source/atlas identifiers remain unchanged. TileData itself is an engine-owned copy.
	var depth := _resolve_depth(coords)
	tile_data.y_sort_origin = depth.x - roundi(map_to_local(coords).y) - y_sort_origin
	tile_data.z_index = depth.y


func _resolve_depth(coords: Vector2i) -> Vector2i:
	var tile_source := get_cell_source_id(coords)
	var atlas := get_cell_atlas_coords(coords)
	var region := depth_layout.find_region(coords, name, tile_source, atlas)
	if region != null:
		return Vector2i(region.sort_y, region.draw_z)
	if unmatched_tiles_are_ground or tile_source == 0 or tile_source == 3:
		return Vector2i(roundi(map_to_local(coords).y), ground_z)
	# Newly painted small props use the bottom of their cell until given a region.
	return Vector2i(roundi(map_to_local(coords).y + tile_set.tile_size.y * 0.5), 0)


func _connect_layout() -> void:
	if depth_layout == null:
		return
	if not depth_layout.changed.is_connected(_on_layout_changed):
		depth_layout.changed.connect(_on_layout_changed)
	for region in depth_layout.regions:
		if region != null and not _connected_regions.has(region):
			if not region.changed.is_connected(_refresh_depth_layout):
				region.changed.connect(_refresh_depth_layout)
			_connected_regions.append(region)


func _disconnect_layout() -> void:
	if depth_layout != null and depth_layout.changed.is_connected(_on_layout_changed):
		depth_layout.changed.disconnect(_on_layout_changed)
	for region in _connected_regions:
		if is_instance_valid(region) and region.changed.is_connected(_refresh_depth_layout):
			region.changed.disconnect(_refresh_depth_layout)
	_connected_regions.clear()


func _on_layout_changed() -> void:
	_disconnect_layout()
	_connect_layout()
	_refresh_depth_layout()


func _refresh_depth_layout() -> void:
	if is_inside_tree():
		notify_runtime_tile_data_update()
