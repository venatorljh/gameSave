@tool
extends Resource
class_name MapDepthLayout

## Specific rules precede broad building rules. The first matching region wins.
@export var regions: Array[MapDepthRegion] = []:
	set(value):
		regions = value
		emit_changed()


func find_region(cell: Vector2i, layer_name: StringName, tile_source: int, atlas: Vector2i) -> MapDepthRegion:
	for region in regions:
		if region != null and region.matches(cell, layer_name, tile_source, atlas):
			return region
	return null
