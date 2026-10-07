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

@export_group("体力")
@export_range(1.0, 500.0, 1.0) var max_stamina := 100.0
@export_range(0.0, 100.0, 0.5) var stamina_regeneration_per_second := 20.0
@export_range(0.0, 5.0, 0.05) var stamina_regeneration_delay := 0.8
@export_range(0.0, 100.0, 0.5) var sprint_stamina_per_second := 18.0
@export_range(0.0, 100.0, 1.0) var magic_stamina_cost := 12.0
@export_range(0.0, 100.0, 1.0) var slash_stamina_cost := 18.0
@export_range(0.0, 100.0, 1.0) var roll_stamina_cost := 16.0

@export_group("翻滚")
## World pixels. Walls can shorten the actual distance.
@export_range(1.0, 256.0, 1.0, "or_greater") var roll_distance := 64.0
@export_range(0.1, 2.0, 0.01) var roll_duration := 0.6
@export_range(0.0, 1.0, 0.01) var roll_invulnerability_start := 0.0
@export_range(0.0, 2.0, 0.01) var roll_invulnerability_duration := 0.43
@export_range(0.0, 1.0, 0.01) var roll_recovery_time := 0.1

@export_group("人物图像")
@export_range(0.01, 1.0, 0.005) var image_scale := 0.06:
	set(value):
		image_scale = value
		if is_node_ready():
			_apply_image_scale()
@export_range(0.5, 3.0, 0.05) var roll_image_scale_multiplier := 1.35:
	set(value):
		roll_image_scale_multiplier = value
		if is_node_ready():
			_apply_image_scale()
@export var roll_image_offset := Vector2(0.0, -185.0):
	set(value):
		roll_image_offset = value
		if is_node_ready():
			roll_sprite.offset = roll_image_offset

@onready var sprite: AnimatedSprite2D = $VisualSortOrigin/AnimatedSprite2D
@onready var roll_sprite: AnimatedSprite2D = $VisualSortOrigin/RollSprite2D
@onready var magic_origin: Marker2D = $MagicOrigin
@onready var magic_cooldown_timer: Timer = $MagicCooldownTimer
@onready var slash_cooldown_timer: Timer = $SlashCooldownTimer
@onready var item_effects: ItemEffectController = $ItemEffects
@onready var inventory: ItemInventory = $Inventory
@onready var inventory_ui: PlayerInventoryUI = $PlayerInventoryUI

var facing: StringName = &"down"
var health := 100.0
var mana := 100.0
var stamina := 100.0
var _mana_regeneration_wait := 0.0
var _stamina_regeneration_wait := 0.0
var _is_rolling := false
var _roll_direction := Vector2.DOWN
var _roll_elapsed := 0.0
var _roll_active_duration := 0.6
var _roll_active_distance := 64.0
var _roll_invulnerable_from := 0.0
var _roll_invulnerable_until := 0.43
var _roll_recovery_left := 0.0

signal item_collected(item_config: ItemConfig)
signal item_used(item_config: ItemConfig)
signal vitals_changed(current_health: float, health_limit: float, current_mana: float, mana_limit: float)
signal stamina_changed(current_stamina: float, stamina_limit: float)


func _ready() -> void:
	_apply_image_scale()
	roll_sprite.offset = roll_image_offset
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	health = max_health
	mana = max_mana
	stamina = max_stamina
	item_effects.effect_expired.connect(_on_item_effect_expired)
	sprite.play(&"idle_down")
	roll_sprite.hide()
	_emit_vitals_changed()
	_emit_stamina_changed()


func _apply_image_scale() -> void:
	sprite.scale = Vector2.ONE * image_scale
	roll_sprite.scale = Vector2.ONE * image_scale * roll_image_scale_multiplier


func _physics_process(delta: float) -> void:
	_regenerate_mana(delta)
	_roll_recovery_left = maxf(0.0, _roll_recovery_left - delta)
	if _is_rolling:
		_process_roll(delta)
		_regenerate_stamina(delta, false)
		return
	var input_direction := _movement_input()
	var sprinting := Input.is_key_pressed(KEY_SHIFT) and input_direction != Vector2.ZERO
	sprinting = sprinting and (sprint_stamina_per_second <= 0.0 or stamina > 0.0)
	var sprint_fraction := 1.0
	if sprinting and sprint_stamina_per_second > 0.0:
		# The last bit of stamina buys only that fraction of this frame's speed bonus.
		sprint_fraction = minf(1.0, stamina / maxf(sprint_stamina_per_second * delta, 0.00001))
	var movement_multiplier := lerpf(1.0, sprint_multiplier, sprint_fraction) if sprinting else 1.0
	sprite.speed_scale = movement_multiplier

	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		_play_animation(StringName("idle_" + String(facing)))
	else:
		var actual_speed := item_effects.get_move_speed(move_speed)
		velocity = input_direction.normalized() * actual_speed * movement_multiplier
		_update_facing(input_direction)
		_play_animation(StringName("walk_" + String(facing)))

	var previous_position := global_position
	move_and_slide()
	var moved := global_position.distance_squared_to(previous_position) > 0.000001
	if sprinting and moved:
		try_spend_stamina(minf(stamina, sprint_stamina_per_second * delta))
	_regenerate_stamina(delta, not (sprinting and moved))


