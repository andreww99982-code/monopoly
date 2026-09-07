extends Control
## Отрисовка классического квадратного поля Монополии 11x11 (40 клеток),
## центра в стиле темы и фишек-персонажей (свинья-копилка в цилиндре).

# Типы клеток (должны совпадать с main.gd)
const T_CORNER := 0
const T_STREET := 1
const T_RAIL := 2
const T_UTIL := 3
const T_CHANCE := 4
const T_CHEST := 5
const T_TAX := 6

const GROUP_COLORS := [
	Color("#7b4a2d"), Color("#8bd3e6"), Color("#d63384"), Color("#f59f00"),
	Color("#e03131"), Color("#ffd43b"), Color("#2f9e44"), Color("#1971c2"),
]
const OWNER_COLORS := [Color("#2d7dbd"), Color("#ae435f"), Color("#b48a31"), Color("#4e9968")]

var tiles: Array = []
var players: Array = []
var board_theme: Dictionary = {}
var player_colors: Array = [Color("#4dabf7"), Color("#ff6b8a"), Color("#ffd166"), Color("#8ce99a")]
var current_player := 0


func _draw() -> void:
	if tiles.is_empty() or board_theme.is_empty():
		return
	var cell := size.x / 11.0
	var font := ThemeDB.fallback_font

	# Центральное поле
	var center_rect := Rect2(cell, cell, cell * 9, cell * 9)
	draw_rect(center_rect, board_theme.center_b)
	draw_rect(Rect2(cell * 1.4, cell * 1.4, cell * 8.2, cell * 8.2), board_theme.center_a)
	_draw_center_logo(font, cell)

	for i in tiles.size():
		_draw_tile(font, i, cell)

	# Фишки игроков поверх клеток
	for index in players.size():
		var player: Dictionary = players[index]
		if player.bankrupt:
			continue
		var rect := _tile_rect(player.position, cell)
		var offset := Vector2((index % 2) * cell * 0.3, (index / 2) * cell * 0.3)
		var c := rect.get_center() + Vector2(-cell * 0.18, -cell * 0.22) + offset
		_draw_token(c, cell * 0.34, player_colors[index % player_colors.size()], index == current_player)


# --- Геометрия поля ---------------------------------------------------------

func _tile_rect(index: int, cell: float) -> Rect2:
	# 0 — правый нижний угол, движение против часовой стрелки, как в оригинале
	if index == 0:
		return Rect2(cell * 10, cell * 10, cell, cell)
	if index < 10:  # нижняя сторона, справа налево
		return Rect2(cell * (10 - index), cell * 10, cell, cell)
	if index == 10:
		return Rect2(0, cell * 10, cell, cell)
	if index < 20:  # левая сторона, снизу вверх
		return Rect2(0, cell * (20 - index), cell, cell)
	if index == 20:
		return Rect2(0, 0, cell, cell)
	if index < 30:  # верхняя сторона, слева направо
		return Rect2(cell * (index - 20), 0, cell, cell)
	if index == 30:
		return Rect2(cell * 10, 0, cell, cell)
	return Rect2(cell * 10, cell * (index - 30), cell, cell)  # правая сторона сверху вниз


func _tile_inner(rect: Rect2) -> Rect2:
	return rect.grow(-1.0)


# --- Отрисовка --------------------------------------------------------------

