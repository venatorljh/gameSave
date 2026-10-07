extends Node
class_name ItemInventory


signal changed()

# ItemConfig.max_stacks limits active effects, not the amount stored here.
var _items: Array[ItemConfig] = []
var _quantities: Dictionary = {}


func can_store(item_config: ItemConfig) -> bool:
	return item_config != null and item_config.item_id != &""


func add_item(item_config: ItemConfig) -> bool:
	if not can_store(item_config):
		return false
	var item_id := item_config.item_id
	if not _quantities.has(item_id):
		_items.append(item_config)
	_quantities[item_id] = get_quantity(item_id) + 1
	changed.emit()
	return true


func get_items() -> Array[ItemConfig]:
	return _items.duplicate()


func get_quantity(item_id: StringName) -> int:
	return int(_quantities.get(item_id, 0))


func get_item(item_id: StringName) -> ItemConfig:
	for item_config in _items:
		if item_config.item_id == item_id:
			return item_config
	return null


func use_item(item_id: StringName, recipient: Node, effects: ItemEffectController) -> bool:
	var item_config := get_item(item_id)
	if item_config == null or get_quantity(item_id) <= 0 or effects == null:
		return false
	# Apply before removing: failed healing or a capped buff keeps the item.
	if not effects.apply(item_config, recipient):
		return false
	var remaining := get_quantity(item_id) - 1
	if remaining > 0:
		_quantities[item_id] = remaining
	else:
		_quantities.erase(item_id)
		_items.erase(item_config)
	changed.emit()
	return true
