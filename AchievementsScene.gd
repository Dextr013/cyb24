# AchievementsScene.gd
extends Control

signal achievements_closed

@onready var close_button = $VBoxContainer/CloseButton
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var achievements_list = $VBoxContainer/ScrollContainer/AchievementsList

var achievements_manager
var current_language = "en"

# Загрузка текстур для иконок
var locked_texture = preload("res://achievement_locked.png")
var unlocked_texture = preload("res://achievement_unlocked.png")

# Словарь переводов для интерфейса
var translations = {
	"en": {
		"status": "STATUS",
		"achievement": "ACHIEVEMENT",
		"description": "DESCRIPTION",
		"manager_not_found": "Achievements manager not found",
		"manager_not_available": "Achievements manager not available",
		"no_achievements": "No achievements data",
		"close": "Close"
	},
	"ru": {
		"status": "СТАТУС",
		"achievement": "ДОСТИЖЕНИЕ",
		"description": "ОПИСАНИЕ",
		"manager_not_found": "Менеджер достижений не найден",
		"manager_not_available": "Менеджер достижений не доступен",
		"no_achievements": "Нет данных о достижениях",
		"close": "Закрыть"
	}
}

# Словарь переводов для названий и описаний достижений
var achievement_translations = {
	"first_blood": {
		"en": {"name": "First Blood", "description": "Score your first point in the game"},
		"ru": {"name": "Первая кровь", "description": "Забейте свой первый гол в игре"}
	},
	"coin_collector": {
		"en": {"name": "Coin Collector", "description": "Collect 100 coins during gameplay"},
		"ru": {"name": "Коллекционер монет", "description": "Соберите 100 монет во время игры"}
	},
	"high_score": {
		"en": {"name": "High Score", "description": "Reach a score of 500 points or more"},
		"ru": {"name": "Рекордный счёт", "description": "Достигните счёта в 500 очков или более"}
	},
	"skin_collector": {
		"en": {"name": "Skin Collector", "description": "Unlock 5 different character skins"},
		"ru": {"name": "Коллекционер скинов", "description": "Разблокируйте 5 различных скинов персонажа"}
	},
	"ad_watcher": {
		"en": {"name": "Ad Watcher", "description": "Watch 10 advertisements to support the game"},
		"ru": {"name": "Наблюдатель рекламы", "description": "Посмотрите 10 рекламных роликов для поддержки игры"}
	},
	"veteran_player": {
		"en": {"name": "Veteran Player", "description": "Play the game for more than 10 hours"},
		"ru": {"name": "Опытный игрок", "description": "Играйте в игру более 10 часов"}
	},
	"perfectionist": {
		"en": {"name": "Perfectionist", "description": "Complete all levels with maximum rating"},
		"ru": {"name": "Перфекционист", "description": "Пройдите все уровни с максимальным рейтингом"}
	},
	"social_butterfly": {
		"en": {"name": "Social Butterfly", "description": "Invite 5 friends to play the game"},
		"ru": {"name": "Социальная бабочка", "description": "Пригласите 5 друзей поиграть в игру"}
	},
	"speedrunner": {
		"en": {"name": "Speedrunner", "description": "Complete any level in under 60 seconds"},
		"ru": {"name": "Спидраннер", "description": "Пройдите любой уровень менее чем за 60 секунд"}
	},
	"completionist": {
		"en": {"name": "Completionist", "description": "Unlock all achievements in the game"},
		"ru": {"name": "Комплиционист", "description": "Разблокируйте все достижения в игре"}
	}
}

var notification_scene = preload("res://scenes/AchievementNotification.tscn")

func _ready():
	print("[DEBUG] AchievementsScene начал инициализацию")
	
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
	
	# Проверяем, что все узлы существуют
	if not close_button:
		push_error("Кнопка закрытия не найдена!")
		return
	
	if not scroll_container:
		push_error("ScrollContainer не найден!")
		return
	
	if not achievements_list:
		push_error("Список достижений не найден!")
		return
	
	# Настраиваем кнопку закрытия в киберпанк стиле
	setup_cyberpunk_button(close_button)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Устанавливаем текст кнопки закрытия
	close_button.text = translate("close")
	
	# Настраиваем размеры и якоря
	setup_layout()
	
	# Получаем менеджер достижений
	achievements_manager = get_node_or_null("/root/AchievementsManager")
	
	if achievements_manager:
		print("[DEBUG] AchievementsManager найден")
		
		# Подключаем сигнал о разблокировке достижений
		if not achievements_manager.achievement_unlocked.is_connected(_on_achievement_unlocked):
			achievements_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	else:
		print("[ERROR] AchievementsManager не найден!")
		show_error_message(translate("manager_not_found"))
		return
	
	# Заполняем список достижений
	populate_achievements()
	
	# Центрируем диалог
	center_dialog()
	
	print("[DEBUG] AchievementsScene инициализирован")

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

# Функция для перевода названий и описаний достижений
func translate_achievement(achievement_id, field):
	if achievement_translations.has(achievement_id) and achievement_translations[achievement_id].has(current_language):
		return achievement_translations[achievement_id][current_language][field]
	elif achievement_translations.has(achievement_id) and achievement_translations[achievement_id].has("en"):
		return achievement_translations[achievement_id]["en"][field]
	else:
		# Возвращаем исходное значение, если перевод не найден
		if field == "name":
			return achievement_id + " Name"
		else:
			return achievement_id + " Description"

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

func center_dialog():
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(viewport_size.x - size.x) / 2,
		(viewport_size.y - size.y) / 2
	)

func setup_layout():
	# Устанавливаем якоря для ScrollContainer
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.anchor_right = 1.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_top = 10
	scroll_container.offset_right = -20
	scroll_container.offset_bottom = -20
	scroll_container.offset_left = 20
	
	# Устанавливаем якоря для списка достижений
	achievements_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	achievements_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_list.anchor_right = 1.0
	achievements_list.anchor_bottom = 1.0

