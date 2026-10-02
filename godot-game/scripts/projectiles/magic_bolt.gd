extends Area2D
class_name MagicBolt


@export var speed := 280.0
@export var max_distance := 256.0

var direction := Vector2.RIGHT
var source_body: CollisionObject2D
var distance_traveled := 0.0
var trail: Line2D
var vanishing := false


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
	_create_trail()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	_add_trail_point()
	if distance_traveled >= max_distance:
		_vanish()


func _create_trail() -> void:
	trail = Line2D.new()
	trail.width = 2.5
	trail.antialiased = false
	trail.z_index = 1
	var colors := Gradient.new()
	colors.set_color(0, Color(0.29, 0.15, 0.7, 0.0))
	colors.set_color(1, Color(0.8, 0.62, 1.0, 0.8))
	trail.gradient = colors
	get_parent().add_child(trail)
	_add_trail_point()


func _add_trail_point() -> void:
	if not is_instance_valid(trail):
		return
	trail.add_point(trail.to_local(global_position))
	if trail.get_point_count() > 8:
		trail.remove_point(0)


func _on_body_entered(body: Node2D) -> void:
	if body != source_body:
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
		var fade := trail.create_tween()
		fade.tween_property(trail, "modulate:a", 0.0, 0.12)
		fade.tween_callback(trail.queue_free)
	queue_free()
