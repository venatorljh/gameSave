extends Node2D
class_name AttackVisualSortOrigin

## Keep the artwork in place while giving the entire effect a ground sorting point.
@onready var artwork: Sprite2D = $Sprite2D
@onready var _artwork_position: Vector2 = artwork.position


func set_world_sort_point(world_point: Vector2) -> void:
	var effect := get_parent() as Node2D
	position = effect.to_local(world_point)
	# The parent may be rotated towards any attack direction.
	artwork.position = _artwork_position - position


static func actor_sort_point(actor: Node2D) -> Vector2:
	var feet := actor.get_node_or_null("VisualSortOrigin") as Node2D
	return feet.global_position if feet != null else actor.global_position
