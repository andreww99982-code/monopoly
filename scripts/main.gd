extends Control
## Главный контроллер: стартовый экран с выбором игры -> игровое поле.
## Игровая логика повторяет официальные правила классической «Монополии»:
## 40 клеток (22 улицы 8 цветовых групп, 4 ж/д, 2 коммунальных предприятия,
## 3 «Шанс», 3 «Общественная казна», 2 налога, СТАРТ, Тюрьма, Бесплатная
## парковка, «Отправляйтесь в тюрьму»), дубли, зарплата за проход СТАРТа.

const BOARD_SIZE := 40
const START_BALANCE := 1500
const GO_SALARY := 200
const JAIL_INDEX := 10
const GO_TO_JAIL_INDEX := 30
const JAIL_FINE := 50
const MAX_DOUBLES := 3
const PLAYER_COLORS := [Color("#4dabf7"), Color("#ff6b8a"), Color("#ffd166"), Color("#8ce99a")]

# Типы клеток
const T_CORNER := 0   # угловые: СТАРТ, Тюрьма, Парковка, В тюрьму
const T_STREET := 1   # улица с цветовой группой
const T_RAIL := 2     # железная дорога
const T_UTIL := 3     # коммунальное предприятие
const T_CHANCE := 4   # Шанс
const T_CHEST := 5    # Общественная казна
const T_TAX := 6      # налог

