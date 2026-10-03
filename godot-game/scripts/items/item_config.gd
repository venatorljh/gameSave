extends Resource
class_name ItemConfig


enum EffectType {
	CAST_RATE,
	MOVE_SPEED,
	SPELL_POWER,
	HEAL,
}

enum DurationMode {
	INSTANT,
	TIMED,
	UNTIL_RUN_END,
}

@export_group("基础信息")
@export var item_id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export_range(0.0, 1000.0, 0.1, "or_greater") var drop_weight := 1.0

@export_group("外观")
@export var icon_texture: Texture2D

@export_group("效果")
@export var effect_type: EffectType = EffectType.CAST_RATE
# 施法频率和移速使用倍率（1.25 = +25%）；伤害和治疗使用固定数值。
@export_range(0.01, 1000.0, 0.01, "or_greater") var strength := 1.0
@export var duration_mode: DurationMode = DurationMode.UNTIL_RUN_END
@export_range(0.0, 3600.0, 0.1, "or_greater") var duration := 0.0
@export_range(1, 20, 1, "or_greater") var max_stacks := 1
