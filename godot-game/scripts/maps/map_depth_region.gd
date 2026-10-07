@tool
extends Resource
class_name MapDepthRegion

## Several painted cells can share the same ground point without moving their textures.
@export var display_name := "":
	set(value):
		display_name = value
		emit_changed()
@export var cell_rect := Rect2i():
	set(value):
		cell_rect = value
		emit_changed()
@export var layer_names := PackedStringArray():
	set(value):
		layer_names = value
		emit_changed()
@export var source_id := -1:
	set(value):
		source_id = value
		emit_changed()
@export var atlas_rect := Rect2i():
	set(value):
		atlas_rect = value
		emit_changed()
@export var sort_y := 0:
	set(value):
		sort_y = value
		emit_changed()
@export_range(-100, 100, 1) var draw_z := 0:
	set(value):
		draw_z = value
		emit_changed()


func matches(cell: Vector2i, layer_name: StringName, tile_source: int, atlas: Vector2i) -> bool:
	if not cell_rect.has_point(cell):
		return false
	if not layer_names.is_empty() and not layer_names.has(String(layer_name)):
		return false
	if source_id >= 0 and source_id != tile_source:
		return false
	if atlas_rect.has_area() and not atlas_rect.has_point(atlas):
		return false
	return true