# ---------------------------------------------------------------------------
# Темы: каждая игра задаёт палитру, центр поля, названия улиц и подписи.
# Классика — московские улицы как в русском издании; остальные — тематические.
# ---------------------------------------------------------------------------
const THEMES := {
	"classic": {
		"label": "Классика",
		"desc": "Оригинальные правила: московские улицы, тюрьма, налоги и аренда.",
		"currency": "₽",
		"start_name": "ВПЕРЁД",
		"jail_name": "ТЮРЬМА",
		"parking_name": "ПАРКОВКА",
		"goto_jail_name": "В ТЮРЬМУ",
		"chance_name": "ШАНС",
		"chest_name": "КАЗНА",
		"board_title": "МОНОПОЛИЯ",
		"board_subtitle": "КЛАССИЧЕСКОЕ ИЗДАНИЕ",
		"bg": Color("#0e3b26"),
		"panel": Color("#123a2a"),
		"accent": Color("#e03131"),
		"text": Color("#f4f8f5"),
		"muted": Color("#9ec3ae"),
		"center_a": Color("#cde6d5"),
		"center_b": Color("#eef7f0"),
		"streets": [
			"Житная ул.", "Нагатинская ул.",
			"Карамышевская наб.", "Рублёвское шоссе", "Тверская ул.",
			"Пушкинская ул.", "Пл. Маяковского", "Новинский бульвар",
			"1-я Парковая ул.", "ул. Щусева", "Ростовская наб.",
			"ул. Полянка", "Смоленская площадь", "Садовое кольцо",
			"Кутузовский пр.", "ул. Малая Бронная", "Никольская ул.",
			"ул. Арбат", "Крымский вал",
			"Страстной бульвар", "Патриаршие пруды"
		],
		"rails": ["Рижский вокзал", "Казанский вокзал", "Курский вокзал", "Ленинградский вокзал"],
		"utils": ["Электростанция", "Водоканал"],
		"taxes": ["Подоходный налог", "Налог на роскошь"],
	},
	"star_wars": {
		"label": "Звёздные Войны",
		"desc": "Галактическая торговля планетами: кредиты, гиперпривод и карцер Империи.",
		"currency": "кр.",
		"start_name": "ГИПЕРПРЫЖОК",
		"jail_name": "КАРЦЕР",
		"parking_name": "ДОК-СТОЯНКА",
		"goto_jail_name": "АРЕСТ",
		"chance_name": "СИЛА",
		"chest_name": "АРХИВ ДЖЕДАЕВ",
		"board_title": "ЗВЁЗДНЫЕ ВОЙНЫ",
		"board_subtitle": "ГАЛАКТИЧЕСКАЯ МОНОПОЛИЯ",
		"bg": Color("#05060e"),
		"panel": Color("#101530"),
		"accent": Color("#ffe81f"),
		"text": Color("#eef2ff"),
		"muted": Color("#7f8cc9"),
		"center_a": Color("#0a0f2e"),
		"center_b": Color("#1b2452"),
		"streets": [
			"Татуин", "Джакку",
			"Хот", "Дагоба", "Эндор",
			"Камино", "Скариф", "Мустафар",
			"Набу", "Кашиик", "Утапау",
			"Беспин", "Явин-4", "Малакор",
			"Джеонозис", "Фелуция", "Салукемай",
			"Мандалор", "Райлот",
			"Алдераан", "Корусант"
		],
		"rails": ["Звёздный разрушитель", "Тысячелетний сокол", "X-Крыло", "Раб-1"],
		"utils": ["Реактор Звезды Смерти", "Генератор щита"],
		"taxes": ["Имперский сбор", "Налог картеля Хаттов"],
	},
	"rick_and_morty": {
		"label": "Рик и Морти",
		"desc": "Межпространственные сделки: шмекли, портальная пушка и Цитадель Риков.",
		"currency": "шмк.",
		"start_name": "ПОРТАЛ",
		"jail_name": "ФЕД. ТЮРЬМА",
		"parking_name": "СТОЯНКА НЛО",
		"goto_jail_name": "ЗА РЕШЁТКУ",
		"chance_name": "ПОРТАЛ-ГАН",
		"chest_name": "ЯЩИК МИСИКСА",
		"board_title": "РИК И МОРТИ",
		"board_subtitle": "МЕЖПРОСТРАНСТВЕННАЯ МОНОПОЛИЯ",
		"bg": Color("#0d2b23"),
		"panel": Color("#10382d"),
		"accent": Color("#a6f750"),
		"text": Color("#eafff2"),
		"muted": Color("#7fd6a4"),
		"center_a": Color("#0a3b2e"),
		"center_b": Color("#0f5c40"),
		"streets": [
			"Гараж Рика", "Школа Морти",
			"Анатомический парк", "Планета Сквонч", "Измерение C-137",
			"Блипс-энд-Читс", "Гэзорпазорп", "Мир Крекулона",
			"Плутониевый городок", "Измерение Крематория", "Клуб Флиба",
			"Измерение Огурчика", "Межпространственный ТЦ", "Планета Тельца",
			"Мир Junkyard", "Планета Зигеров", "Крякомир",
			"Измерение Хэппи", "Мир без глаз",
			"Кинотеатр Багса", "Цитадель Риков"
		],
		"rails": ["Космолёт Рика", "Портальный экспресс", "Микровселенная-мобиль", "Мусорный шаттл"],
		"utils": ["Плутониевый реактор", "Сборщик микровселенных"],
		"taxes": ["Галактический налог", "Сбор Цитадели"],
	},
	"anime": {
		"label": "Аниме-клуб",
		"desc": "Сакура, фестивали и клубы: соберите все локации аниме-города.",
		"currency": "жет.",
		"start_name": "ШК. ВОРОТА",
		"jail_name": "КАРА",
		"parking_name": "КРЫША ШКОЛЫ",
		"goto_jail_name": "НАКАЗАНИЕ",
		"chance_name": "ФОРТУНА",
		"chest_name": "КЛУБНАЯ КАЗНА",
		"board_title": "АНИМЕ-КЛУБ",
		"board_subtitle": "САКУРА-МАНГА ЭДИШН",
		"bg": Color("#3d1836"),
		"panel": Color("#4a1f42"),
		"accent": Color("#ff8fb3"),
		"text": Color("#fff3f8"),
		"muted": Color("#e0a4c6"),
		"center_a": Color("#59284e"),
		"center_b": Color("#7c3a6d"),
		"streets": [
			"Кофейня «Сакура»", "Кондитерская «Данго»",
			"Отаку-магазин", "Клуб манги", "Аркада «Нео-Токио»",
			"Класс горничных", "Библиотека додзинси", "Клуб единоборств",
			"Аллея сакуры", "Пляжный фестиваль", "Онсэн «Лунный свет»",
			"Клуб идолов", "Летний фестиваль", "Кинотеатр аниме",
			"Храм лисицы", "Гора Осень", "Улица торийяки",
			"Неоновый квартал", "Кибер-рынок",
			"Сад хризантем", "Выпускной бал"
		],
		"rails": ["Линия Яманоте", "Синкансэн", "Монорельс бухты", "Ночной экспресс"],
		"utils": ["Электростанция «Каваи»", "Водяной храм"],
		"taxes": ["Клубный взнос", "Налог на гача"],
	},
}

const THEME_ORDER := ["classic", "star_wars", "rick_and_morty", "anime"]

# Цветовые группы улиц (8 штук) и размеры групп
const GROUP_COLORS := [
	Color("#7b4a2d"), Color("#8bd3e6"), Color("#d63384"), Color("#f59f00"),
	Color("#e03131"), Color("#ffd43b"), Color("#2f9e44"), Color("#1971c2"),
]
const GROUP_SIZES := [2, 3, 3, 3, 3, 3, 2, 2]
# Цены как в классической монополии (по группам от дешёвых к дорогим)
const STREET_PRICES := [
	[60, 60], [100, 100, 120], [140, 140, 160], [180, 180, 200],
	[220, 220, 240], [260, 260, 280], [300, 300, 320], [350, 400],
]
const RAIL_PRICE := 200
const RAIL_RENTS := [25, 50, 100, 200]  # по числу ж/д у владельца
const UTIL_PRICE := 150
const TAX_AMOUNTS := [200, 100]  # подоходный, роскошь

