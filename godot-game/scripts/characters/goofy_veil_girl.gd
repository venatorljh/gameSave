@tool
extends CharacterBody2D


const MAGIC_BOLT_SCENE: PackedScene = preload("res://scenes/projectiles/magic_bolt.tscn")
const SLASH_SCENE: PackedScene = preload("res://scenes/projectiles/slash_attack.tscn")

@export_range(1.0, 400.0, 1.0) var move_speed := 120.0
@export_range(1.0, 3.0, 0.05) var sprint_multiplier := 1.6
@export_range(0.05, 5.0, 0.05) var magic_cooldown := 0.5
@export_range(0.1, 3.0, 0.05) var slash_cooldown := 0.55
@export_range(1.0, 100.0, 1.0) var slash_damage := 14.0
@export_range(1.0, 100.0, 1.0) var spell_power := 10.0
@export_range(1.0, 500.0, 1.0) var max_health := 100.0
@export_range(1.0, 500.0, 1.0) var max_mana := 100.0
@export_range(0.0, 100.0, 1.0) var magic_mana_cost := 12.0
@export_range(0.0, 100.0, 0.5) var mana_regeneration_per_second := 8.0
@export_range(0.0, 5.0, 0.05) var mana_regeneration_delay := 0.8

@export_group("人物图像")
@export_range(0.01, 1.0, 0.005) var image_scale := 0.06:
	set(value):
		image_scale = value
		if is_node_ready():
			sprite.scale = Vector2.ONE * image_scale

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var magic_origin: Marker2D = $MagicOrigin
@onready var magic_cooldown_timer: Timer = $MagicCooldownTimer
@onready var slash_cooldown_timer: Timer = $SlashCooldownTimer
@onready var item_effects: ItemEffectController = $ItemEffects

var facing: StringName = &"down"
var health := 100.0
var mana := 100.0
var _mana_regeneration_wait := 0.0

signal item_collected(item_config: ItemConfig)
signal vitals_changed(current_health: float, health_limit: float, current_mana: float, mana_limit: float)


func _ready() -> void:
	sprite.scale = Vector2.ONE * image_scale
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	health = max_health
	mana = max_mana
	item_effects.effect_expired.connect(_on_item_effect_expired)
	sprite.play(&"idle_down")
	_emit_vitals_changed()


func _physics_process(delta: float) -> void:
	_regenerate_mana(delta)
	var horizontal := int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
	var vertical := int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	var input_direction := Vector2(horizontal, vertical)
	var sprinting := Input.is_key_pressed(KEY_SHIFT) and input_direction != Vector2.ZERO
	sprite.speed_scale = sprint_multiplier if sprinting else 1.0

	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		_play_animation(StringName("idle_" + String(facing)))
	else:
		var actual_speed := item_effects.get_move_speed(move_speed)
		velocity = input_direction.normalized() * actual_speed * (sprint_multiplier if sprinting else 1.0)
		_update_facing(input_direction)
		_play_animation(StringName("walk_" + String(facing)))

	move_and_slide()


func _update_facing(input_direction: Vector2) -> void:
	if absf(input_direction.x) > absf(input_direction.y):
		facing = &"right" if input_direction.x > 0.0 else &"left"
	elif absf(input_direction.y) > absf(input_direction.x):
		facing = &"down" if input_direction.y > 0.0 else &"up"
	elif facing == &"left" or facing == &"right":
		facing = &"right" if input_direction.x > 0.0 else &"left"
	else:
		facing = &"down" if input_direction.y > 0.0 else &"up"


func _play_animation(animation_name: StringName) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if key_event.pressed and not key_event.echo:
		match key_event.physical_keycode:
			KEY_J:
				_fire_magic()
			KEY_K:
				_swing_slash()


func _fire_magic() -> void:
	if not magic_cooldown_timer.is_stopped() or mana < magic_mana_cost:
		return
	var aim := _facing_direction()
	var bolt := MAGIC_BOLT_SCENE.instantiate() as MagicBolt
	if bolt == null:
		return
	get_parent().add_child(bolt)
	bolt.damage = item_effects.get_spell_power(spell_power)
	bolt.launch(magic_origin.global_position + aim * 10.0, aim, self)
	mana = maxf(0.0, mana - magic_mana_cost)
	_mana_regeneration_wait = mana_regeneration_delay
	_emit_vitals_changed()
	magic_cooldown_timer.start(item_effects.get_magic_cooldown(magic_cooldown))


func _swing_slash() -> void:
	if not slash_cooldown_timer.is_stopped():
		return
	var slash := SLASH_SCENE.instantiate() as SlashAttack
	if slash == null:
		return
	get_parent().add_child(slash)
	slash.launch(magic_origin.global_position, _facing_direction(), self, slash_damage)
	slash_cooldown_timer.start(slash_cooldown)


func _regenerate_mana(delta: float) -> void:
	var regeneration_time := delta
	if _mana_regeneration_wait > 0.0:
		var blocked_time := minf(regeneration_time, _mana_regeneration_wait)
		_mana_regeneration_wait -= blocked_time
		regeneration_time -= blocked_time
	if regeneration_time <= 0.0 or mana >= max_mana or mana_regeneration_per_second <= 0.0:
		return
	mana = minf(max_mana, mana + mana_regeneration_per_second * regeneration_time)
	_emit_vitals_changed()


func can_receive_item(item_config: ItemConfig) -> bool:
	return item_effects.can_apply(item_config, self)


func receive_item(item_config: ItemConfig) -> bool:
	if not item_effects.apply(item_config, self):
		return false
	item_collected.emit(item_config)
	_show_item_message(item_config.display_name)
	return true


func can_restore_health() -> bool:
	return health < max_health


func restore_health(amount: float) -> bool:
	if amount <= 0.0 or not can_restore_health():
		return false
	health = minf(max_health, health + amount)
	_emit_vitals_changed()
	return true


func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_emit_vitals_changed()


func _emit_vitals_changed() -> void:
	vitals_changed.emit(health, max_health, mana, max_mana)


func _show_item_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.position = Vector2(-38.0, -67.0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.24))
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -18.0), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func _on_item_effect_expired(item_config: ItemConfig) -> void:
	_show_item_message(item_config.display_name + "结束")


func _facing_direction() -> Vector2:
	match facing:
		&"up":
			return Vector2.UP
		&"left":
			return Vector2.LEFT
		&"right":
			return Vector2.RIGHT
		_:
			return Vector2.DOWN
