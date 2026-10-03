extends Node
class_name ItemEffectController


signal effect_expired(item_config: ItemConfig)

@export_range(1.0, 10.0, 0.1, "or_greater") var max_move_speed_multiplier := 2.0
@export_range(0.01, 5.0, 0.01) var min_magic_cooldown := 0.12


class ActiveBuff:
	extends RefCounted

	var config: ItemConfig
	var stacks := 1
	var remaining := 0.0

	func _init(item_config: ItemConfig) -> void:
		config = item_config
		remaining = item_config.duration


var _active_buffs: Dictionary = {}


func _process(delta: float) -> void:
	for item_config in _active_buffs.keys():
		var buff: ActiveBuff = _active_buffs[item_config]
		if buff.config.duration_mode != ItemConfig.DurationMode.TIMED:
			continue
		buff.remaining -= delta
		if buff.remaining <= 0.0:
			_active_buffs.erase(item_config)
			effect_expired.emit(buff.config)


func can_apply(item_config: ItemConfig, recipient: Node) -> bool:
	if item_config == null or item_config.item_id == &"" or item_config.strength <= 0.0:
		return false
	if item_config.effect_type == ItemConfig.EffectType.HEAL:
		return (
			item_config.duration_mode == ItemConfig.DurationMode.INSTANT
			and recipient.has_method("can_restore_health")
			and recipient.has_method("restore_health")
			and bool(recipient.call("can_restore_health"))
		)
	if item_config.duration_mode == ItemConfig.DurationMode.INSTANT:
		return false
	if item_config.duration_mode == ItemConfig.DurationMode.TIMED and item_config.duration <= 0.0:
		return false
	var existing := _active_buffs.get(item_config) as ActiveBuff
	if existing != null and item_config.duration_mode == ItemConfig.DurationMode.UNTIL_RUN_END:
		return existing.stacks < item_config.max_stacks
	return true


func apply(item_config: ItemConfig, recipient: Node) -> bool:
	if not can_apply(item_config, recipient):
		return false
	if item_config.effect_type == ItemConfig.EffectType.HEAL:
		return bool(recipient.call("restore_health", item_config.strength))
	var existing := _active_buffs.get(item_config) as ActiveBuff
	if existing == null:
		_active_buffs[item_config] = ActiveBuff.new(item_config)
	else:
		existing.stacks = mini(existing.stacks + 1, item_config.max_stacks)
		if item_config.duration_mode == ItemConfig.DurationMode.TIMED:
			existing.remaining = item_config.duration
	return true


func get_move_speed(base_speed: float) -> float:
	var multiplier := 1.0
	for active in _active_buffs.values():
		var buff: ActiveBuff = active
		if buff.config.effect_type == ItemConfig.EffectType.MOVE_SPEED:
			multiplier *= pow(buff.config.strength, buff.stacks)
	return minf(base_speed * multiplier, base_speed * max_move_speed_multiplier)


func get_magic_cooldown(base_cooldown: float) -> float:
	var cast_rate_multiplier := 1.0
	for active in _active_buffs.values():
		var buff: ActiveBuff = active
		if buff.config.effect_type == ItemConfig.EffectType.CAST_RATE:
			cast_rate_multiplier *= pow(buff.config.strength, buff.stacks)
	return maxf(minf(min_magic_cooldown, base_cooldown), base_cooldown / cast_rate_multiplier)


func get_spell_power(base_power: float) -> float:
	var bonus := 0.0
	for active in _active_buffs.values():
		var buff: ActiveBuff = active
		if buff.config.effect_type == ItemConfig.EffectType.SPELL_POWER:
			bonus += buff.config.strength * buff.stacks
	return base_power + bonus
