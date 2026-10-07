extends CanvasLayer
class_name PlayerInventoryUI


const TEXT_COLOR := Color("#eadbbd")
const MUTED_COLOR := Color("#c0adb5")
const ACCENT_COLOR := Color("#d9c5aa")
const SLOT_SIZE := 48.0
const SLOT_GAP := 4.0
const MAX_COLUMNS := 5
const MAX_ROWS := 4

@onready var _screen: Control = $Screen
@onready var _panel: Panel = $Screen/Panel
@onready var _details_panel: Panel = $Screen/ItemDetails

var _player: Node
var _inventory: ItemInventory
var _opened := false
var _selected_id: StringName = &""
var _page := 0
var _columns := MAX_COLUMNS
var _rows := MAX_ROWS
var _slot_buttons: Array[Button] = []
var _title_label: Label
var _count_label: Label
var _close_button: Button
var _previous_button: Button
var _next_button: Button
var _page_label: Label
var _hint_label: Label
var _detail_icon: TextureRect
var _detail_name: Label
var _quantity_label: Label
var _description_scroll: ScrollContainer
var _description_label: Label
var _reason_label: Label
var _feedback_label: Label
var _use_button: Button
var _details_close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_parent()
	_inventory = _player.get_node_or_null("Inventory") as ItemInventory
	_screen.theme = _make_theme()
	_build_content()
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)
	if _inventory != null:
		_inventory.changed.connect(_refresh_inventory)
	_refresh_inventory()
	_screen.hide()
	_details_panel.hide()


func _process(_delta: float) -> void:
	if not _opened:
		return
	# Other menus own their pause state; the inventory never changes it.
	if get_tree().paused or float(_player.get("health")) <= 0.0:
		close_inventory()
		return
	if _details_panel.visible:
		_update_details()


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		if _opened:
			close_inventory()
		return
	var key := event as InputEventKey
	if key != null:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_TAB:
			if key.pressed and not key.echo:
				if _opened:
					close_inventory()
				else:
					open_inventory()
			get_viewport().set_input_as_handled()
		elif _opened and code == KEY_ESCAPE:
			if key.pressed and not key.echo:
				if _details_panel.visible:
					_hide_details()
				else:
					close_inventory()
			get_viewport().set_input_as_handled()
		# Movement, combat and interaction keys continue to reach the game.
		return
	var mouse := event as InputEventMouseButton
	if _opened and _details_panel.visible and mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		if not _panel.get_global_rect().has_point(mouse.position) and not _details_panel.get_global_rect().has_point(mouse.position):
			_hide_details()


func is_open() -> bool:
	return _opened


func open_inventory() -> void:
	if _opened or _inventory == null or get_tree().paused:
		return
	if float(_player.get("health")) <= 0.0:
		return
	_opened = true
	_hide_details()
	_refresh_inventory()
	_apply_layout()
	_screen.show()


func close_inventory() -> void:
	_opened = false
	_hide_details()
	_screen.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _screen.is_ancestor_of(focused):
		focused.release_focus()