func _movement_input() -> Vector2:
	var horizontal := int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
	var vertical := int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	return Vector2(horizontal, vertical)


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
			KEY_SPACE:
				_start_roll()


func _fire_magic() -> void:
	if _is_rolling or _roll_recovery_left > 0.0 or health <= 0.0:
		return
	if not magic_cooldown_timer.is_stopped() or mana < magic_mana_cost or not can_spend_stamina(magic_stamina_cost):
		return
	var aim := _facing_direction()
	var bolt := MAGIC_BOLT_SCENE.instantiate() as MagicBolt
	if bolt == null:
		return
	if not try_spend_stamina(magic_stamina_cost):
		bolt.free()
		return
	get_parent().add_child(bolt)
	bolt.damage = item_effects.get_spell_power(spell_power)
	bolt.launch(magic_origin.global_position + aim * 10.0, aim, self)
	mana = maxf(0.0, mana - magic_mana_cost)
	_mana_regeneration_wait = mana_regeneration_delay
	_emit_vitals_changed()
	magic_cooldown_timer.start(item_effects.get_magic_cooldown(magic_cooldown))


func _swing_slash() -> void:
	if _is_rolling or _roll_recovery_left > 0.0 or health <= 0.0:
		return
	if not slash_cooldown_timer.is_stopped() or not can_spend_stamina(slash_stamina_cost):
		return
	var slash := SLASH_SCENE.instantiate() as SlashAttack
	if slash == null:
		return
	if not try_spend_stamina(slash_stamina_cost):
		slash.free()
		return
	get_parent().add_child(slash)
	slash.launch(magic_origin.global_position, _facing_direction(), self, slash_damage)
	slash_cooldown_timer.start(slash_cooldown)


func _start_roll() -> void:
	if _is_rolling or _roll_recovery_left > 0.0 or health <= 0.0:
		return
	var direction := _movement_input()
	if direction == Vector2.ZERO:
		direction = _facing_direction()
	if roll_sprite.sprite_frames == null:
		return
	# Choose the four-way view before locking this roll's eight-way movement direction.
	var previous_facing := facing
	_update_facing(direction)
	var animation_name := StringName("roll_" + String(facing))
	if not roll_sprite.sprite_frames.has_animation(animation_name):
		facing = previous_facing
		return
	if roll_sprite.sprite_frames.get_frame_count(animation_name) == 0 or not try_spend_stamina(roll_stamina_cost):
		facing = previous_facing
		return
	_roll_direction = direction.normalized()
	_roll_elapsed = 0.0
	_roll_active_duration = maxf(0.1, roll_duration)
	_roll_active_distance = maxf(0.0, roll_distance)
	_roll_invulnerable_from = clampf(roll_invulnerability_start, 0.0, _roll_active_duration)
	_roll_invulnerable_until = minf(_roll_active_duration, _roll_invulnerable_from + maxf(0.0, roll_invulnerability_duration))
	_is_rolling = true
	sprite.stop()
	sprite.hide()
	roll_sprite.show()
	# Match the entire six-frame animation to the configured roll duration.
	var animation_seconds := 0.0
	for index in range(roll_sprite.sprite_frames.get_frame_count(animation_name)):
		animation_seconds += roll_sprite.sprite_frames.get_frame_duration(animation_name, index)
	animation_seconds /= maxf(roll_sprite.sprite_frames.get_animation_speed(animation_name), 0.001)
	roll_sprite.speed_scale = animation_seconds / _roll_active_duration
	roll_sprite.stop()
	roll_sprite.play(animation_name)
	roll_sprite.set_frame_and_progress(0, 0.0)
	get_viewport().set_input_as_handled()