var current_theme_id := "classic"
var players: Array[Dictionary] = []
var tiles: Array[Dictionary] = []
var chance_deck: Array = []
var chest_deck: Array = []
var current_player := 0
var round_number := 1
var dice := [1, 1]
var rng := RandomNumberGenerator.new()
var awaiting_human := false  # ждём решения человека о покупке

var menu_layer: Control
var game_layer: Control
var board_view: Control
var status_label: Label
var players_label: Label
var roll_button: Button
var buy_button: Button
var end_button: Button
var log_label: RichTextLabel
var dice_view: Control


func _ready() -> void:
	rng.randomize()
	_build_menu()

# ---------------------------------------------------------------------------
# ТЕМА / ДОСКА
# ---------------------------------------------------------------------------

func _theme() -> Dictionary:
	return THEMES[current_theme_id]

func _format_money(amount: int) -> String:
	return "%d %s" % [amount, _theme().currency]

func _street_name_index(group: int, slot: int) -> int:
	var base := 0
	for i in group:
		base += GROUP_SIZES[i]
	return base + slot

func _create_board() -> void:
	tiles.clear()
	var theme: Dictionary = _theme()
	var streets: Array = theme.streets
	var rails: Array = theme.rails
	var utils: Array = theme.utils
	var taxes: Array = theme.taxes

	# Структура классического поля 40 клеток, как в оригинале.
	var layout := [
		{"t": T_CORNER},                                            # 0 ВПЕРЁД
		{"t": T_STREET, "g": 0, "s": 0},                            # 1
		{"t": T_CHEST},                                             # 2
		{"t": T_STREET, "g": 0, "s": 1},                            # 3
		{"t": T_TAX, "n": 0},                                       # 4 подоходный
		{"t": T_RAIL, "n": 0},                                      # 5
		{"t": T_STREET, "g": 1, "s": 0},                            # 6
		{"t": T_CHANCE},                                            # 7
		{"t": T_STREET, "g": 1, "s": 1},                            # 8
		{"t": T_STREET, "g": 1, "s": 2},                            # 9
		{"t": T_CORNER},                                            # 10 ТЮРЬМА
		{"t": T_STREET, "g": 2, "s": 0},                            # 11
		{"t": T_UTIL, "n": 0},                                      # 12 электростанция
		{"t": T_STREET, "g": 2, "s": 1},                            # 13
		{"t": T_STREET, "g": 2, "s": 2},                            # 14
		{"t": T_RAIL, "n": 1},                                      # 15
		{"t": T_STREET, "g": 3, "s": 0},                            # 16
		{"t": T_CHEST},                                             # 17
		{"t": T_STREET, "g": 3, "s": 1},                            # 18
		{"t": T_STREET, "g": 3, "s": 2},                            # 19
		{"t": T_CORNER},                                            # 20 ПАРКОВКА
		{"t": T_STREET, "g": 4, "s": 0},                            # 21
		{"t": T_CHANCE},                                            # 22
		{"t": T_STREET, "g": 4, "s": 1},                            # 23
		{"t": T_STREET, "g": 4, "s": 2},                            # 24
		{"t": T_RAIL, "n": 2},                                      # 25
		{"t": T_STREET, "g": 5, "s": 0},                            # 26
		{"t": T_STREET, "g": 5, "s": 1},                            # 27
		{"t": T_UTIL, "n": 1},                                      # 28 водоканал
		{"t": T_STREET, "g": 5, "s": 2},                            # 29
		{"t": T_CORNER},                                            # 30 В ТЮРЬМУ
		{"t": T_STREET, "g": 6, "s": 0},                            # 31
		{"t": T_STREET, "g": 6, "s": 1},                            # 32
		{"t": T_CHEST},                                             # 33
		{"t": T_STREET, "g": 6, "s": 2},                            # 34
		{"t": T_RAIL, "n": 3},                                      # 35
		{"t": T_CHANCE},                                            # 36
		{"t": T_STREET, "g": 7, "s": 0},                            # 37
		{"t": T_TAX, "n": 1},                                       # 38 роскошь
		{"t": T_STREET, "g": 7, "s": 1},                            # 39
	]

	for spec in layout:
		match spec.t:
			T_CORNER:
				var idx := tiles.size()
				var tile_name: String = theme.start_name
				if idx == JAIL_INDEX:
					tile_name = theme.jail_name
				elif idx == 20:
					tile_name = theme.parking_name
				elif idx == GO_TO_JAIL_INDEX:
					tile_name = theme.goto_jail_name
				tiles.append({"type": T_CORNER, "name": tile_name})
			T_STREET:
				var g: int = spec.g
				var s: int = spec.s
				tiles.append({
					"type": T_STREET,
					"name": streets[_street_name_index(g, s)],
					"group": g,
					"price": STREET_PRICES[g][s],
					"rent": maxi(2, STREET_PRICES[g][s] / 10),
					"owner": -1,
				})
			T_RAIL:
				tiles.append({"type": T_RAIL, "name": rails[spec.n], "price": RAIL_PRICE, "rent": 25, "owner": -1})
			T_UTIL:
				tiles.append({"type": T_UTIL, "name": utils[spec.n], "price": UTIL_PRICE, "rent": 0, "owner": -1})
			T_CHANCE:
				tiles.append({"type": T_CHANCE, "name": theme.chance_name})
			T_CHEST:
				tiles.append({"type": T_CHEST, "name": theme.chest_name})
			T_TAX:
				tiles.append({"type": T_TAX, "name": taxes[spec.n], "tax": TAX_AMOUNTS[spec.n]})