func _build_content() -> void:
	_title_label = _label("物品栏", 16)
	_panel.add_child(_title_label)
	_count_label = _label("", 10)
	_count_label.add_theme_color_override("font_color", MUTED_COLOR)
	_panel.add_child(_count_label)
	_close_button = _button("×")
	_close_button.pressed.connect(close_inventory)
	_panel.add_child(_close_button)
	_previous_button = _button("<")
	_previous_button.pressed.connect(_change_page.bind(-1))
	_panel.add_child(_previous_button)
	_page_label = _label("1 / 1", 10)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_page_label)
	_next_button = _button(">")
	_next_button.pressed.connect(_change_page.bind(1))
	_panel.add_child(_next_button)
	_hint_label = _label("暂无物品", 10)
	_hint_label.add_theme_color_override("font_color", MUTED_COLOR)
	_panel.add_child(_hint_label)

	_details_panel.add_theme_stylebox_override("panel", _style("#28212e", "#796d83", 2, 0.68))
	_detail_icon = TextureRect.new()
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_panel.add_child(_detail_icon)
	_detail_name = _label("", 13)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.max_lines_visible = 1
	_details_panel.add_child(_detail_name)
	_quantity_label = _label("", 10)
	_quantity_label.add_theme_color_override("font_color", MUTED_COLOR)
	_details_panel.add_child(_quantity_label)
	_details_close_button = _button("×")
	_details_close_button.pressed.connect(_hide_details)
	_details_panel.add_child(_details_close_button)
	_description_scroll = ScrollContainer.new()
	_description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_description_scroll.focus_mode = Control.FOCUS_NONE
	_details_panel.add_child(_description_scroll)
	_description_label = _label("", 11)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_description_scroll.add_child(_description_label)
	_reason_label = _label("", 10)
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.max_lines_visible = 2
	_reason_label.add_theme_color_override("font_color", MUTED_COLOR)
	_details_panel.add_child(_reason_label)
	_feedback_label = _label("", 10)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.max_lines_visible = 2
	_feedback_label.add_theme_color_override("font_color", ACCENT_COLOR)
	_details_panel.add_child(_feedback_label)
	_use_button = _button("使用一个")
	_use_button.pressed.connect(_use_selected_item)
	_details_panel.add_child(_use_button)


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var available := viewport_size - Vector2(24.0, 24.0)
	_columns = clampi(floori((available.x - 24.0 + SLOT_GAP) / (SLOT_SIZE + SLOT_GAP)), 1, MAX_COLUMNS)
	_rows = clampi(floori((available.y - 72.0 + SLOT_GAP) / (SLOT_SIZE + SLOT_GAP)), 1, MAX_ROWS)
	var panel_size := Vector2(
		24.0 + _columns * SLOT_SIZE + (_columns - 1) * SLOT_GAP,
		72.0 + _rows * SLOT_SIZE + (_rows - 1) * SLOT_GAP
	)
	# A plain Panel has no child-driven minimum size: contents never resize it.
	_place(_panel, Vector2(12.0, maxf(8.0, viewport_size.y - panel_size.y - 12.0)), panel_size)
	_place(_title_label, Vector2(12.0, 9.0), Vector2(60.0, 23.0))
	_place(_count_label, Vector2(78.0, 12.0), Vector2(maxf(0.0, panel_size.x - 110.0), 18.0))
	_place(_close_button, Vector2(panel_size.x - 30.0, 8.0), Vector2(20.0, 22.0))
	var footer_y := panel_size.y - 26.0
	_place(_previous_button, Vector2(12.0, footer_y), Vector2(20.0, 20.0))
	_place(_page_label, Vector2(35.0, footer_y), Vector2(39.0, 20.0))
	_place(_next_button, Vector2(77.0, footer_y), Vector2(20.0, 20.0))
	_place(_hint_label, Vector2(105.0, footer_y), Vector2(maxf(0.0, panel_size.x - 117.0), 20.0))
	_count_label.visible = _columns >= 3
	_hint_label.visible = _columns >= 3
	_title_label.text = "物品" if _columns == 1 else "物品栏"
	_title_label.add_theme_font_size_override("font_size", 12 if _columns == 1 else 16)
	if _columns == 1:
		_place(_title_label, Vector2(6.0, 9.0), Vector2(36.0, 23.0))
		_place(_close_button, Vector2(panel_size.x - 24.0, 8.0), Vector2(18.0, 22.0))
		_place(_previous_button, Vector2(5.0, footer_y), Vector2(16.0, 20.0))
		_place(_page_label, Vector2(22.0, footer_y), Vector2(28.0, 20.0))
		_place(_next_button, Vector2(51.0, footer_y), Vector2(16.0, 20.0))
	if _slot_buttons.size() != _columns * _rows:
		_rebuild_slots()
	for index in range(_slot_buttons.size()):
		var column := index % _columns
		var row := floori(float(index) / float(_columns))
		_place(_slot_buttons[index], Vector2(12.0 + column * (SLOT_SIZE + SLOT_GAP), 40.0 + row * (SLOT_SIZE + SLOT_GAP)), Vector2.ONE * SLOT_SIZE)
	_layout_details()
	_refresh_inventory()


