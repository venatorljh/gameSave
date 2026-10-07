extends Area2D
class_name MagicBolt


@export var speed := 280.0
@export var max_distance := 256.0
@export var damage := 10.0

@onready var visual_sort_origin: AttackVisualSortOrigin = $VisualSortOrigin

var direction := Vector2.RIGHT
var source_body: CollisionObject2D
var distance_traveled := 0.0
var trail: Line2D
var vanishing := false
var _sort_offset := Vector2.ZERO
var _trail_world_points := PackedVector2Array()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	set_physics_process(false)


func launch(start_position: Vector2, aim: Vector2, caster: CollisionObject2D) -> void:
	source_body = caster
	direction = aim.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = start_position
	rotation = direction.angle()
	_sort_offset = AttackVisualSortOrigin.actor_sort_point(caster) - start_position
	_sync_visual_depth()
	_create_trail()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	_sync_visual_depth()
	_add_trail_point()
	if distance_traveled >= max_distance:
		_vanish()


func _sync_visual_depth() -> void:
	visual_sort_origin.set_world_sort_point(global_position + _sort_offset)


func _create_trail() -> void:
	trail = Line2D.new()
	trail.width = 2.5
	trail.antialiased = false
	var colors := Gradient.new()
	colors.set_color(0, Color(0.29, 0.15, 0.7, 0.0))
	colors.set_color(1, Color(0.8, 0.62, 1.0, 0.8))
	trail.gradient = colors
	visual_sort_origin.add_child(trail)
	visual_sort_origin.move_child(trail, 0)
	_add_trail_point()


func _add_trail_point() -> void:
	if not is_instance_valid(trail):
		return
	# History stays in world coordinates while its drawing anchor follows the bolt.
	_trail_world_points.append(global_position)
	if _trail_world_points.size() > 8:
		_trail_world_points.remove_at(0)
	var local_points := PackedVector2Array()
	for point in _trail_world_points:
		local_points.append(trail.to_local(point))
	trail.points = local_points


func _on_body_entered(body: Node2D) -> void:
	if body != source_body:
		if body.has_method("take_damage"):
			body.call("take_damage", damage)
		_vanish()


func _on_area_entered(area: Area2D) -> void:
	if area != self:
		_vanish()


func _vanish() -> void:
	if vanishing:
		return
	vanishing = true
	set_physics_process(false)
	if is_instance_valid(trail):
		# Preserve both the last ground sorting point and the visible line during its fade.
		trail.reparent(get_parent(), true)
		var fade := trail.create_tween()
		fade.tween_property(trail, "modulate:a", 0.0, 0.12)
		fade.tween_callback(trail.queue_free)
	queue_free()
