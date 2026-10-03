extends StaticBody2D
class_name TreasureChest


const PICKUP_SCENE: PackedScene = preload("res://scenes/items/item_pickup.tscn")
const OPEN_TEXTURE: Texture2D = preload("res://items/chest_open_v1.png")

@export var drop_offset := Vector2(0.0, 20.0)
@export var fixed_loot: ItemConfig
@export var loot_pool: Array[ItemConfig] = []

@onready var chest_sprite: Sprite2D = $ChestSprite
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt: Label = $InteractionPrompt

var nearby_player: Node2D
var opened := false


func _ready() -> void:
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	prompt.hide()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_E and is_instance_valid(nearby_player) and not opened:
		_open()
		get_viewport().set_input_as_handled()


func _on_player_entered(body: Node2D) -> void:
	if body.has_method("can_receive_item"):
		nearby_player = body
		if not opened:
			prompt.text = "E"
			prompt.show()


func _on_player_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		prompt.hide()


func _open() -> void:
	var selected := _choose_loot()
	if selected == null:
		prompt.text = "暂无可用道具"
		return
	var loot := PICKUP_SCENE.instantiate() as ItemPickup
	if loot == null:
		return
	loot.configure(selected)
	opened = true
	chest_sprite.texture = OPEN_TEXTURE
	prompt.hide()
	get_parent().add_child(loot)
	loot.global_position = global_position + drop_offset


func _choose_loot() -> ItemConfig:
	if fixed_loot != null:
		return fixed_loot if _can_receive(fixed_loot) else null
	var total_weight := 0.0
	var candidates: Array[ItemConfig] = []
	for config in loot_pool:
		if config == null or config.drop_weight <= 0.0 or not _can_receive(config):
			continue
		candidates.append(config)
		total_weight += config.drop_weight
	if candidates.is_empty():
		return null
	var roll := randf() * total_weight
	for config in candidates:
		roll -= config.drop_weight
		if roll < 0.0:
			return config
	return candidates.back()


func _can_receive(config: ItemConfig) -> bool:
	return (
		is_instance_valid(nearby_player)
		and bool(nearby_player.call("can_receive_item", config))
	)
