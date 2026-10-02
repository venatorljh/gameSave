extends CharacterBody2D


const MAGIC_BOLT_SCENE: PackedScene = preload("res://scenes/projectiles/magic_bolt.tscn")

@export_range(1.0, 400.0, 1.0) var move_speed := 120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var magic_origin: Marker2D = $MagicOrigin

var facing: StringName = &"down"


func _ready() -> void:
	sprite.play(&"idle_down")


func _physics_process(_delta: float) -> void:
	var horizontal := int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
	var vertical := int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	var input_direction := Vector2(horizontal, vertical)

	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		_play_animation(StringName("idle_" + String(facing)))
	else:
		velocity = input_direction.normalized() * move_speed
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
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_J:
		_fire_magic()


func _fire_magic() -> void:
	var aim := _facing_direction()
	var bolt := MAGIC_BOLT_SCENE.instantiate() as MagicBolt
	if bolt == null:
		return
	get_parent().add_child(bolt)
	bolt.launch(magic_origin.global_position + aim * 10.0, aim, self)


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