func _build_decks() -> void:
	# Колода по мотивам оригинальных карточек
	chance_deck = [
		{"text": "Аванс: пройдите на СТАРТ и получите %s." % _format_money(GO_SALARY), "kind": "go_start"},
		{"text": "Банк выплачивает дивиденды: +%s." % _format_money(50), "kind": "money", "v": 50},
		{"text": "Штраф за быструю езду: -%s." % _format_money(15), "kind": "money", "v": -15},
		{"text": "Отправляйтесь в тюрьму!", "kind": "jail"},
		{"text": "Отступите на 3 клетки назад.", "kind": "back", "v": 3},
		{"text": "Вы выиграли конкурс красоты: +%s." % _format_money(10), "kind": "money", "v": 10},
		{"text": "Ремонт улиц: -%s." % _format_money(40), "kind": "money", "v": -40},
		{"text": "Идите на ближайшую ж/д станцию.", "kind": "nearest_rail"},
	]
	chest_deck = [
		{"text": "Наследство: +%s." % _format_money(100), "kind": "money", "v": 100},
		{"text": "Возврат налога: +%s." % _format_money(20), "kind": "money", "v": 20},
		{"text": "Оплатите лечение: -%s." % _format_money(50), "kind": "money", "v": -50},
		{"text": "Праздничный бонус: +%s." % _format_money(25), "kind": "money", "v": 25},
		{"text": "Страховая выплата: +%s." % _format_money(75), "kind": "money", "v": 75},
		{"text": "Отправляйтесь в тюрьму!", "kind": "jail"},
	]
	chance_deck.shuffle()
	chest_deck.shuffle()

func _draw_card(deck_name: String) -> Dictionary:
	var deck: Array = chance_deck if deck_name == "chance" else chest_deck
	var card: Dictionary = deck.pop_front()
	deck.push_back(card)
	return card

# ---------------------------------------------------------------------------
# СТАРТОВЫЙ ЭКРАН
# ---------------------------------------------------------------------------

func _build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)

	var bg := ColorRect.new()
	bg.color = Color("#0b1020")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(bg)

	var grad := TextureRect.new()
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.texture = _make_vertical_gradient(Color("#101a36"), Color("#0b1020"))
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	menu_layer.add_child(grad)

	var logo := Label.new()
	logo.text = "МОНОПОЛИЯ"
	logo.position = Vector2(0, 46)
	logo.size = Vector2(1280, 90)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 84)
	logo.add_theme_color_override("font_color", Color("#ffffff"))
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 6)
	menu_layer.add_child(logo)

	var logo_bar := ColorRect.new()
	logo_bar.color = Color("#e03131")
	logo_bar.position = Vector2(440, 148)
	logo_bar.size = Vector2(400, 8)
	menu_layer.add_child(logo_bar)

	var subtitle := Label.new()
	subtitle.text = "Выберите игру — у каждой своё поле, валюта и атмосфера"
	subtitle.position = Vector2(0, 172)
	subtitle.size = Vector2(1280, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("#9fb2d8"))
	menu_layer.add_child(subtitle)

	var card_w := 290.0
	var card_h := 340.0
	var gap := 24.0
	var total := card_w * 4 + gap * 3
	var x0 := (1280.0 - total) / 2.0
	for i in THEME_ORDER.size():
		var tid: String = THEME_ORDER[i]
		var theme: Dictionary = THEMES[tid]
		var card := _make_theme_card(theme, tid)
		card.position = Vector2(x0 + i * (card_w + gap), 226)
		card.size = Vector2(card_w, card_h)
		menu_layer.add_child(card)

	var hint := Label.new()
	hint.text = "Вы и двое ботов • Поле 40 клеток • Классические правила Монополии"
	hint.position = Vector2(0, 590)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("#5f7197"))
	menu_layer.add_child(hint)