func _rebuild_slots() -> void:
	for slot in _slot_buttons:
		_panel.remove_child(slot)
		slot.queue_free()
	_slot_buttons.clear()
	for index in range(_columns * _rows):
		var slot := _button("")
		slot.toggle_mode = true
		slot.pressed.connect(_on_slot_pressed.bind(index))
		_panel.add_child(slot)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.add_child(icon)
		_place(icon, Vector2(5.0, 4.0), Vector2(38.0, 36.0))
		var quantity := _label("", 10)
		quantity.name = "Quantity"
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		slot.add_child(quantity)
		_place(quantity, Vector2(2.0, 28.0), Vector2(43.0, 17.0))
		_slot_buttons.append(slot)


func _refresh_inventory() -> void:
	var items: Array[ItemConfig] = _inventory.get_items() if _inventory != null else []
	var capacity := maxi(1, _slot_buttons.size())
	var page_count := maxi(1, ceili(float(items.size()) / float(capacity)))
	_page = clampi(_page, 0, page_count - 1)
	var total := 0
	for item_config in items:
		total += _inventory.get_quantity(item_config.item_id)
	_count_label.text = "%d 类 · %d 件" % [items.size(), total]
	_page_label.text = ("%d/%d" if _columns == 1 else "%d / %d") % [_page + 1, page_count]
	_previous_button.disabled = _page == 0
	_next_button.disabled = _page >= page_count - 1
	_hint_label.text = "暂无物品" if items.is_empty() else "点击格子 · Tab收起"
	for index in range(_slot_buttons.size()):
		var slot := _slot_buttons[index]
		var item_index := _page * capacity + index
		var item_config: ItemConfig = items[item_index] if item_index < items.size() else null
		var icon := slot.get_node("Icon") as TextureRect
		var quantity := slot.get_node("Quantity") as Label
		slot.disabled = item_config == null
		slot.set_meta("item_id", item_config.item_id if item_config != null else &"")
		slot.set_pressed_no_signal(item_config != null and item_config.item_id == _selected_id)
		icon.texture = item_config.icon_texture if item_config != null else null
		quantity.text = "×%d" % _inventory.get_quantity(item_config.item_id) if item_config != null else ""
	if _selected_id != &"" and (_inventory == null or _inventory.get_item(_selected_id) == null):
		_hide_details()
	if _details_panel.visible:
		_update_details()
		_position_details()


func _change_page(direction: int) -> void:
	_page += direction
	_hide_details()
	_refresh_inventory()


func _on_slot_pressed(index: int) -> void:
	var item_id := StringName(_slot_buttons[index].get_meta("item_id", &""))
	if item_id == &"":
		return
	if _selected_id == item_id and _details_panel.visible:
		_hide_details()
		return
	_selected_id = item_id
	_feedback_label.text = ""
	_description_scroll.scroll_vertical = 0
	_details_panel.show()
	_refresh_inventory()


func _hide_details() -> void:
	_selected_id = &""
	_details_panel.hide()
	for slot in _slot_buttons:
		slot.set_pressed_no_signal(false)


func _layout_details() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_details_panel.size = Vector2(minf(192.0, maxf(96.0, viewport_size.x - 16.0)), minf(216.0, maxf(168.0, viewport_size.y - 16.0)))
	var card_size := _details_panel.size
	_place(_detail_icon, Vector2(10.0, 10.0), Vector2(30.0, 30.0))
	_place(_detail_name, Vector2(46.0, 8.0), Vector2(maxf(24.0, card_size.x - 75.0), 20.0))
	_place(_quantity_label, Vector2(46.0, 28.0), Vector2(card_size.x - 56.0, 16.0))
	_place(_details_close_button, Vector2(card_size.x - 27.0, 6.0), Vector2(20.0, 22.0))
	_place(_description_scroll, Vector2(10.0, 46.0), Vector2(card_size.x - 20.0, maxf(20.0, card_size.y - 144.0)))
	_place(_reason_label, Vector2(10.0, card_size.y - 90.0), Vector2(card_size.x - 20.0, 26.0))
	_place(_feedback_label, Vector2(10.0, card_size.y - 62.0), Vector2(card_size.x - 20.0, 22.0))
	_place(_use_button, Vector2(10.0, card_size.y - 34.0), Vector2(card_size.x - 20.0, 24.0))
	_position_details()


