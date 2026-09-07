extends Control
## Рисованная пара кубиков с точками.

var dice: Array = [1, 1]
var accent: Color = Color("#e03131")


func _draw() -> void:
	var s := size.y * 0.92
	for i in 2:
		var pos := Vector2(i * (size.x - s), (size.y - s) / 2.0)
		_draw_die(Rect2(pos, Vector2(s, s)), dice[clampi(i, 0, dice.size() - 1)])


func _draw_die(rect: Rect2, value: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#f8f9fa")
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_color = accent
	sb.set_border_width_all(2)
	draw_style_box(sb, rect)

	var pip := rect.size.x * 0.09
	var c := rect.get_center()
	var dx := rect.size.x * 0.24
	var col := Color("#212529")
	var points: Array[Vector2] = []
	match value:
		1:
			points = [c]
		2:
			points = [c + Vector2(-dx, -dx), c + Vector2(dx, dx)]
		3:
			points = [c + Vector2(-dx, -dx), c, c + Vector2(dx, dx)]
		4:
			points = [c + Vector2(-dx, -dx), c + Vector2(dx, -dx), c + Vector2(-dx, dx), c + Vector2(dx, dx)]
		5:
			points = [c + Vector2(-dx, -dx), c + Vector2(dx, -dx), c, c + Vector2(-dx, dx), c + Vector2(dx, dx)]
		6:
			points = [c + Vector2(-dx, -dx), c + Vector2(dx, -dx), c + Vector2(-dx, 0), c + Vector2(dx, 0),
				c + Vector2(-dx, dx), c + Vector2(dx, dx)]
	for p in points:
		draw_circle(p, pip, col)
