extends Area2D


@export var destination_scene: PackedScene
@export var arrival_marker_name: StringName = &"ArrivalFromOutdoor"

@onready var prompt: Label = $InteractionPrompt
@onready var choice_dialog: ConfirmationDialog = $ChoiceDialog

var nearby_player: CharacterBody2D
var _transitioning := false


func _ready() -> void:
	monitoring = true
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	choice_dialog.confirmed.connect(_on_confirmed)
	choice_dialog.canceled.connect(_on_canceled)


func _unhandled_key_input(event: InputEvent) -> void:
	if _transitioning or not is_instance_valid(nearby_player) or choice_dialog.visible:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_E:
		choice_dialog.popup_centered(Vector2i(360, 140))
		get_tree().paused = true
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	var player := body as CharacterBody2D
	if player != null and player.get_collision_layer_value(2):
		nearby_player = player
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	prompt.hide()
	if choice_dialog.visible:
		choice_dialog.hide()
		get_tree().paused = false


func _on_confirmed() -> void:
	get_tree().paused = false
	if _transitioning:
		return
	_transitioning = true
	call_deferred("_change_map")


func _on_canceled() -> void:
	get_tree().paused = false


func _change_map() -> void:
	if not is_instance_valid(nearby_player) or destination_scene == null:
		_transitioning = false
		return
	var instance := destination_scene.instantiate()
	if instance == null:
		push_error("无法实例化目标地图。")
		_transitioning = false
		return
	var next_map := instance as Node2D
	if next_map == null:
		push_error("目标地图的根节点必须是 Node2D。")
		instance.free()
		_transitioning = false
		return
	var arrival := next_map.get_node_or_null(NodePath(String(arrival_marker_name))) as Marker2D
	if arrival == null:
		push_error("目标地图缺少到达点：" + String(arrival_marker_name))
		next_map.free()
		_transitioning = false
		return
	var old_map := get_tree().current_scene
	if old_map == null:
		old_map = get_parent()
	get_tree().root.add_child(next_map)
	nearby_player.reparent(next_map)
	nearby_player.global_position = arrival.global_position
	nearby_player.velocity = Vector2.ZERO
	get_tree().current_scene = next_map
	old_map.queue_free()
