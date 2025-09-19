# LeaderboardScene.gd
extends Control

signal scene_closed

# Ссылки на узлы сцены
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var scroll_container = $MarginContainer/VBoxContainer/ScrollContainer
@onready var leaderboard_list = $MarginContainer/VBoxContainer/ScrollContainer/LeaderboardList
@onready var vbox_container = $MarginContainer/VBoxContainer

# Локализация
var current_language = "en"
var translations = {
	"en": {
		"title": "Leaderboard",
		"rank": "Rank",
		"player": "Player",
		"score": "Score",
		"date": "Date",
		"close": "Close",
		"no_data": "No leaderboard data",
		"you": "You"
	},
	"ru": {
		"title": "Таблица лидеров",
		"rank": "Место",
		"player": "Игрок",
		"score": "Очки",
		"date": "Дата",
		"close": "Закрыть",
		"no_data": "Нет данных о рекордах",
		"you": "Вы"
	},
	"es": {
		"title": "Tabla de clasificación",
		"rank": "Posición",
		"player": "Jugador",
		"score": "Puntuación",
		"date": "Fecha",
		"close": "Cerrar",
		"no_data": "No hay datos de clasificación",
		"you": "Tú"
	},
	"fr": {
		"title": "Classement",
		"rank": "Rang",
		"player": "Joueur",
		"score": "Score",
		"date": "Date",
		"close": "Fermer",
		"no_data": "Aucune donnée de classement",
		"you": "Vous"
	},
	"de": {
		"title": "Bestenliste",
		"rank": "Rang",
		"player": "Spieler",
		"score": "Punkte",
		"date": "Datum",
		"close": "Schließen",
		"no_data": "Keine Bestenlistendaten",
		"you": "Du"
	}
}

func _ready():
	print("[DEBUG] LeaderboardScene начал инициализацию")
	
	# Загружаем настройки языка
	load_language_settings()
	
	# Устанавливаем размер окна
	self.size = Vector2(900, 600)
	
	# Настраиваем темный фон в киберпанк стиле
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.2, 0.8, 1.0)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	add_theme_stylebox_override("panel", panel_style)
	
	# Настраиваем элементы интерфейса
	setup_ui()
	
	# Заполняем таблицу лидеров
	populate_leaderboard()
	
	# Центрируем диалог
	center_dialog()
	
	print("[DEBUG] LeaderboardScene инициализирован")

func center_dialog():
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(viewport_size.x - size.x) / 2,
		(viewport_size.y - size.y) / 2
	)

func setup_ui():
	# Устанавливаем заголовок
	title_label.text = translate("title")
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Настраиваем ScrollContainer
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Добавляем фон для ScrollContainer
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	scroll_style.corner_radius_top_left = 5
	scroll_style.corner_radius_top_right = 5
	scroll_style.corner_radius_bottom_right = 5
	scroll_style.corner_radius_bottom_left = 5
	scroll_container.add_theme_stylebox_override("panel", scroll_style)
	
	# Создаем кнопку закрытия
	create_close_button()

func create_close_button():
	# Создаем контейнер для кнопки закрытия
	var close_button_container = HBoxContainer.new()
	close_button_container.name = "CloseButtonContainer"
	close_button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button_container.custom_minimum_size = Vector2(0, 60)
	
	# Добавляем контейнер в VBoxContainer ПЕРЕД ScrollContainer
	var scroll_index = vbox_container.get_child_count() - 1
	vbox_container.add_child(close_button_container)
	vbox_container.move_child(close_button_container, scroll_index)
	
	# Создаем кнопку закрытия
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = translate("close")
	close_button.custom_minimum_size = Vector2(120, 50)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Добавляем стиль для кнопки закрытия
	setup_cyberpunk_button(close_button)
	
	close_button_container.add_child(close_button)

func setup_cyberpunk_button(button: Button):
	# Стиль для нормального состояния
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.2, 0.8, 1.0)
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_right = 5
	normal_style.corner_radius_bottom_left = 5
	
	# Стиль для наведения
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	hover_style.border_color = Color(0.8, 0.2, 1.0)
	
	# Стиль для нажатия
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	pressed_style.border_color = Color(1.0, 0.5, 0.8)
	
	# Применяем стили
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Настройки текста
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(0.8, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.8, 0.2, 1.0))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.8))

func load_language_settings():
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK:
		current_language = config.get_value("ui", "language", "en")
		print("[DEBUG] Загружен язык: ", current_language)

func translate(key):
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	elif translations.has("en") and translations["en"].has(key):
		return translations["en"][key]
	else:
		return key

func _on_close_button_pressed():
	print("[DEBUG] Закрытие сцены таблицы лидеров")
	emit_signal("scene_closed")
	queue_free()

func populate_leaderboard():
	print("[DEBUG] Начало заполнения таблицы лидеров")
	
	if not leaderboard_list:
		print("[ERROR] Нет контейнера для списка лидеров!")
		return
	
	# Очищаем список
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	# Получаем данные таблицы лидеров
	var leaderboard_data = get_leaderboard_data()
	print("[DEBUG] Получено данных: ", leaderboard_data.size())
	
	if leaderboard_data.is_empty():
		print("[WARNING] Таблица лидеров пуста")
		show_empty_message()
		return
	
	print("[DEBUG] Найдено записей в таблице лидеров: ", leaderboard_data.size())
	
	# Создаем заголовок таблицы
	create_table_header()
	
	# Заполняем таблицу лидеров
	for i in range(leaderboard_data.size()):
		var entry = leaderboard_data[i]
		create_leaderboard_entry(i + 1, entry)
	
	print("[DEBUG] Добавлено записей в таблицу лидеров: ", leaderboard_data.size())