func _make_theme_card(theme: Dictionary, theme_id: String) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = theme.panel
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.border_color = theme.accent
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card.add_child(vb)

	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(0, 150)
	var psb := StyleBoxFlat.new()
	psb.bg_color = theme.center_a
	psb.corner_radius_top_left = 18
	psb.corner_radius_top_right = 18
	preview.add_theme_stylebox_override("panel", psb)
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	preview.add_child(pv)
	var pl := Label.new()
	pl.text = theme.board_title
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.add_theme_font_size_override("font_size", 26)
	pl.add_theme_color_override("font_color", theme.text)
	pv.add_child(pl)
	# полоска цветовых групп как на рамке поля
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 3)
	for gc in GROUP_COLORS:
		var chip := ColorRect.new()
		chip.color = gc
		chip.custom_minimum_size = Vector2(22, 10)
		strip.add_child(chip)
	pv.add_child(strip)
	vb.add_child(preview)

	var title := Label.new()
	title.text = theme.label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", theme.text)
	vb.add_child(title)

	var desc := Label.new()
	desc.text = theme.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 66)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", theme.muted)
	vb.add_child(desc)

	var play := Button.new()
	play.text = "ИГРАТЬ"
	play.custom_minimum_size = Vector2(0, 46)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = theme.accent
	bsb.corner_radius_top_left = 12
	bsb.corner_radius_top_right = 12
	bsb.corner_radius_bottom_left = 12
	bsb.corner_radius_bottom_right = 12
	play.add_theme_stylebox_override("normal", bsb)
	var bsb_h: StyleBoxFlat = bsb.duplicate()
	bsb_h.bg_color = theme.accent.lightened(0.15)
	play.add_theme_stylebox_override("hover", bsb_h)
	play.add_theme_color_override("font_color", Color("#ffffff"))
	play.add_theme_font_size_override("font_size", 18)
	play.pressed.connect(_start_game.bind(theme_id))
	vb.add_child(play)
	return card

