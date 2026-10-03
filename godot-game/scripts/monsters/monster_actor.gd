@tool
extends CharacterBody2D
class_name MonsterActor


enum State {
	PATROL,
	CHASE,
	WINDUP,
	ATTACK,
	RECOVER,
	DEAD,
}

@export var monster_config: MonsterConfig:
	set(value):
		monster_config = value
		if is_node_ready():
			_apply_config()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

var _state := State.PATROL
var _health := 0.0
var _target: Node2D
var _home := Vector2.ZERO
var _patrol_destination := Vector2.ZERO
var _patrol_wait := 0.0
var _state_time := 0.0
var _attack_cooldown_left := 0.0
var _attack_direction := Vector2.RIGHT
var _hit_targets: Dictionary = {}


func _ready() -> void:
	_apply_config()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	if monster_config == null:
		push_warning("MonsterActor 缺少 MonsterConfig 资源。")
		set_physics_process(false)
		return
	_home = global_position
	_patrol_destination = _home
	_health = monster_config.max_health
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_area.body_entered.connect(_on_attack_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	_play_animation(&"patrol")


func _apply_config() -> void:
	if monster_config == null:
		return
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = monster_config.body_radius
	body_shape.height = maxf(monster_config.body_height, monster_config.body_radius * 2.0)
	body_collision.shape = body_shape
	body_collision.position = monster_config.body_offset

	var detection_shape := CircleShape2D.new()
	detection_shape.radius = monster_config.detection_radius
	detection_collision.shape = detection_shape
	detection_area.position = monster_config.body_offset

	var attack_shape := CircleShape2D.new()
	attack_shape.radius = monster_config.hitbox_radius
	attack_collision.shape = attack_shape
	attack_area.position = monster_config.body_offset

	sprite.position = monster_config.sprite_offset
	sprite.scale = monster_config.sprite_scale
	sprite.sprite_frames = _build_sprite_frames()
	if Engine.is_editor_hint() and sprite.sprite_frames.has_animation(&"patrol"):
		sprite.animation = &"patrol"
		sprite.frame = 0


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	if monster_config.sprite_sheet == null:
		return frames
	_add_animation(frames, &"patrol", monster_config.sprite_sheet, monster_config.frame_size,
		monster_config.frames_per_row, monster_config.patrol_rows, monster_config.patrol_fps, true)
	_add_animation(frames, &"chase", monster_config.sprite_sheet, monster_config.frame_size,
		monster_config.frames_per_row, monster_config.chase_rows, monster_config.chase_fps, true)
	_add_animation(frames, &"attack", monster_config.sprite_sheet, monster_config.frame_size,
		monster_config.frames_per_row, monster_config.attack_rows, monster_config.attack_fps, false)
	var death_texture: Texture2D = monster_config.death_sheet if monster_config.death_sheet != null else monster_config.sprite_sheet
	_add_animation(frames, &"death", death_texture, monster_config.death_frame_size,
		monster_config.death_frames_per_row, monster_config.death_rows, monster_config.death_fps, false)
	return frames


func _add_animation(frames: SpriteFrames, animation_name: StringName, sheet: Texture2D,
		cell_size: Vector2i, columns: int, rows: PackedInt32Array, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	if sheet == null or cell_size.x <= 0 or cell_size.y <= 0:
		return
	for row in rows:
		for column in range(columns):
			var region := Rect2(column * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y)
			if region.end.x > sheet.get_width() or region.end.y > sheet.get_height():
				continue
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = region
			frame.filter_clip = true
			frames.add_frame(animation_name, frame)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or monster_config == null or _state == State.DEAD:
		return
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	match _state:
		State.PATROL:
			_tick_patrol(delta)
		State.CHASE:
			_tick_chase()
		State.WINDUP:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_begin_attack()
		State.ATTACK:
			_tick_attack(delta)
		State.RECOVER:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_finish_recovery()
	move_and_slide()
	if _state == State.ATTACK:
		_try_attack_overlaps()
		if monster_config.attack_kind == MonsterConfig.AttackKind.CHARGE and get_slide_collision_count() > 0:
			_begin_recovery()
	elif _state == State.PATROL and get_slide_collision_count() > 0:
		_patrol_wait = monster_config.patrol_pause_seconds
		_patrol_destination = global_position


func _tick_patrol(delta: float) -> void:
	velocity = Vector2.ZERO
	_play_animation(&"patrol")
	if _patrol_wait > 0.0:
		_patrol_wait -= delta
		if _patrol_wait <= 0.0:
			_pick_patrol_destination()
		return
	var offset := _patrol_destination - global_position
	if offset.length() < 5.0:
		_patrol_wait = monster_config.patrol_pause_seconds
		if _patrol_wait <= 0.0:
			_pick_patrol_destination()
		return
	velocity = offset.normalized() * monster_config.patrol_speed
	_update_visual_facing(offset)


func _pick_patrol_destination() -> void:
	if monster_config.patrol_radius <= 0.0:
		_patrol_destination = _home
		return
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(monster_config.patrol_radius * 0.3, monster_config.patrol_radius)
	_patrol_destination = _home + Vector2.RIGHT.rotated(angle) * distance


func _tick_chase() -> void:
	if not is_instance_valid(_target) or global_position.distance_to(_home) > monster_config.max_chase_distance:
		_target = null
		_resume_patrol()
		return
	var to_target := _target.global_position - global_position
	if to_target.length() <= monster_config.attack_range:
		velocity = Vector2.ZERO
		if _attack_cooldown_left <= 0.0:
			_begin_windup(to_target)
		return
	velocity = to_target.normalized() * monster_config.chase_speed
	_update_visual_facing(to_target)
	_play_animation(&"chase")


func _begin_windup(to_target: Vector2) -> void:
	_state = State.WINDUP
	_state_time = monster_config.attack_windup
	_attack_cooldown_left = monster_config.attack_cooldown
	_attack_direction = to_target.normalized() if to_target != Vector2.ZERO else Vector2.RIGHT
	_update_visual_facing(_attack_direction)
	attack_area.position = monster_config.body_offset + _attack_direction * monster_config.hitbox_forward_offset
	velocity = Vector2.ZERO
	_play_animation(&"attack")


func _begin_attack() -> void:
	_state = State.ATTACK
	_state_time = monster_config.attack_active_seconds
	_hit_targets.clear()
	if monster_config.attack_kind == MonsterConfig.AttackKind.CHARGE:
		attack_area.position = monster_config.body_offset
	else:
		attack_area.position = monster_config.body_offset + _attack_direction * monster_config.hitbox_forward_offset


func _tick_attack(delta: float) -> void:
	velocity = _attack_direction * monster_config.charge_speed if monster_config.attack_kind == MonsterConfig.AttackKind.CHARGE else Vector2.ZERO
	_state_time -= delta
	if _state_time <= 0.0:
		_begin_recovery()


func _begin_recovery() -> void:
	_state = State.RECOVER
	_state_time = monster_config.attack_recovery
	velocity = Vector2.ZERO


func _finish_recovery() -> void:
	if is_instance_valid(_target):
		_state = State.CHASE
		_play_animation(&"chase")
	else:
		_resume_patrol()


func _resume_patrol() -> void:
	_state = State.PATROL
	_patrol_destination = _home
	_patrol_wait = 0.0
	velocity = Vector2.ZERO
	_play_animation(&"patrol")


func _try_attack_overlaps() -> void:
	for body in attack_area.get_overlapping_bodies():
		_hit_body(body)


func _hit_body(body: Node2D) -> void:
	if _state != State.ATTACK or body == self or not body.has_method("take_damage"):
		return
	var target_id := body.get_instance_id()
	if _hit_targets.has(target_id):
		return
	_hit_targets[target_id] = true
	body.call("take_damage", monster_config.contact_damage)


func take_damage(amount: float) -> void:
	if Engine.is_editor_hint() or _state == State.DEAD or amount <= 0.0:
		return
	_health = maxf(0.0, _health - amount)
	if _health <= 0.0:
		_die()


func _die() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	_target = null
	body_collision.set_deferred("disabled", true)
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	sprite.scale = monster_config.death_sprite_scale
	_play_animation(&"death")
	set_physics_process(false)
	if sprite.sprite_frames.get_frame_count(&"death") == 0:
		queue_free()


func _play_animation(animation_name: StringName) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _update_visual_facing(direction: Vector2) -> void:
	if absf(direction.x) < 0.1:
		return
	sprite.flip_h = direction.x < 0.0 if monster_config.art_faces_right else direction.x > 0.0


func _on_detection_body_entered(body: Node2D) -> void:
	if _state == State.DEAD or not body.has_method("take_damage"):
		return
	_target = body
	if _state == State.PATROL:
		_state = State.CHASE
		_play_animation(&"chase")


func _on_detection_body_exited(body: Node2D) -> void:
	if body != _target:
		return
	_target = null
	if _state == State.CHASE:
		_resume_patrol()


func _on_attack_body_entered(body: Node2D) -> void:
	_hit_body(body)


func _on_animation_finished() -> void:
	if _state == State.DEAD and sprite.animation == &"death":
		queue_free()