func _process_roll(delta: float) -> void:
	var previous_progress := _roll_elapsed / _roll_active_duration
	_roll_elapsed = minf(_roll_active_duration, _roll_elapsed + delta)
	var progress := _roll_elapsed / _roll_active_duration
	# Ease out the travel: a quick initial dodge, then a slower landing/recovery.
	var previous_distance := _roll_active_distance * (1.0 - pow(1.0 - previous_progress, 2.0))
	var next_distance := _roll_active_distance * (1.0 - pow(1.0 - progress, 2.0))
	velocity = _roll_direction * (next_distance - previous_distance) / maxf(delta, 0.00001)
	move_and_slide()
	if _roll_elapsed >= _roll_active_duration:
		_finish_roll()


func _finish_roll() -> void:
	_is_rolling = false
	velocity = Vector2.ZERO
	_roll_recovery_left = maxf(0.0, roll_recovery_time)
	roll_sprite.stop()
	roll_sprite.hide()
	sprite.show()
	sprite.speed_scale = 1.0
	_play_animation(StringName("idle_" + String(facing)))


func is_invulnerable() -> bool:
	return _is_rolling and _roll_elapsed >= _roll_invulnerable_from and _roll_elapsed < _roll_invulnerable_until


func can_spend_stamina(amount: float) -> bool:
	return stamina >= maxf(0.0, amount)


func try_spend_stamina(amount: float) -> bool:
	var cost := maxf(0.0, amount)
	if not can_spend_stamina(cost):
		return false
	if cost <= 0.0:
		return true
	stamina = maxf(0.0, stamina - cost)
	_stamina_regeneration_wait = maxf(0.0, stamina_regeneration_delay)
	_emit_stamina_changed()
	return true


func _regenerate_stamina(delta: float, movement_allows_regeneration: bool) -> void:
	var regeneration_time := delta
	if _stamina_regeneration_wait > 0.0:
		var blocked_time := minf(regeneration_time, _stamina_regeneration_wait)
		_stamina_regeneration_wait -= blocked_time
		regeneration_time -= blocked_time
	if not movement_allows_regeneration or _is_rolling or _roll_recovery_left > 0.0 or health <= 0.0:
		return
	if regeneration_time <= 0.0 or stamina >= max_stamina or stamina_regeneration_per_second <= 0.0:
		return
	stamina = minf(max_stamina, stamina + stamina_regeneration_per_second * regeneration_time)
	_emit_stamina_changed()


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
	return inventory.can_store(item_config)


func receive_item(item_config: ItemConfig) -> bool:
	if not inventory.add_item(item_config):
		return false
	item_collected.emit(item_config)
	_show_item_message("已收纳：" + item_config.display_name)
	return true


func can_use_inventory_item(item_id: StringName) -> bool:
	if health <= 0.0 or _is_rolling or _roll_recovery_left > 0.0:
		return false
	var item_config := inventory.get_item(item_id)
	return inventory.get_quantity(item_id) > 0 and item_effects.can_apply(item_config, self)


func use_inventory_item(item_id: StringName) -> bool:
	if not can_use_inventory_item(item_id):
		return false
	var item_config := inventory.get_item(item_id)
	if not inventory.use_item(item_id, self, item_effects):
		return false
	item_used.emit(item_config)
	_show_item_message("已使用：" + item_config.display_name)
	return true


func get_inventory_use_reason(item_id: StringName) -> String:
	var item_config := inventory.get_item(item_id)
	if item_config == null or inventory.get_quantity(item_id) <= 0:
		return "物品已用完"
	if health <= 0.0:
		return "人物已倒下，无法使用"
	if _is_rolling or _roll_recovery_left > 0.0:
		return "翻滚结束后才能使用"
	if item_effects.can_apply(item_config, self):
		return ""
	if item_config.effect_type == ItemConfig.EffectType.HEAL and not can_restore_health():
		return "生命值已满，药水将保留"
	if item_config.duration_mode == ItemConfig.DurationMode.UNTIL_RUN_END:
		return "当前效果已达到叠加上限，物品将保留"
	return "当前无法使用，物品将保留"


func can_restore_health() -> bool:
	return health < max_health


func restore_health(amount: float) -> bool:
	if amount <= 0.0 or not can_restore_health():
		return false
	health = minf(max_health, health + amount)
	_emit_vitals_changed()
	return true


func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0 or is_invulnerable():
		return
	health = maxf(0.0, health - amount)
	_emit_vitals_changed()


func _emit_vitals_changed() -> void:
	vitals_changed.emit(health, max_health, mana, max_mana)


func _emit_stamina_changed() -> void:
	stamina_changed.emit(stamina, max_stamina)


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
