extends Control

const PLAYER_COLORS := [Color("#48a9ff"), Color("#ff6b8a"), Color("#ffd166"), Color("#8ce99a")]
var tiles: Array[Dictionary] = []
var players: Array[Dictionary] = []

func _draw() -> void:
	var center := size / 2.0
	var radius := min(size.x, size.y) * 0.37
	draw_circle(center, radius + 34.0, Color("#182945"))
	draw_circle(center, radius + 28.0, Color("#0d1728"))
	draw_circle(center, radius - 34.0, Color("#111e34"))
	draw_string(ThemeDB.fallback_font, center - Vector2(91, -8), "MONOPOLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#d8e7ff"))
	draw_string(ThemeDB.fallback_font, center - Vector2(56, -35), "ANDROID", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#6e8bb5"))
	for index in tiles.size():
		var angle := -PI / 2.0 + TAU * float(index) / tiles.size()
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		var tile_color := Color("#48a9ff") if index == 0 else Color("#243b60")
		if tiles[index].owner != -1:
			tile_color = [Color("#2d7dbd"), Color("#ae435f"), Color("#b48a31"), Color("#4e9968")][tiles[index].owner % 4]
		draw_circle(point, 25.0, Color("#07101e"))
		draw_circle(point, 21.0, tile_color)
		draw_string(ThemeDB.fallback_font, point - Vector2(6, -5), str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffffff"))
		draw_string(ThemeDB.fallback_font, point - Vector2(24, -38), tiles[index].name, HORIZONTAL_ALIGNMENT_CENTER, 48, 10, Color("#9eb2d1"))
	for index in players.size():
		var player: Dictionary = players[index]
		var angle := -PI / 2.0 + TAU * float(player.position) / tiles.size()
		var point := center + Vector2(cos(angle), sin(angle)) * radius + Vector2(-12 + (index % 2) * 24, -12 + (index / 2) * 24)
		draw_circle(point, 10.0, PLAYER_COLORS[index % PLAYER_COLORS.size()])
		draw_circle(point, 10.0, Color("#ffffff"), false, 2.0)