func _on_close_button_pressed():
	print("[DEBUG] Закрытие диалога достижений")
	emit_signal("achievements_closed")
	queue_free()

func _on_achievement_unlocked(_achievement_id, _achievement_name, _reward_coins):
	# Обновляем список при разблокировке нового достижения
	populate_achievements()

func populate_achievements():
	print("[DEBUG] Начало заполнения списка достижений")
	
	# Очищаем список
	for child in achievements_list.get_children():
		child.queue_free()
	
	if not achievements_manager:
		print("[ERROR] Менеджер достижений не доступен")
		show_error_message(translate("manager_not_available"))
		return
	
	# Получаем все достижения
	var achievements = achievements_manager.achievements
	
	if achievements.is_empty():
		print("[WARNING] Список достижений пуст")
		show_empty_message()
		return
	
	print("[DEBUG] Найдено достижений: ", achievements.size())
	
	# Создаем заголовок таблицы
	create_table_header()
	
	# Заполняем достижения
	var count = 0
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		create_achievement_item(achievement_id, achievement)
		count += 1
	
	print("[DEBUG] Добавлено достижений в список: ", count)

func create_table_header():
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 40)
	
	var status_header = Label.new()
	status_header.text = translate("status")
	status_header.custom_minimum_size = Vector2(100, 0)
	status_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	status_header.add_theme_font_size_override("font_size", 16)
	
	var name_header = Label.new()
	name_header.text = translate("achievement")
	name_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	name_header.add_theme_font_size_override("font_size", 16)
	
	var desc_header = Label.new()
	desc_header.text = translate("description")
	desc_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_header.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	desc_header.add_theme_font_size_override("font_size", 16)
	
	header.add_child(status_header)
	header.add_child(name_header)
	header.add_child(desc_header)
	
	achievements_list.add_child(header)
	
	# Добавляем разделитель
	var separator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.2, 0.8, 1.0, 0.5))
	achievements_list.add_child(separator)

func create_achievement_item(achievement_id, achievement):
	print("[DEBUG] Создание элемента для достижения: ", achievement_id)
	
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(0, 80)
	
	# Статус достижения
	var status_container = Control.new()
	status_container.custom_minimum_size = Vector2(100, 60)
	
	# Создаем TextureRect для отображения иконки
	var status_icon = TextureRect.new()
	status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_icon.custom_minimum_size = Vector2(48, 48)
	
	if achievement.unlocked:
		# Иконка разблокированного достижения
		status_icon.texture = unlocked_texture
	else:
		# Иконка заблокированного достижения
		status_icon.texture = locked_texture
	
	status_container.add_child(status_icon)
	item.add_child(status_container)
	
	# Название достижения с фоном
	var name_container = PanelContainer.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_container.custom_minimum_size = Vector2(0, 60)
	
	# Создаем стиль для фона названия
	var name_style = StyleBoxFlat.new()
	name_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	name_style.border_width_left = 2
	name_style.border_width_right = 2
	name_style.border_width_top = 2
	name_style.border_width_bottom = 2
	name_style.border_color = Color(0.2, 0.8, 1.0, 0.3)
	name_container.add_theme_stylebox_override("panel", name_style)
	
	var name_label = Label.new()
	
	# Используем переведенное название достижения
	name_label.text = translate_achievement(achievement_id, "name")
	
	name_label.add_theme_font_size_override("font_size", 18)
	
	if achievement.unlocked:
		name_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.9))
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Добавляем отступы для текста
	name_label.add_theme_constant_override("margin_left", 10)
	name_label.add_theme_constant_override("margin_right", 10)
	name_label.add_theme_constant_override("margin_top", 5)
	name_label.add_theme_constant_override("margin_bottom", 5)
	
	name_container.add_child(name_label)
	
	# Описание достижения с фоном
	var desc_container = PanelContainer.new()
	desc_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_container.custom_minimum_size = Vector2(0, 60)
	
	# Создаем стиль для фона описания
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(0, 0, 0, 0.8)
	desc_style.border_width_left = 2
	desc_style.border_width_right = 2
	desc_style.border_width_top = 2
	desc_style.border_width_bottom = 2
	desc_style.border_color = Color(0.2, 0.8, 1.0, 0.3)
	desc_container.add_theme_stylebox_override("panel", desc_style)
	
	var desc_label = Label.new()
	
	# Используем переведенное описание достижения
	desc_label.text = translate_achievement(achievement_id, "description")
	
	desc_label.add_theme_font_size_override("font_size", 14)
	
	if achievement.unlocked:
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	else:
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Добавляем отступы для текста
	desc_label.add_theme_constant_override("margin_left", 10)
	desc_label.add_theme_constant_override("margin_right", 10)
	desc_label.add_theme_constant_override("margin_top", 5)
	desc_label.add_theme_constant_override("margin_bottom", 5)
	
	desc_container.add_child(desc_label)
	
	item.add_child(name_container)
	item.add_child(desc_container)
	
	achievements_list.add_child(item)
	
	# Добавляем разделитель между достижениями
	var separator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.3, 0.3, 0.3, 0.5))
	achievements_list.add_child(separator)
	
	print("[DEBUG] Элемент создан для достижения: ", achievement_id)

func show_error_message(message):
	var error_label = Label.new()
	error_label.text = message
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	achievements_list.add_child(error_label)

func show_empty_message():
	var empty_label = Label.new()
	empty_label.text = translate("no_achievements")
	empty_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	achievements_list.add_child(empty_label)

# Добавляем обработку клавиши Escape для закрытия
func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			_on_close_button_pressed()