func _make_vertical_gradient(top: Color, bottom: Color) -> Texture2D:
	var img := Image.create(4, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		var c := top.lerp(bottom, y / 127.0)
		for x in 4:
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------------------
# ЗАПУСК ИГРЫ
# ---------------------------------------------------------------------------

func _start_game(theme_id: String) -> void:
	current_theme_id = theme_id
	_create_board()
	_build_decks()
	_create_players()
	current_player = 0
	round_number = 1
	dice = [1, 1]
	awaiting_human = false
	if menu_layer:
		menu_layer.queue_free()
		menu_layer = null
	_build_game_ui()
	_add_log("Игра «%s» началась! Ваш ход — бросайте кубики." % _theme().label)
	_refresh_interface()

func _create_players() -> void:
	players = [
		{"name": "Вы", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": false,
			"properties": [], "in_jail": false, "jail_turns": 0, "doubles": 0},
		{"name": "Бот Алиса", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": true,
			"properties": [], "in_jail": false, "jail_turns": 0, "doubles": 0},
		{"name": "Бот Борис", "balance": START_BALANCE, "position": 0, "bankrupt": false, "ai": true,
			"properties": [], "in_jail": false, "jail_turns": 0, "doubles": 0},
	]

func _build_game_ui() -> void:
	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_layer)
	var theme: Dictionary = _theme()

	var background := ColorRect.new()
	background.color = theme.bg
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(background)

	# Верхняя плашка в стиле логотипа MONOPOLY
	var bar := Panel.new()
	bar.position = Vector2(24, 16)
	bar.size = Vector2(560, 64)
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = theme.accent
	bar_sb.corner_radius_top_left = 10
	bar_sb.corner_radius_top_right = 10
	bar_sb.corner_radius_bottom_left = 10
	bar_sb.corner_radius_bottom_right = 10
	bar_sb.border_color = Color(1, 1, 1, 0.85)
	bar_sb.set_border_width_all(3)
	bar.add_theme_stylebox_override("panel", bar_sb)
	game_layer.add_child(bar)

	var title := Label.new()
	title.text = theme.board_title
	title.position = Vector2(0, 8)
	title.size = Vector2(560, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	bar.add_child(title)

	var back := Button.new()
	back.text = "← МЕНЮ"
	back.position = Vector2(1140, 26)
	back.size = Vector2(116, 44)
	back.pressed.connect(_back_to_menu)
	game_layer.add_child(back)

	# Поле — квадратная доска слева
	board_view = preload("res://scripts/board_view.gd").new()
	board_view.position = Vector2(16, 92)
	board_view.size = Vector2(616, 616)
	board_view.board_theme = theme
	board_view.tiles = tiles
	board_view.players = players
	board_view.player_colors = PLAYER_COLORS
	game_layer.add_child(board_view)

	# Боковая панель
	var side := Panel.new()
	side.position = Vector2(648, 92)
	side.size = Vector2(616, 616)
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = theme.panel
	side_style.corner_radius_top_left = 18
	side_style.corner_radius_top_right = 18
	side_style.corner_radius_bottom_left = 18
	side_style.corner_radius_bottom_right = 18
	side.add_theme_stylebox_override("panel", side_style)
	game_layer.add_child(side)

	status_label = Label.new()
	status_label.position = Vector2(24, 18)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", theme.text)
	side.add_child(status_label)

	# Рисованные кубики
	dice_view = preload("res://scripts/dice_view.gd").new()
	dice_view.position = Vector2(460, 14)
	dice_view.size = Vector2(132, 62)
	dice_view.accent = theme.accent
	side.add_child(dice_view)

	players_label = Label.new()
	players_label.position = Vector2(24, 92)
	players_label.size = Vector2(568, 120)
	players_label.add_theme_font_size_override("font_size", 17)
	players_label.add_theme_color_override("font_color", theme.muted)
	side.add_child(players_label)

	roll_button = Button.new()
	roll_button.text = "БРОСИТЬ КУБИКИ  [ПРОБЕЛ]"
	roll_button.position = Vector2(24, 226)
	roll_button.size = Vector2(280, 52)
	roll_button.add_theme_font_size_override("font_size", 16)
	var roll_sb := StyleBoxFlat.new()
	roll_sb.bg_color = theme.accent
	roll_sb.corner_radius_top_left = 12
	roll_sb.corner_radius_top_right = 12
	roll_sb.corner_radius_bottom_left = 12
	roll_sb.corner_radius_bottom_right = 12
	roll_button.add_theme_stylebox_override("normal", roll_sb)
	roll_button.add_theme_color_override("font_color", Color("#ffffff"))
	roll_button.pressed.connect(_on_roll_pressed)
	side.add_child(roll_button)

	buy_button = Button.new()
	buy_button.text = "КУПИТЬ"
	buy_button.position = Vector2(316, 226)
	buy_button.size = Vector2(136, 52)
	buy_button.disabled = true
	buy_button.pressed.connect(_on_buy_pressed)
	side.add_child(buy_button)

	end_button = Button.new()
	end_button.text = "НЕ ПОКУПАТЬ"
	end_button.position = Vector2(464, 226)
	end_button.size = Vector2(128, 52)
	end_button.disabled = true
	end_button.pressed.connect(_on_end_turn_pressed)
	side.add_child(end_button)

	var save_button := Button.new()
	save_button.text = "СОХРАНИТЬ ИГРУ"
	save_button.position = Vector2(24, 288)
	save_button.size = Vector2(280, 36)
	save_button.pressed.connect(_save_game)
	side.add_child(save_button)

	log_label = RichTextLabel.new()
	log_label.position = Vector2(24, 336)
	log_label.size = Vector2(568, 258)
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.add_theme_font_size_override("normal_font_size", 15)
	log_label.add_theme_color_override("default_color", theme.text)
	var log_sb := StyleBoxFlat.new()
	log_sb.bg_color = theme.bg.darkened(0.35)
	log_sb.corner_radius_top_left = 10
	log_sb.corner_radius_top_right = 10
	log_sb.corner_radius_bottom_left = 10
	log_sb.corner_radius_bottom_right = 10
	log_label.add_theme_stylebox_override("normal", log_sb)
	side.add_child(log_label)

func _back_to_menu() -> void:
	if game_layer:
		game_layer.queue_free()
		game_layer = null
	_build_menu()

# ---------------------------------------------------------------------------
# ИГРОВОЙ ХОД
# ---------------------------------------------------------------------------

func _unhandled_key_input(event: InputEvent) -> void:
	if game_layer and event.is_action_pressed("roll_dice") and not roll_button.disabled:
		_on_roll_pressed()

func _on_roll_pressed() -> void:
	if _game_over():
		return
	var player: Dictionary = players[current_player]
	if player.bankrupt:
		_end_turn()
		_refresh_interface()
		_maybe_ai_turn()
		return

	if player.in_jail:
		var d1 := rng.randi_range(1, 6)
		var d2 := rng.randi_range(1, 6)
		dice = [d1, d2]
		if d1 == d2:
			player.in_jail = false
			player.jail_turns = 0
			_add_log("%s выкинул дубль и выходит из тюрьмы!" % player.name)
			_move_player(player, d1 + d2)
			after_move(player, false)
		else:
			player.jail_turns += 1
			if player.jail_turns >= 3:
				player.in_jail = false
				player.jail_turns = 0
				_pay_bank(player, JAIL_FINE)
				_add_log("%s заплатил штраф %s и вышел из тюрьмы." % [player.name, _format_money(JAIL_FINE)])
				_move_player(player, d1 + d2)
				after_move(player, false)
			else:
				_add_log("%s в тюрьме: дубля нет (попытка %d/3)." % [player.name, player.jail_turns])
				_end_turn()
		_refresh_interface()
		_maybe_ai_turn()
		return

	var d1 := rng.randi_range(1, 6)
	var d2 := rng.randi_range(1, 6)
	dice = [d1, d2]
	var is_double: bool = d1 == d2
	if is_double:
		player.doubles += 1
		if player.doubles >= MAX_DOUBLES:
			_add_log("[color=#ff8787]%s выкинул третий дубль подряд — в тюрьму![/color]" % player.name)
			_send_to_jail(player)
			_end_turn()
			_refresh_interface()
			_maybe_ai_turn()
			return
	else:
		player.doubles = 0

	_add_log("%s бросил %d + %d = %d%s." % [player.name, d1, d2, d1 + d2, " (дубль!)" if is_double else ""])
	_move_player(player, d1 + d2)
	after_move(player, is_double)
	_refresh_interface()
	_maybe_ai_turn()

func _move_player(player: Dictionary, steps: int) -> void:
	var old_position: int = player.position
	player.position = (old_position + steps) % BOARD_SIZE
	if player.position < old_position:
		player.balance += GO_SALARY
		_add_log("%s прошёл СТАРТ и получил %s." % [player.name, _format_money(GO_SALARY)])
	_add_log("%s попал на «%s»." % [player.name, tiles[player.position].name])

func after_move(player: Dictionary, rolled_double: bool) -> void:
	var tile: Dictionary = tiles[player.position]
	var extra_turn := rolled_double
	match tile.type:
		T_STREET, T_RAIL, T_UTIL:
			if tile.owner == -1:
				if player.ai:
					if player.balance - tile.price >= 80:
						_purchase(player)
				else:
					awaiting_human = true
					_add_log("Клетка свободна (%s). Купить?" % _format_money(tile.price))
			elif tile.owner != players.find(player):
				_pay_rent(player, tile)
		T_TAX:
			_pay_bank(player, tile.tax)
			_add_log("%s заплатил налог «%s»: %s." % [player.name, tile.name, _format_money(tile.tax)])
		T_CHANCE:
			_apply_card(player, _draw_card("chance"))
		T_CHEST:
			_apply_card(player, _draw_card("chest"))
		T_CORNER:
			if player.position == GO_TO_JAIL_INDEX:
				_send_to_jail(player)
				extra_turn = false
	if player.bankrupt or player.in_jail:
		extra_turn = false
	if extra_turn:
		_add_log("%s бросает ещё раз за дубль." % player.name)
		if player.ai:
			await get_tree().create_timer(0.5).timeout
			_on_roll_pressed()
		return
	_end_turn()

func _pay_rent(player: Dictionary, tile: Dictionary) -> void:
	var owner: Dictionary = players[tile.owner]
	var amount: int = tile.rent
	if tile.type == T_RAIL:
		var count := 0
		for t in tiles:
			if t.get("type") == T_RAIL and t.get("owner", -1) == tile.owner:
				count += 1
		amount = RAIL_RENTS[clampi(count - 1, 0, 3)]
	elif tile.type == T_UTIL:
		var count := 0
		for t in tiles:
			if t.get("type") == T_UTIL and t.get("owner", -1) == tile.owner:
				count += 1
		amount = (dice[0] + dice[1]) * (10 if count == 2 else 4)
	elif tile.type == T_STREET and _has_monopoly(tile.owner, tile.group):
		amount = tile.rent * 2
	amount = mini(amount, player.balance)
	player.balance -= amount
	owner.balance += amount
	_add_log("%s заплатил аренду %s игроку %s." % [player.name, _format_money(amount), owner.name])
	_check_bankrupt(player)

func _has_monopoly(owner_index: int, group: int) -> bool:
	for t in tiles:
		if t.get("type") == T_STREET and t.get("group") == group and t.get("owner", -1) != owner_index:
			return false
	return true

func _apply_card(player: Dictionary, card: Dictionary) -> void:
	_add_log("[i]%s[/i]" % card.text)
	match card.kind:
		"money":
			if card.v >= 0:
				player.balance += card.v
			else:
				_pay_bank(player, -card.v)
		"jail":
			_send_to_jail(player)
		"go_start":
			var old: int = player.position
			player.position = 0
			if old != 0:
				player.balance += GO_SALARY
		"back":
			player.position = (player.position - card.v + BOARD_SIZE) % BOARD_SIZE
			_add_log("%s отступил на «%s»." % [player.name, tiles[player.position].name])
			_resolve_property(player)
		"nearest_rail":
			var pos: int = player.position
			for i in range(1, BOARD_SIZE + 1):
				var idx := (pos + i) % BOARD_SIZE
				if tiles[idx].type == T_RAIL:
					if idx < pos:
						player.balance += GO_SALARY
					player.position = idx
					break
			_add_log("%s переместился на «%s»." % [player.name, tiles[player.position].name])
			_resolve_property(player)

func _resolve_property(player: Dictionary) -> void:
	# Разрешение клетки после перемещения карточкой
	var tile: Dictionary = tiles[player.position]
	match tile.type:
		T_STREET, T_RAIL, T_UTIL:
			if tile.owner == -1:
				if player.ai:
					if player.balance - tile.price >= 80:
						_purchase(player)
				else:
					awaiting_human = true
			elif tile.owner != players.find(player):
				_pay_rent(player, tile)
		T_TAX:
			_pay_bank(player, tile.tax)

func _send_to_jail(player: Dictionary) -> void:
	player.position = JAIL_INDEX
	player.in_jail = true
	player.jail_turns = 0
	player.doubles = 0
	_add_log("[color=#ff8787]%s отправляется в тюрьму.[/color]" % player.name)

func _pay_bank(player: Dictionary, amount: int) -> void:
	player.balance -= amount
	_check_bankrupt(player)

func _check_bankrupt(player: Dictionary) -> void:
	if player.balance <= 0 and not player.bankrupt:
		player.bankrupt = true
		player.balance = 0
		for owned_index in player.properties:
			tiles[owned_index].owner = -1
		player.properties.clear()
		_add_log("[color=#ff6b8a]%s обанкротился и выбывает![/color]" % player.name)
		if _game_over():
			var winners := players.filter(func(p): return not p.bankrupt)
			if winners.size() == 1:
				_add_log("[color=#ffd43b]ИГРА ОКОНЧЕНА! Победитель: %s с капиталом %s.[/color]" % [
					winners[0].name, _format_money(winners[0].balance)])

func _on_buy_pressed() -> void:
	if current_player == 0 and awaiting_human:
		_purchase(players[0])
		awaiting_human = false
		_refresh_interface()

func _on_end_turn_pressed() -> void:
	# Человек отказался покупать — клетка остаётся свободной
	if current_player == 0 and awaiting_human:
		awaiting_human = false
		_add_log("%s отказался от покупки." % players[0].name)
		_refresh_interface()

func _purchase(player: Dictionary) -> void:
	var tile: Dictionary = tiles[player.position]
	if tile.get("owner", -1) == -1 and tile.get("price", 0) > 0 and player.balance >= tile.price:
		player.balance -= tile.price
		tile.owner = players.find(player)
		player.properties.append(player.position)
		_add_log("[color=#8ce99a]%s купил «%s» за %s.[/color]" % [player.name, tile.name, _format_money(tile.price)])

func _end_turn() -> void:
	var attempts := 0
	while attempts < players.size():
		current_player = (current_player + 1) % players.size()
		if current_player == 0:
			round_number += 1
		if not players[current_player].bankrupt:
			return
		attempts += 1

func _maybe_ai_turn() -> void:
	if _game_over():
		_refresh_interface()
		return
	if players[current_player].ai:
		await get_tree().create_timer(0.55).timeout
		if game_layer and not _game_over() and players[current_player].ai:
			_on_roll_pressed()

func _game_over() -> bool:
	var alive := 0
	for player in players:
		if not player.bankrupt:
			alive += 1
	return alive <= 1

func _refresh_interface() -> void:
	if not game_layer:
		return
	var theme: Dictionary = _theme()
	var player: Dictionary = players[current_player]
	status_label.text = "Ход: %s   •   Раунд: %d" % [player.name, round_number]
	var lines := ""
	for index in players.size():
		var item: Dictionary = players[index]
		var marker := "> " if index == current_player else "   "
		var state := ""
		if item.bankrupt:
			state = "  [БАНКРОТ]"
		elif item.in_jail:
			state = "  [ТЮРЬМА]"
		lines += "%s%s: %s — %d влад., кл. %d%s\n" % [
			marker, item.name, _format_money(item.balance), item.properties.size(), item.position, state]
	players_label.text = lines
	var human: Dictionary = players[0]
	var current_tile: Dictionary = tiles[human.position]
	var can_buy: bool = (current_player == 0 and awaiting_human
		and current_tile.get("owner", -1) == -1 and current_tile.get("price", 0) > 0
		and human.balance >= current_tile.get("price", 0))
	buy_button.disabled = not can_buy
	end_button.disabled = not (current_player == 0 and awaiting_human)
	roll_button.disabled = (current_player != 0 or _game_over() or human.bankrupt)
	board_view.tiles = tiles
	board_view.players = players
	board_view.board_theme = theme
	board_view.current_player = current_player
	board_view.queue_redraw()
	if dice_view:
		dice_view.dice = dice
		dice_view.queue_redraw()

func _add_log(message: String) -> void:
	if log_label:
		log_label.append_text("• " + message + "\n")

func _save_game() -> void:
	var data := {
		"theme": current_theme_id,
		"round": round_number,
		"players": players,
		"tiles": tiles,
	}
	var file := FileAccess.open("user://monopoly_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	_add_log("[color=#8ce99a]Игра сохранена.[/color]")
