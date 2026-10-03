@tool
extends Resource
class_name MonsterConfig


enum AttackKind {
	ARM_SWING,
	CHARGE,
}

@export_group("基础")
@export var monster_id: StringName = &""
@export var display_name := ""
@export_range(1.0, 1000.0, 1.0) var max_health := 30.0
@export_range(0.0, 100.0, 0.5) var contact_damage := 8.0

@export_group("巡逻与锁敌")
@export_range(0.0, 300.0, 1.0) var patrol_radius := 48.0
@export_range(0.0, 200.0, 1.0) var patrol_speed := 28.0
@export_range(0.0, 300.0, 1.0) var chase_speed := 75.0
@export_range(8.0, 400.0, 1.0) var detection_radius := 96.0
@export_range(16.0, 600.0, 1.0) var max_chase_distance := 220.0
@export_range(0.0, 5.0, 0.1) var patrol_pause_seconds := 0.6

@export_group("攻击")
@export var attack_kind: AttackKind = AttackKind.ARM_SWING
@export_range(8.0, 120.0, 1.0) var attack_range := 28.0
@export_range(0.1, 5.0, 0.05) var attack_cooldown := 0.8
@export_range(0.0, 2.0, 0.01) var attack_windup := 0.18
@export_range(0.05, 2.0, 0.01) var attack_active_seconds := 0.14
@export_range(0.0, 2.0, 0.01) var attack_recovery := 0.3
@export_range(1.0, 60.0, 1.0) var hitbox_radius := 13.0
@export_range(0.0, 60.0, 1.0) var hitbox_forward_offset := 17.0
@export_range(0.0, 500.0, 1.0) var charge_speed := 200.0

@export_group("碰撞与外观")
@export_range(2.0, 30.0, 1.0) var body_radius := 6.0
@export_range(4.0, 60.0, 1.0) var body_height := 18.0
@export var body_offset := Vector2(0.0, -10.0)
@export var sprite_offset := Vector2(0.0, -13.0)
@export var sprite_scale := Vector2.ONE
@export var death_sprite_scale := Vector2.ONE
@export var art_faces_right := true

@export_group("逐帧图")
@export var sprite_sheet: Texture2D
@export var frame_size := Vector2i(32, 32)
@export_range(1, 40, 1) var frames_per_row := 8
@export var patrol_rows := PackedInt32Array([0])
@export var chase_rows := PackedInt32Array([1])
@export var attack_rows := PackedInt32Array([2])
@export_range(1.0, 30.0, 1.0) var patrol_fps := 8.0
@export_range(1.0, 30.0, 1.0) var chase_fps := 10.0
@export_range(1.0, 30.0, 1.0) var attack_fps := 12.0

@export_group("死亡逐帧图")
# 留空则沿用主图；眼球怪在这里指定独立的炸裂图。
@export var death_sheet: Texture2D
@export var death_frame_size := Vector2i(32, 32)
@export_range(1, 40, 1) var death_frames_per_row := 8
@export var death_rows := PackedInt32Array([3])
@export_range(1.0, 30.0, 1.0) var death_fps := 12.0