func create_table_header():
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 40)
	
	# Добавляем фон для заголовка
	var header_bg = ColorRect.new()
	header_bg.color = Color(0.25, 0.25, 0.3, 0.9)
	header_bg.size = Vector2(860, 40)
	header.add_child(header_bg)
	
	var rank_header = Label.new()
	rank_header.text = translate("rank")
	rank_header.custom_minimum_size = Vector2(80, 0)
	rank_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	rank_header.add_theme_font_size_override("font_size", 16)
	
	var name_header = Label.new()
	name_header.text = translate("player")
	name_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	name_header.add_theme_font_size_override("font_size", 16)
	
	var score_header = Label.new()
	score_header.text = translate("score")
	score_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	score_header.add_theme_font_size_override("font_size", 16)
	
	var date_header = Label.new()
	date_header.text = translate("date")
	date_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	date_header.add_theme_font_size_override("font_size", 16)
	
	header.add_child(rank_header)
	header.add_child(name_header)
	header.add_child(score_header)
	header.add_child(date_header)
	
	leaderboard_list.add_child(header)
	
	# Добавляем разделитель
	var separator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.2, 0.8, 1.0, 0.5))
	leaderboard_list.add_child(separator)

func get_leaderboard_data():
	# Здесь должна быть логика загрузки данных таблицы лидеров
	# Временно возвращаем тестовые данные
	var test_data = [
		{"player_name": "Player1", "score": 20480, "date": "12.05.2023"},
		{"player_name": "Player2", "score": 16384, "date": "10.05.2023"},
		{"player_name": translate("you"), "score": 10240, "date": "11.05.2023"},
		{"player_name": "Player3", "score": 8192, "date": "09.05.2023"},
		{"player_name": "Player4", "score": 4096, "date": "08.05.2023"},
		{"player_name": "Player5", "score": 2048, "date": "07.05.2023"},
		{"player_name": "Player6", "score": 1024, "date": "06.05.2023"},
		{"player_name": "Player7", "score": 512, "date": "05.05.2023"},
		{"player_name": "Player8", "score": 256, "date": "04.05.2023"},
		{"player_name": "Player9", "score": 128, "date": "03.05.2023"}
	]
	print("[DEBUG] Возвращаем тестовые данные: ", test_data)
	return test_data

func create_leaderboard_entry(rank, entry):
	print("[DEBUG] Создание записи: ", rank, " - ", entry)
	
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 50)
	
	# Добавляем фон для всей строки
	var item_bg = ColorRect.new()
	if rank % 2 == 0:
		item_bg.color = Color(0.1, 0.1, 0.12, 0.7)  # Темный фон для четных строк
	else:
		item_bg.color = Color(0.15, 0.15, 0.18, 0.7)  # Светлее для нечетных строк
	
	# Выделяем текущего игрока другим цветом
	if entry.player_name == translate("you"):
		item_bg.color = Color(0.3, 0.25, 0.1, 0.8)  # Золотистый оттенок для текущего игрока
	
	item_bg.size = Vector2(860, 50)
	item_container.add_child(item_bg)
	
	# Место
	var rank_label = Label.new()
	rank_label.text = str(rank)
	rank_label.custom_minimum_size = Vector2(80, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_color_override("font_color", Color.WHITE)
	rank_label.add_theme_font_size_override("font_size", 16)
	
	# Имя игрока
	var name_label = Label.new()
	name_label.text = entry.player_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 16)
	
	# Очки
	var score_label = Label.new()
	score_label.text = str(entry.score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_color_override("font_color", Color(1, 0.9, 0))  # Золотой цвет для очков
	score_label.add_theme_font_size_override("font_size", 16)
	
	# Дата
	var date_label = Label.new()
	date_label.text = entry.date
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	date_label.add_theme_font_size_override("font_size", 14)
	
	item_container.add_child(rank_label)
	item_container.add_child(name_label)
	item_container.add_child(score_label)
	item_container.add_child(date_label)
	
	leaderboard_list.add_child(item_container)
	
	# Добавляем разделитель между записями
	var separator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.3, 0.3, 0.3))
	leaderboard_list.add_child(separator)
	
	print("[DEBUG] Запись создана: ", rank, " - ", entry.player_name)

func show_empty_message():
	var empty_label = Label.new()
	empty_label.text = translate("no_data")
	empty_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Добавляем фон для сообщения о пустом списке
	var empty_bg = PanelContainer.new()
	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0.2, 0.2, 0.2, 0.7)
	empty_bg.add_theme_stylebox_override("panel", empty_style)
	empty_bg.custom_minimum_size = Vector2(600, 40)
	
	empty_bg.add_child(empty_label)
	leaderboard_list.add_child(empty_bg)

# Добавляем обработку клавиши Escape для закрытия
func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			_on_close_button_pressed()
