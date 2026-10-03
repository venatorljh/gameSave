@tool
extends Control
class_name PlayerVitalsHud


var _health := 100.0
var _max_health := 100.0
var _mana := 100.0
var _max_mana := 100.0


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	var canvas := get_parent()
	var actor: Node = canvas.get_parent() if canvas != null else null
	if actor == null or not actor.has_signal("vitals_changed"):
		return
	actor.connect("vitals_changed", Callable(self, "_on_vitals_changed"))
	_on_vitals_changed(
		float(actor.get("health")),
		float(actor.get("max_health")),
		float(actor.get("mana")),
		float(actor.get("max_mana"))
	)


func _on_vitals_changed(health: float, health_limit: float, mana: float, mana_limit: float) -> void:
	_health = health
	_max_health = maxf(health_limit, 1.0)
	_mana = mana
	_max_mana = maxf(mana_limit, 1.0)
	queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width < 60.0 or height < 50.0:
		return

	# 木底、紫灰金属边与铆钉沿用室外瓦片和宝箱的低饱和色调。
	draw_rect(Rect2(2.0, 3.0, width - 2.0, height - 3.0), Color(0.05, 0.04, 0.08, 0.5))
	draw_rect(Rect2(0.0, 0.0, width - 2.0, height - 3.0), Color("#211b29"))
	draw_rect(Rect2(2.0, 2.0, width - 6.0, height - 7.0), Color("#796d83"))
	draw_rect(Rect2(4.0, 4.0, width - 10.0, height - 11.0), Color("#302830"))
	draw_rect(Rect2(6.0, 6.0, width - 14.0, 4.0), Color("#5e4d53"))
	draw_rect(Rect2(6.0, height - 12.0, width - 14.0, 3.0), Color("#4d424f"))
	for rivet_x in [8.0, width - 13.0]:
		draw_rect(Rect2(rivet_x, 7.0, 3.0, 3.0), Color("#d9c5aa"))
		draw_rect(Rect2(rivet_x, height - 12.0, 3.0, 3.0), Color("#d9c5aa"))

	_draw_bar(Rect2(35.0, 17.0, width - 46.0, 12.0), _health, _max_health,
		Color("#a84d63"), Color("#d67b8a"))
	_draw_bar(Rect2(35.0, 39.0, width - 46.0, 12.0), _mana, _max_mana,
		Color("#5478b7"), Color("#91b1df"))

	var font := get_theme_default_font()
	if font == null:
		return
	var text_color := Color("#eadbbd")
	var shadow_color := Color("#181420")
	_draw_text(font, Vector2(9.0, 27.0), "HP", 10, text_color, shadow_color)
	_draw_text(font, Vector2(9.0, 49.0), "MP", 10, text_color, shadow_color)
	_draw_value(font, Vector2(35.0, 27.0), width - 50.0, _health, _max_health, text_color, shadow_color)
	_draw_value(font, Vector2(35.0, 49.0), width - 50.0, _mana, _max_mana, text_color, shadow_color)


func _draw_bar(rect: Rect2, current: float, maximum: float, fill_color: Color, light_color: Color) -> void:
	draw_rect(rect, Color("#17131f"))
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), rect.size - Vector2(2.0, 2.0)), Color("#514658"))
	var inner := Rect2(rect.position + Vector2(2.0, 2.0), rect.size - Vector2(4.0, 4.0))
	draw_rect(inner, Color("#211c2a"))
	var fill_width := floorf(inner.size.x * clampf(current / maximum, 0.0, 1.0))
	if fill_width > 0.0:
		draw_rect(Rect2(inner.position, Vector2(fill_width, inner.size.y)), fill_color)
		draw_rect(Rect2(inner.position, Vector2(fill_width, 2.0)), light_color)
	for index in range(1, 5):
		var tick_x := inner.position.x + floorf(inner.size.x * index / 5.0)
		draw_rect(Rect2(tick_x, inner.position.y, 1.0, inner.size.y), Color(0.09, 0.07, 0.13, 0.45))


func _draw_text(font: Font, position: Vector2, value: String, font_size: int, color: Color, shadow: Color) -> void:
	draw_string(font, position + Vector2.ONE, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow)
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_value(font: Font, position: Vector2, text_width: float, current: float,
		maximum: float, color: Color, shadow: Color) -> void:
	var value := "%d/%d" % [roundi(current), roundi(maximum)]
	draw_string(font, position + Vector2.ONE, value, HORIZONTAL_ALIGNMENT_RIGHT, text_width, 8, shadow)
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_RIGHT, text_width, 8, color)
