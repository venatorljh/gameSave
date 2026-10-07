extends Area2D
class_name SlashAttack


@export_range(0.05, 1.0, 0.01) var active_seconds := 0.12
@export_range(1.0, 100.0, 1.0) var damage := 14.0

@onready var visual_sort_origin: AttackVisualSortOrigin = $VisualSortOrigin
@onready var slash_sprite: Sprite2D = $VisualSortOrigin/Sprite2D

var source_body: CollisionObject2D
var _remaining := 0.0
var _hit_targets: Dictionary = {}
var _sort_point := Vector2.ZERO


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	set_physics_process(false)


func launch(origin: Vector2, aim: Vector2, caster: CollisionObject2D, attack_damage: float) -> void:
	source_body = caster
	damage = attack_damage
	global_position = origin
	rotation = aim.angle() if aim != Vector2.ZERO else 0.0
	_sort_point = AttackVisualSortOrigin.actor_sort_point(caster)
	_sync_visual_depth()
	_remaining = active_seconds
	slash_sprite.modulate.a = 1.0
	slash_sprite.rotation = -0.12
	var sweep := create_tween()
	sweep.tween_property(slash_sprite, "rotation", 0.12, active_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	monitoring = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_sync_visual_depth()
	_remaining -= delta
	if _remaining <= 0.0:
		monitoring = false
		queue_free()


func _sync_visual_depth() -> void:
	if is_instance_valid(source_body):
		_sort_point = AttackVisualSortOrigin.actor_sort_point(source_body)
	visual_sort_origin.set_world_sort_point(_sort_point)


func _on_body_entered(body: Node2D) -> void:
	_apply_hit(body)


func _on_area_entered(area: Area2D) -> void:
	var target: Node2D = area
	if not area.has_method("take_damage"):
		target = area.get_parent() as Node2D
	if target != null:
		_apply_hit(target)


func _apply_hit(target: Node2D) -> void:
	if target == source_body or not target.has_method("take_damage"):
		return
	var target_id := target.get_instance_id()
	if _hit_targets.has(target_id):
		return
	_hit_targets[target_id] = true
	target.call("take_damage", damage)