func _position_details() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var card_size := _details_panel.size
	var desired_x := _panel.position.x + _panel.size.x + 8.0
	if desired_x + card_size.x > viewport_size.x - 8.0:
		desired_x = _panel.position.x - card_size.x - 8.0
		if desired_x < 8.0:
			desired_x = viewport_size.x - card_size.x - 8.0
	var desired_y := _panel.position.y + 32.0
	for slot in _slot_buttons:
		if slot.get_meta("item_id", &"") == _selected_id and _selected_id != &"":
			desired_y = _panel.position.y + slot.position.y - 8.0
			break
	_details_panel.position = Vector2(
		clampf(desired_x, 8.0, maxf(8.0, viewport_size.x - card_size.x - 8.0)),
		clampf(desired_y, 8.0, maxf(8.0, viewport_size.y - card_size.y - 8.0))
	).floor()


func _update_details() -> void:
	var item_config := _inventory.get_item(_selected_id) if _inventory != null else null
	if item_config == null:
		_hide_details()
		return
	_detail_icon.texture = item_config.icon_texture
	_detail_name.text = item_config.display_name
	_quantity_label.text = "持有 %d 个" % _inventory.get_quantity(_selected_id)
	_description_label.text = item_config.description if not item_config.description.is_empty() else "这个物品暂时没有说明。"
	_use_button.disabled = not bool(_player.call("can_use_inventory_item", _selected_id))
	_reason_label.text = String(_player.call("get_inventory_use_reason", _selected_id))


func _use_selected_item() -> void:
	if not _opened or _inventory == null or get_tree().paused:
		return
	var item_id := _selected_id
	var item_config := _inventory.get_item(item_id)
	if item_config == null:
		return
	if bool(_player.call("use_inventory_item", item_id)):
		_feedback_label.text = "已使用：" + item_config.display_name
	else:
		_feedback_label.text = String(_player.call("get_inventory_use_reason", item_id))
	if _details_panel.visible:
		_update_details()


func _place(control: Control, position: Vector2, size: Vector2) -> void:
	control.position = position.floor()
	control.size = size.floor()


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color("#17131f"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	# Mouse clicks must not let Space activate buttons instead of rolling.
	button.focus_mode = Control.FOCUS_NONE
	return button


func _style(background: String, border: String, width: int = 2, opacity: float = 0.52) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.bg_color.a = opacity
	style.border_color = Color(border)
	style.border_color.a = 0.8
	style.set_border_width_all(width)
	style.content_margin_left = 4.0
	style.content_margin_top = 3.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 3.0
	style.anti_aliasing = false
	return style


func _make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 12
	result.set_color("font_color", "Label", TEXT_COLOR)
	result.set_color("font_color", "Button", TEXT_COLOR)
	result.set_color("font_hover_color", "Button", TEXT_COLOR)
	result.set_color("font_pressed_color", "Button", Color("#fff0c9"))
	result.set_color("font_disabled_color", "Button", Color("#8d8191"))
	result.set_stylebox("panel", "Panel", _style("#302830", "#796d83"))
	result.set_stylebox("normal", "Button", _style("#302830", "#796d83", 1, 0.2))
	result.set_stylebox("hover", "Button", _style("#4d424f", "#ad98a5", 1, 0.42))
	result.set_stylebox("pressed", "Button", _style("#5e4d53", "#d9c5aa", 2, 0.45))
	result.set_stylebox("disabled", "Button", _style("#27212c", "#514658", 1, 0.12))
	return result