func _draw_center_logo(font: Font, cell: float) -> void:
	var center := Vector2(cell * 5.5, cell * 5.5)
	# Плашка в стиле логотипа MONOPOLY, повёрнутая по диагонали
	var set := Transform2D(deg_to_rad(-45.0), center)
	draw_set_transform(set.origin, set.get_rotation(), Vector2.ONE)
	var w := cell * 5.2
	var h := cell * 1.5
	var rect := Rect2(-w / 2, -h / 2, w, h)
	draw_rect(rect, board_theme.accent)
	draw_rect(rect, Color(1, 1, 1, 0.9), false, 4.0)
	var ts := int(h * 0.52)
	var tw := font.get_string_size(board_theme.board_title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
	while tw > w - 30 and ts > 8:
		ts -= 2
		tw = font.get_string_size(board_theme.board_title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
	draw_string(font, Vector2(-tw / 2, ts * 0.36), board_theme.board_title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Подпись под плашкой
	var sub: String = board_theme.board_subtitle
	var ss := int(cell * 0.30)
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
	var text_col: Color = board_theme.text if board_theme.center_a.get_luminance() < 0.45 else board_theme.bg.darkened(0.4)
	draw_string(font, center + Vector2(-sw / 2, cell * 1.5), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, text_col)
	# Декоративная мини-свинья под логотипом
	_draw_token(center + Vector2(0, -cell * 1.35), cell * 0.62, board_theme.accent, false)


func _draw_tile(font: Font, index: int, cell: float) -> void:
	var tile: Dictionary = tiles[index]
	var rect := _tile_rect(index, cell)
	var inner := _tile_inner(rect)
	var base := Color("#f4f0e6")  # слоновая кость классической доски
	var border := Color("#2b2b30")
	draw_rect(inner, base)
	draw_rect(inner, border, false, 1.5)

	match tile.type:
		T_STREET:
			_draw_color_band(rect, index, GROUP_COLORS[tile.group], cell)
		T_CORNER:
			_draw_corner(font, tile, rect, cell)
		T_CHANCE:
			_draw_symbol_tile(font, tile, rect, "?", Color("#e8590c"), cell)
		T_CHEST:
			_draw_chest(tile, rect, cell)
		T_RAIL:
			_draw_rail(font, tile, rect, cell)
		T_UTIL:
			_draw_util(font, tile, rect, cell)
		T_TAX:
			_draw_symbol_tile(font, tile, rect, "◆", Color("#495057"), cell)

	# Подписи: название + цена
	if tile.type != T_CORNER:
		_draw_tile_label(font, tile, rect, cell)

	# Маркер владельца — цветная плашка снизу
	if tile.get("owner", -1) != -1:
		var own := rect
		own.position.y = rect.end.y - cell * 0.12
		own.size.y = cell * 0.12
		draw_rect(own, OWNER_COLORS[tile.owner % OWNER_COLORS.size()])


func _draw_color_band(rect: Rect2, index: int, color: Color, cell: float) -> void:
	var band := rect
	if index > 0 and index < 10:        # низ — полоса сверху
		band.size.y = cell * 0.24
	elif index > 10 and index < 20:     # левая — полоса справа
		band.position.x = rect.end.x - cell * 0.24
		band.size.x = cell * 0.24
	elif index > 20 and index < 30:     # верх — полоса снизу
		band.position.y = rect.end.y - cell * 0.24
		band.size.y = cell * 0.24
	else:                               # правая — полоса слева
		band.size.x = cell * 0.24
	draw_rect(band.grow(-1.0), color)


func _draw_corner(font: Font, tile: Dictionary, rect: Rect2, cell: float) -> void:
	var c := rect.get_center()
	draw_rect(rect.grow(-1.0), board_theme.accent.darkened(0.1))
	draw_rect(rect.grow(-2.0), board_theme.accent.lightened(0.08))
	var ts := int(cell * 0.17)
	var col := Color.WHITE
	var words: PackedStringArray = tile.name.split(" ")
	var y := c.y - (words.size() - 1) * ts * 0.62
	for word in words:
		var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		var tw := w
		var t2 := ts
		while tw > rect.size.x - 6 and t2 > 6:
			t2 -= 1
			tw = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, t2).x
		draw_string(font, Vector2(c.x - tw / 2, y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, t2, col)
		y += ts * 1.24


func _draw_symbol_tile(font: Font, tile: Dictionary, rect: Rect2, symbol: String, color: Color, cell: float) -> void:
	var c := rect.get_center()
	var ts := int(cell * 0.5)
	var w := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
	draw_string(font, Vector2(c.x - w / 2, c.y - cell * 0.08), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, color)


func _draw_chest(tile: Dictionary, rect: Rect2, cell: float) -> void:
	# Сундук общественной казны
	var c := rect.get_center() + Vector2(0, -cell * 0.1)
	var w := cell * 0.34
	var h := cell * 0.24
	draw_rect(Rect2(c.x - w, c.y - h * 0.4, w * 2, h * 1.2), Color("#97753f"))
	draw_rect(Rect2(c.x - w, c.y - h * 0.8, w * 2, h * 0.5), Color("#b08d4f"))
	draw_rect(Rect2(c.x - cell * 0.04, c.y - h * 0.6, cell * 0.08, h * 0.8), Color("#ffd43b"))


func _draw_rail(font: Font, tile: Dictionary, rect: Rect2, cell: float) -> void:
	# Паровозик
	var c := rect.get_center() + Vector2(0, -cell * 0.08)
	var s := cell * 0.4
	draw_rect(Rect2(c.x - s * 0.7, c.y - s * 0.3, s * 1.2, s * 0.5), Color("#343a40"))  # корпус
	draw_rect(Rect2(c.x - s * 0.15, c.y - s * 0.62, s * 0.5, s * 0.4), Color("#343a40")) # кабина
	draw_rect(Rect2(c.x + s * 0.35, c.y - s * 0.52, s * 0.22, s * 0.3), Color("#212529")) # труба
	for i in 3:
		draw_circle(c + Vector2(-s * 0.45 + i * s * 0.45, s * 0.28), s * 0.14, Color("#212529"))


func _draw_util(font: Font, tile: Dictionary, rect: Rect2, cell: float) -> void:
	var c := rect.get_center() + Vector2(0, -cell * 0.1)
	if "лектро" in tile.name or "еактор" in tile.name or "Каваи" in tile.name or "Генератор" in tile.name:
		# Молния
		var pts := PackedVector2Array([
			c + Vector2(0, -cell * 0.3), c + Vector2(-cell * 0.14, cell * 0.02),
			c + Vector2(0, cell * 0.02), c + Vector2(-cell * 0.06, cell * 0.3),
			c + Vector2(cell * 0.16, -cell * 0.06), c + Vector2(cell * 0.03, -cell * 0.06),
		])
		draw_colored_polygon(pts, Color("#fab005"))
	else:
		# Кран/капля
		draw_circle(c + Vector2(0, cell * 0.05), cell * 0.16, Color("#339af0"))
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-cell * 0.13, -cell * 0.02), c + Vector2(cell * 0.13, -cell * 0.02),
			c + Vector2(0, -cell * 0.3)]), Color("#339af0"))


