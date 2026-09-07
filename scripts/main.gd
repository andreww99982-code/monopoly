extends Control

const BOARD_SIZE := 24
const START_BALANCE := 1500
const PLAYER_COLORS := [Color("#48a9ff"), Color("#ff6b8a"), Color("#ffd166"), Color("#8ce99a")]

var players: Array[Dictionary] = []
var tiles: Array[Dictionary] = []
var current_player := 0
var turn_number := 0
var rng := RandomNumberGenerator.new()
var board_view: Control
var status_label: Label
var players_label: Label
var roll_button: Button
var buy_button: Button
var log_label: RichTextLabel

func _ready() -> void:
	rng.randomize()
	_create_board()
	_create_players()
	_build_interface()
	_refresh_interface()

func _create_board() -> void:
	for index in BOARD_SIZE:
		if index == 0:
			tiles.append({"name": "СТАРТ", "price": 0, "rent": 0, "owner": -1})
		else:
			var price := 60 + index * 20
			tiles.append({"name": "Улица %d" % index, "price": price, "rent": price / 10, "owner": -1})

func _create_players() -> void:
	players = [
		{"name": "Вы", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": false, "properties": []},
		{"name": "Бот Алиса", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": true, "properties": []},
		{"name": "Бот Борис", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": true, "properties": []}
	]

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#090e1b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := Label.new()
	title.text = "МОНОПОЛИЯ"
	title.position = Vector2(38, 24)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "3D-ready game foundation • Godot 4 • Android"
	subtitle.position = Vector2(40, 66)
	subtitle.add_theme_color_override("font_color", Color("#8da2c0"))
	add_child(subtitle)

	board_view = preload("res://scripts/board_view.gd").new()
	board_view.position = Vector2(40, 115)
	board_view.size = Vector2(760, 555)
	board_view.tiles = tiles
	board_view.players = players
	add_child(board_view)

	var side := Panel.new()
	side.position = Vector2(840, 115)
	side.size = Vector2(400, 555)
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color("#121c30")
	side_style.corner_radius_top_left = 18
	side_style.corner_radius_top_right = 18
	side_style.corner_radius_bottom_left = 18
	side_style.corner_radius_bottom_right = 18
	side.add_theme_stylebox_override("panel", side_style)
	add_child(side)

	status_label = Label.new()
	status_label.position = Vector2(24, 22)
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.add_theme_color_override("font_color", Color("#f8fafc"))
	side.add_child(status_label)

	players_label = Label.new()
	players_label.position = Vector2(24, 66)
	players_label.size = Vector2(350, 115)
	players_label.add_theme_font_size_override("font_size", 17)
	players_label.add_theme_color_override("font_color", Color("#c9d6ea"))
	side.add_child(players_label)

	roll_button = Button.new()
	roll_button.text = "БРОСИТЬ КУБИКИ  [ПРОБЕЛ]"
	roll_button.position = Vector2(24, 202)
	roll_button.size = Vector2(352, 52)
	roll_button.add_theme_font_size_override("font_size", 16)
	roll_button.pressed.connect(_on_roll_pressed)
	side.add_child(roll_button)

	buy_button = Button.new()
	buy_button.text = "КУПИТЬ КЛЕТКУ"
	buy_button.position = Vector2(24, 264)
	buy_button.size = Vector2(170, 44)
	buy_button.disabled = true
	buy_button.pressed.connect(_on_buy_pressed)
	side.add_child(buy_button)

	var save_button := Button.new()
	save_button.text = "СОХРАНИТЬ"
	save_button.position = Vector2(206, 264)
	save_button.size = Vector2(170, 44)
	save_button.pressed.connect(_save_game)
	side.add_child(save_button)

	log_label = RichTextLabel.new()
	log_label.position = Vector2(24, 325)
	log_label.size = Vector2(352, 205)
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.add_theme_font_size_override("normal_font_size", 15)
	side.add_child(log_label)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		_on_roll_pressed()

func _on_roll_pressed() -> void:
	if players[current_player].bankrupt:
		_advance_turn()
		return
	var player: Dictionary = players[current_player]
	var steps := rng.randi_range(1, 6) + rng.randi_range(1, 6)
	var old_position: int = player.position
	player.position = (old_position + steps) % BOARD_SIZE
	if player.position < old_position:
		player.balance += 200
	_add_log("%s бросил %d и перешёл на «%s»." % [player.name, steps, tiles[player.position].name])
	_resolve_tile(player)
	turn_number += 1
	_advance_turn()
	_refresh_interface()
	if players[current_player].ai and not _game_over():
		await get_tree().create_timer(0.45).timeout
		_on_roll_pressed()

func _resolve_tile(player: Dictionary) -> void:
	var tile: Dictionary = tiles[player.position]
	if tile.price <= 0 or tile.owner == -1 or tile.owner == players.find(player):
		if tile.price > 0 and tile.owner == -1 and player.ai:
			if player.balance - tile.price >= int(player.balance * 0.3):
				_purchase(player)
		return
	var owner: Dictionary = players[tile.owner]
	var amount: int = mini(tile.rent, player.balance)
	player.balance -= amount
	owner.balance += amount
	_add_log("%s заплатил аренду %d игроку %s." % [player.name, amount, owner.name])
	if player.balance <= 0:
		player.bankrupt = true
		for owned_index in player.properties:
			tiles[owned_index].owner = -1
		_add_log("[color=#ff6b8a]%s обанкротился.[/color]" % player.name)

func _on_buy_pressed() -> void:
	var player: Dictionary = players[0]
	if current_player == 0:
		_purchase(player)
		_refresh_interface()

func _purchase(player: Dictionary) -> void:
	var tile: Dictionary = tiles[player.position]
	if tile.owner == -1 and tile.price > 0 and player.balance >= tile.price:
		player.balance -= tile.price
		tile.owner = players.find(player)
		player.properties.append(player.position)
		_add_log("%s купил «%s» за %d." % [player.name, tile.name, tile.price])

func _advance_turn() -> void:
	var attempts := 0
	while attempts < players.size():
		current_player = (current_player + 1) % players.size()
		if not players[current_player].bankrupt:
			return
		attempts += 1

func _game_over() -> bool:
	var alive := 0
	for player in players:
		if not player.bankrupt:
			alive += 1
	return alive <= 1

func _refresh_interface() -> void:
	var player: Dictionary = players[current_player]
	status_label.text = "Ход: %s\nРаунд: %d" % [player.name, turn_number + 1]
	var lines := ""
	for index in players.size():
		var item: Dictionary = players[index]
		var marker := "  ➜ " if index == current_player else "    "
		lines += "%s%s: $%d  •  клетка %d%s\n" % [marker, item.name, item.balance, item.position, "  БАНКРОТ" if item.bankrupt else ""]
	players_label.text = lines
	var human: Dictionary = players[0]
	var current_tile: Dictionary = tiles[human.position]
	buy_button.disabled = current_player != 0 or current_tile.owner != -1 or current_tile.price <= 0 or human.balance < current_tile.price
	board_view.tiles = tiles
	board_view.players = players
	board_view.queue_redraw()

func _add_log(message: String) -> void:
	if log_label:
		log_label.append_text("• " + message + "\n")

func _save_game() -> void:
	var data := {"turn": turn_number, "players": players, "tiles": tiles}
	var file := FileAccess.open("user://monopoly_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	_add_log("[color=#8ce99a]Игра сохранена.[/color]")
