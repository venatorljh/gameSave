@tool
extends Area2D
class_name ItemPickup


@export var item_config: ItemConfig:
	set(value):
		item_config = value
		_refresh_visuals()

var _waiting_bodies: Array[Node2D] = []
var _retry_delay := 0.0


func _ready() -> void:
	_refresh_visuals()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	set_process(false)
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_visuals()


func _physics_process(delta: float) -> void:
	_retry_delay -= delta
	if _retry_delay > 0.0:
		return
	_retry_delay = 0.25
	for body in _waiting_bodies.duplicate():
		if not is_instance_valid(body):
			_waiting_bodies.erase(body)
		elif _try_collect(body):
			return
	if _waiting_bodies.is_empty():
		set_physics_process(false)


func configure(config: ItemConfig) -> void:
	item_config = config


func _refresh_visuals() -> void:
	var icon := get_node_or_null("Icon") as Sprite2D
	if icon != null:
		var desired_texture: Texture2D = item_config.icon_texture if item_config != null else null
		if icon.texture != desired_texture:
			icon.texture = desired_texture


func _on_body_entered(body: Node2D) -> void:
	if item_config == null or not body.has_method("receive_item"):
		return
	if not _try_collect(body):
		_waiting_bodies.append(body)
		_retry_delay = 0.25
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	_waiting_bodies.erase(body)
	if _waiting_bodies.is_empty():
		set_physics_process(false)


func _try_collect(body: Node2D) -> bool:
	if not bool(body.call("receive_item", item_config)):
		return false
	queue_free()
	return true