func _draw_tile_label(font: Font, tile: Dictionary, rect: Rect2, cell: float) -> void:
	var ts := int(cell * 0.135)
	var col := Color("#1a1a1e")
	var c := rect.get_center()
	# многословные названия в две строки
	var words: PackedStringArray = tile.name.split(" ")
	var lines: Array[String] = []
	if words.size() > 1 and tile.name.length() > 9:
		var mid := words.size() / 2
		lines.append(" ".join(words.slice(0, mid)))
		lines.append(" ".join(words.slice(mid)))
	else:
		lines.append(tile.name)
	var y0 := c.y + cell * 0.02 - (lines.size() - 1) * ts * 0.6
	for line in lines:
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		var t2 := ts
		while w > rect.size.x - 6 and t2 > 6:
			t2 -= 1
			w = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, t2).x
		draw_string(font, Vector2(c.x - w / 2, y0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, t2, col)
		y0 += ts * 1.18
	if tile.get("price", 0) > 0:
		var price := str(tile.price)
		var pw := font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		draw_string(font, Vector2(c.x - pw / 2, rect.end.y - cell * 0.16), price, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color("#6b5e2e"))


# --- Персонаж-свинья (фишка игрока) ----------------------------------------

func _draw_token(c: Vector2, r: float, color: Color, active: bool) -> void:
	# тень
	draw_circle(c + Vector2(r * 0.12, r * 0.3), r * 0.85, Color(0, 0, 0, 0.25))
	# тело
	var pink := Color("#f8a89a")
	var pink_dark := Color("#e28074")
	draw_circle(c, r, pink_dark)
	draw_circle(c + Vector2(0, -r * 0.08), r * 0.9, pink)
	# уши
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.75, -r * 0.55), c + Vector2(-r * 0.95, -r * 1.05), c + Vector2(-r * 0.4, -r * 0.8)]), pink_dark)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.75, -r * 0.55), c + Vector2(r * 0.95, -r * 1.05), c + Vector2(r * 0.4, -r * 0.8)]), pink_dark)
	# цилиндр
	var hw := r * 0.52
	var top := c.y - r * 1.85
	draw_rect(Rect2(c.x - hw, top, hw * 2, r * 0.95), Color("#26262e"))
	draw_rect(Rect2(c.x - hw, c.y - r * 1.18, hw * 2, r * 0.28), color)  # лента в цвет игрока
	draw_ellipse(Rect2(c.x - hw * 1.35, c.y - r * 1.1, hw * 2.7, r * 0.34), Color("#1a1a20"))
	draw_ellipse(Rect2(c.x - hw, top - r * 0.1, hw * 2, r * 0.22), Color("#4a4a56"))
	# глаза
	for sx in [-1.0, 1.0]:
		draw_circle(c + Vector2(sx * r * 0.36, -r * 0.28), r * 0.13, Color("#1a1a20"))
		draw_circle(c + Vector2(sx * r * 0.32, -r * 0.33), r * 0.05, Color.WHITE)
	# пятачок
	draw_ellipse(Rect2(c.x - r * 0.33, c.y - r * 0.06, r * 0.66, r * 0.44), Color("#fcbeb2"))
	draw_ellipse(Rect2(c.x - r * 0.33, c.y - r * 0.06, r * 0.66, r * 0.44), Color("#c46058"), false)
	draw_ellipse(Rect2(c.x - r * 0.2, c.y + r * 0.06, r * 0.12, r * 0.2), Color("#c46058"))
	draw_ellipse(Rect2(c.x + r * 0.08, c.y + r * 0.06, r * 0.12, r * 0.2), Color("#c46058"))
	# усы
	draw_ellipse(Rect2(c.x - r * 0.72, c.y + r * 0.3, r * 0.55, r * 0.22), Color("#f5f5fa"))
	draw_ellipse(Rect2(c.x + r * 0.17, c.y + r * 0.3, r * 0.55, r * 0.22), Color("#f5f5fa"))
	# бабочка
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.5, r * 0.62), c + Vector2(-r * 0.12, r * 0.48), c + Vector2(-r * 0.12, r * 0.76)]), Color("#1c1c22"))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.5, r * 0.62), c + Vector2(r * 0.12, r * 0.48), c + Vector2(r * 0.12, r * 0.76)]), Color("#1c1c22"))
	draw_circle(c + Vector2(0, r * 0.62), r * 0.1, Color("#34343e"))
	if active:
		draw_arc(c, r * 1.12, 0, TAU, 24, color, 3.0)


func draw_ellipse(rect: Rect2, color: Color, filled := true, width := 1.0) -> void:
	# аппроксимация эллипса полигоном
	var cc := rect.get_center()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(cc + Vector2(cos(a) * rect.size.x / 2.0, sin(a) * rect.size.y / 2.0))
	if filled:
		draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		draw_polyline(pts, color, width)
