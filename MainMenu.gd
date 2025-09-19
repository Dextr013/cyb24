# MainMenu.gd
extends Control

# Явно загружаем GameEnums
const GameEnums = preload("res://GameEnums.gd")

# Ссылки на узлы
@onready var start_button = $VBoxContainer/StartButton
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var mode_select_button = $VBoxContainer/ModeSelectButton
@onready var leaderboard_button = $VBoxContainer/LeaderboardButton
@onready var achievements_button = $VBoxContainer/AchievementsButton
@onready var daily_reward_button = $VBoxContainer/DailyRewardButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var coins_label = $HBoxContainer/CoinsLabel
@onready var best_score_label = $HBoxContainer/BestScoreLabel
@onready var vbox_container = $VBoxContainer
@onready var hbox_container = $HBoxContainer
@onready var volume_container = $VolumeContainer
@onready var volume_slider = $VolumeContainer/VolumeSlider

# Copyright label
var copyright_label: Label

# Менеджеры
var music_manager
var game_data
var ad_manager
var device_manager
var achievements_manager
var game_modes
var web_bus

var mode_select_window = null
var leaderboard_scene = preload("res://LeaderboardScene.tscn")
var achievements_scene = preload("res://AchievementsScene.tscn")

# Текущие открытые сцены
var current_leaderboard_instance = null
var current_achievements_instance = null

# Локализация
var current_language = "en"
var translations = {
	"en": {
		"start": "Start Game",
		"continue": "Continue Game",
		"mode_select": "Select Mode",
		"leaderboard": "Leaderboard",
		"achievements": "Achievements",
		"daily_reward": "Daily Reward",
		"settings": "Settings",
		"quit": "Quit",
		"coins": "coins",
		"best": "Best",
		"volume": "Volume",
		"current_mode": "Current Mode: ",
		"classic": "Classic",
		"timed": "Timed",
		"limited": "Limited Moves",
		"challenge": "Challenge",
		"copyright": "© %d Your Company. All rights reserved."
	},
	"ru": {
		"start": "Начать игру",
		"continue": "Продолжить игру",
		"mode_select": "Выбор режима",
		"leaderboard": "Таблица лидеров",
		"achievements": "Достижения",
		"daily_reward": "Ежедневная награда",
		"settings": "Настройки",
		"quit": "Выход",
		"coins": "монеты",
		"best": "Лучший",
		"volume": "Громкость",
		"current_mode": "Текущий режим: ",
		"classic": "Классический",
		"timed": "На время",
		"limited": "Ограниченные ходы",
		"challenge": "Испытания",
		"copyright": "© %d Ваша Компания. Все права защищены."
	},
	"es": {
		"start": "Iniciar juego",
		"mode_select": "Seleccionar modo",
		"leaderboard": "Tabla de clasificación",
		"achievements": "Logros",
		"daily_reward": "Recompensa diaria",
		"settings": "Ajustes",
		"quit": "Salir",
		"coins": "monedas",
		"best": "Mejor",
		"volume": "Volumen",
		"current_mode": "Modo actual: ",
		"classic": "Clásico",
		"timed": "Contrarreloj",
		"limited": "Movimientos limitados",
		"challenge": "Desafío",
		"copyright": "© %d Su Empresa. Todos los derechos reservados."
	},
	"fr": {
		"start": "Commencer",
		"mode_select": "Sélectionner le mode",
		"leaderboard": "Classement",
		"achievements": "Succès",
		"daily_reward": "Récompense quotidienne",
		"settings": "Paramètres",
		"quit": "Quitter",
		"coins": "pièces",
		"best": "Meilleur",
		"volume": "Volume",
		"current_mode": "Mode actuel: ",
		"classic": "Classique",
		"timed": "Contre la montre",
		"limited": "Mouvements limités",
		"challenge": "Défi",
		"copyright": "© %d Votre Société. Tous droits réservés."
	},
	"de": {
		"start": "Spiel starten",
		"mode_select": "Modus auswählen",
		"leaderboard": "Bestenliste",
		"achievements": "Erfolge",
		"daily_reward": "Tägliche Belohnung",
		"settings": "Einstellungen",
		"quit": "Beenden",
		"coins": "münzen",
		"best": "Beste",
		"volume": "Lautstärke",
		"current_mode": "Aktueller Modus: ",
		"classic": "Klassisch",
		"timed": "Zeitgesteuert",
		"limited": "Begrenzte Züge",
		"challenge": "Herausforderung",
		"copyright": "© %d Ihr Unternehmen. Alle Rechte vorbehalten."
	}
}

func _ready():
	print("MainMenu initializing...")
	
	# Получаем ссылки на менеджеры
	game_data = get_node_or_null("/root/GameData")
	ad_manager = get_node_or_null("/root/AdvertisementManager")
	achievements_manager = get_node_or_null("/root/AchievementsManager")
	game_modes = get_node_or_null("/root/GameModes")
	music_manager = get_node_or_null("/root/MusicManager")
	device_manager = get_node_or_null("/root/DeviceManager")
	web_bus = get_node_or_null("/root/WebBus")
	
	# Создаем copyright label
	create_copyright_label()
	
	setup_cyberpunk_buttons()
	
	if not game_data:
		push_error("GameData not found!")
	
	# Добавляем кнопки в группу для управления
	for button in [start_button, continue_button, mode_select_button, leaderboard_button, achievements_button, daily_reward_button, settings_button, quit_button]:
		if button:
			button.add_to_group("menu_buttons")
			call_deferred("setup_cyberpunk_buttons")
	
	# Проверяем наличие сохраненной игры
	check_saved_game()
	
	# Подключаем сигналы кнопок
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
	if mode_select_button:
		mode_select_button.pressed.connect(_on_mode_select_button_pressed)
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	if achievements_button:
		achievements_button.pressed.connect(_on_achievements_button_pressed)
	if daily_reward_button:
		daily_reward_button.pressed.connect(_on_daily_reward_button_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Подключаем слайдер громкости
	if volume_slider and volume_slider is HSlider:
		volume_slider.value_changed.connect(_on_volume_changed)
		print("Volume slider connected successfully")
	else:
		push_error("VolumeSlider is not a HSlider or is missing!")
		create_fallback_volume_slider()
	
	# Загружаем настройки языка
	load_language_settings()
	
	# Загружаем настройки громкости
	load_volume_settings()
	
	# Настраиваем адаптивный интерфейс
	setup_responsive_ui()
	
	# Обновляем UI
	update_ui()
	
	# Воспроизводим музыку меню, если она включена
	if music_manager:
		if music_manager.has_method("set_context_music"):
			music_manager.set_context_music("menu")
		elif music_manager.has_method("play_music"):
			music_manager.play_music("menu")
	
	# Подключаем сигналы от AdvertisementManager
	if ad_manager and ad_manager.has_signal("ad_completed"):
		if not ad_manager.ad_completed.is_connected(_on_ad_completed):
			ad_manager.ad_completed.connect(_on_ad_completed)
	
	# Подключаем сигналы от AchievementsManager
	if achievements_manager and achievements_manager.has_signal("achievement_unlocked"):
		if not achievements_manager.achievement_unlocked.is_connected(_on_achievement_unlocked):
			achievements_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# Подключаем обработчик изменения размера экрана
	get_viewport().size_changed.connect(_on_screen_resized)
	
	print("MainMenu initialized successfully")

# Создание copyright label
func create_copyright_label():
	copyright_label = Label.new()
	copyright_label.name = "CopyrightLabel"
	add_child(copyright_label)
	
	# Обновляем текст
	update_copyright_text()
	
	# Настраиваем положение
	setup_copyright_label()

# Обновление текста copyright
func update_copyright_text():
	var current_year = Time.get_date_dict_from_system()["year"]
	var copyright_texts = {
		"en": "© %d 13.ink. All rights reserved.",
		"ru": "© %d 13.ink. Все права защищены.",
		"es": "© %d 13.ink. Todos los derechos reservados.",
		"fr": "© %d 13.ink. Tous droits réservés.",
		"de": "© %d 13.ink. Alle Rechte vorbehalten."
	}
	
	# Получаем текущий язык из LanguageManager
	var current_lang = "en"
	if has_node("/root/LanguageManager"):
		var lang_manager = get_node("/root/LanguageManager")
		current_lang = lang_manager.current_language
	
	# Устанавливаем текст на нужном языке
	var text_template = copyright_texts.get(current_lang, copyright_texts.en)
	copyright_label.text = text_template % current_year

# Настройка положения и стиля copyright label
func setup_copyright_label():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Используем процент от высоты экрана для позиционирования
	var margin_bottom = screen_size.y * 0.03  # 3% от высоты экрана
	
	copyright_label.position = Vector2(
		(screen_size.x - copyright_label.size.x) / 2,
		screen_size.y - margin_bottom - copyright_label.size.y
	)
	
	# Настраиваем стиль текста
	copyright_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	
	# Адаптивный размер шрифта
	var font_size = max(10, screen_size.y * 0.02)  # Минимум 10px, 2% от высоты экрана
	copyright_label.add_theme_font_size_override("font_size", font_size)
	
	# Центрируем текст
	copyright_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Функция проверки сохраненной игры
func check_saved_game():
	# Проверяем наличие сохраненной игры
	var has_save = false
	
	if OS.has_feature('web') and web_bus and web_bus.has_method("has_saved_game"):
		has_save = web_bus.has_saved_game()
	else:
		has_save = FileAccess.file_exists("user://game_save.dat")
	
	print("Saved game exists: ", has_save)
	
	if continue_button:
		continue_button.visible = has_save
		continue_button.disabled = !has_save

# Обработчики кнопок
func _on_start_button_pressed():
	# Устанавливаем флаг, чтобы не показывать заставку
	if game_data and game_data.has_method("set_show_splash"):
		game_data.set_show_splash(false)
	
	# Переходим к игре
	if ResourceLoader.exists("res://main.tscn"):
		var result = get_tree().change_scene_to_file("res://main.tscn")
		if result != OK:
			push_error("Failed to change scene to main.tscn: " + str(result))
	else:
		push_error("Main scene not found: res://main.tscn")

func _on_continue_button_pressed():
	print("Continue button pressed")
	
	# Устанавливаем флаг, чтобы не показывать заставку
	if game_data and game_data.has_method("set_show_splash"):
		game_data.set_show_splash(false)
	
	# Устанавливаем флаг продолжения игры в GameData
	if game_data and game_data.has_method("set_continue_game"):
		game_data.set_continue_game(true)
		print("Continue game flag set")
	else:
		print("GameData not available or missing set_continue_game method")
	
	# Переходим к игре
	if ResourceLoader.exists("res://main.tscn"):
		var result = get_tree().change_scene_to_file("res://main.tscn")
		if result != OK:
			push_error("Failed to change scene to main.tscn: " + str(result))
	else:
		push_error("Main scene not found: res://main.tscn")

func _on_mode_select_button_pressed():
	show_mode_select_dialog()

func _on_leaderboard_button_pressed():
	if ad_manager and ad_manager.has_method("is_ad_available") and ad_manager.is_ad_available(GameEnums.AdType.LEADERBOARD):
		ad_manager.show_advertisement(GameEnums.AdType.LEADERBOARD)
	else:
		show_leaderboard()

func _on_achievements_button_pressed():
	show_achievements()

func _on_daily_reward_button_pressed():
	if ad_manager and ad_manager.has_method("is_ad_available") and ad_manager.is_ad_available(GameEnums.AdType.DAILY_REWARD):
		ad_manager.show_advertisement(GameEnums.AdType.DAILY_REWARD)

func _on_settings_button_pressed():
	if ResourceLoader.exists("res://scenes/settings_menu.tscn"):
		var result = get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
		if result != OK:
			push_error("Failed to change scene to settings_menu.tscn: " + str(result))
	else:
		push_error("Settings scene not found: res://scenes/settings_menu.tscn")

func _on_quit_button_pressed():
	if OS.has_feature('web'):
		# Для веба показываем сообщение вместо выхода
		if web_bus and web_bus.has_method("show_exit_message"):
			web_bus.show_exit_message()
		else:
			print("Exit button pressed on web version")
	else:
		get_tree().quit()

func _on_volume_changed(value):
	if music_manager and music_manager.has_method("set_volume"):
		music_manager.set_volume(value)
	
	save_volume_settings()

func _on_ad_completed(ad_type, reward):
	if ad_type == GameEnums.AdType.LEADERBOARD:
		show_leaderboard()
	elif ad_type == GameEnums.AdType.DAILY_REWARD:
		if game_data and game_data.has_method("add_coins"):
			game_data.add_coins(reward)
		update_ui()

func _on_achievement_unlocked(_achievement_id, _achievement_name, _reward_coins):
	update_ui()

# Функции для работы с Leaderboard и Achievements
func show_leaderboard():
	# Закрываем предыдущий инстанс, если он есть
	if current_leaderboard_instance and is_instance_valid(current_leaderboard_instance):
		current_leaderboard_instance.queue_free()
		current_leaderboard_instance = null
		return
	
	# Создаем новый инстанс
	var leaderboard_instance = leaderboard_scene.instantiate()
	get_tree().root.add_child(leaderboard_instance)
	current_leaderboard_instance = leaderboard_instance
	
	# Подключаем сигнал закрытия
	if leaderboard_instance.has_signal("scene_closed"):
		leaderboard_instance.scene_closed.connect(_on_leaderboard_closed)
	else:
		# Если сигнала нет, добавляем обработчик к кнопке закрытия
		var close_button = leaderboard_instance.find_child("CloseButton")
		if close_button:
			close_button.pressed.connect(_on_leaderboard_closed.bind(leaderboard_instance))
	
	# Центрируем сцену
	var viewport_size = get_viewport().get_visible_rect().size
	leaderboard_instance.position = Vector2(
		(viewport_size.x - leaderboard_instance.size.x) / 2,
		(viewport_size.y - leaderboard_instance.size.y) / 2
	)

func show_achievements():
	# Закрываем предыдущий инстанс, если он есть
	if current_achievements_instance and is_instance_valid(current_achievements_instance):
		current_achievements_instance.queue_free()
		current_achievements_instance = null
		return
	
	# Создаем новый инстанс
	var achievements_instance = achievements_scene.instantiate()
	get_tree().root.add_child(achievements_instance)
	current_achievements_instance = achievements_instance
	
	# Подключаем сигнал закрытия
	if achievements_instance.has_signal("scene_closed"):
		achievements_instance.scene_closed.connect(_on_achievements_closed)
	else:
		# Если сигнала нет, добавляем обработчик к кнопке закрытия
		var close_button = achievements_instance.find_child("CloseButton")
		if close_button:
			close_button.pressed.connect(_on_achievements_closed.bind(achievements_instance))
	
	# Центрируем сцену
	var viewport_size = get_viewport().get_visible_rect().size
	achievements_instance.position = Vector2(
		(viewport_size.x - achievements_instance.size.x) / 2,
		(viewport_size.y - achievements_instance.size.y) / 2
	)

func _on_leaderboard_closed(instance = null):
	print("Лидерборд закрыт")
	if instance:
		instance.queue_free()
	elif current_leaderboard_instance:
		current_leaderboard_instance.queue_free()
	current_leaderboard_instance = null

func _on_achievements_closed(instance = null):
	print("Достижения закрыт")
	if instance:
		instance.queue_free()
	elif current_achievements_instance:
		current_achievements_instance.queue_free()
	current_achievements_instance = null

# Функции для работы с настройки
func create_fallback_volume_slider():
	# Создаем контейнер для слайдера громкости, если его нет
	if not volume_container:
		volume_container = HBoxContainer.new()
		volume_container.name = "VolumeContainer"
		add_child(volume_container)
	
	# Удаляем старый VolumeSlider, если он есть и не является HSlider
	if volume_slider and not volume_slider is HSlider:
		volume_slider.queue_free()
		volume_slider = null
	
	# Создаем текст
	var volume_label = Label.new()
	volume_label.text = translate("volume") + ":"
	volume_container.add_child(volume_label)
	
	# Создаем слайдер
	volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.1
	volume_slider.value = 0.3
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_container.add_child(volume_slider)
	
	print("Fallback volume slider created")

func load_language_settings():
	if OS.has_feature('web') and web_bus and web_bus.has_method("load_data"):
		var settings_data = web_bus.load_data("player_settings")
		if settings_data:
			current_language = settings_data.get("language", "en")
	else:
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			current_language = config.get_value("ui", "language", "en")
	
	# Обновляем тексты интерфейса
	update_ui_texts()
	# Обновляем текст copyright
	update_copyright_text()

func load_volume_settings():
	var volume = 0.3
	
	if OS.has_feature('web') and web_bus and web_bus.has_method("load_data"):
		var settings_data = web_bus.load_data("player_settings")
		if settings_data:
			volume = settings_data.get("volume", 0.3)
	else:
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			volume = config.get_value("audio", "volume", 0.3)
	
	if volume_slider:
		volume_slider.value = volume
	
	# Устанавливаем громкость в MusicManager
	if music_manager and music_manager.has_method("set_volume"):
		music_manager.set_volume(volume)

func save_volume_settings():
	var settings_data = {
		"volume": volume_slider.value
	}
	
	if OS.has_feature('web') and web_bus and web_bus.has_method("save_data"):
		web_bus.save_data("player_settings", settings_data)
	else:
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err != OK:
			config = ConfigFile.new()
		
		config.set_value("audio", "volume", volume_slider.value)
		config.save("user://player_settings.cfg")

func setup_responsive_ui():
	if not device_manager:
		return
	
	# Добавляем в группу для получения уведомлений об изменении размера
	add_to_group("responsive")
	
	# Настраиваем UI в зависимости от типа устройства и ориентации
	update_layout()

func update_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(1.0, min(screen_size.x / 1280.0, screen_size.y / 720.0))
	
	# Центрируем основной контейнер
	if vbox_container:
		vbox_container.position = Vector2(
			(screen_size.x - vbox_container.size.x) / 2,
			(screen_size.y - vbox_container.size.y) / 2
		)
	
	# Центрируем верхнюю панель с монетами и рекордом
	if hbox_container:
		hbox_container.position = Vector2(
			(screen_size.x - hbox_container.size.x * scale_factor) / 2,
			20 * scale_factor
		)
		hbox_container.scale = Vector2(scale_factor, scale_factor)
	
	# Центрируем контейнер громкости
	if volume_container:
		volume_container.position = Vector2(
			(screen_size.x - volume_container.size.x * scale_factor) / 2,
			screen_size.y - 100 * scale_factor
		)
		volume_container.scale = Vector2(scale_factor, scale_factor)
	
	if copyright_label:
		copyright_label.position = Vector2(
			(screen_size.x - copyright_label.size.x) / 2,
			screen_size.y - copyright_label.size.y - 20
		)
	# Автоматически масштабируем кнопки под размер экрана
	for button in get_tree().get_nodes_in_group("menu_buttons"):
		var base_size = Vector2(300, 60)
		button.custom_minimum_size = base_size * scale_factor
		button.add_theme_font_size_override("font_size", int(24 * scale_factor))
	
	# Обновляем размер шрифта для верхней панели
	var font_size = int(20 * scale_factor)
	if coins_label:
		coins_label.add_theme_font_size_override("font_size", font_size)
	if best_score_label:
		best_score_label.add_theme_font_size_override("font_size", font_size)
	
	# Обновляем размер слайдера громкости
	if volume_slider:
		volume_slider.custom_minimum_size = Vector2(300 * scale_factor, 30 * scale_factor)
	
	# Обновляем положение copyright label
	setup_copyright_label()

func _on_screen_resized():
	update_layout()

func update_ui():
	if game_data:
		if coins_label:
			coins_label.text = str(game_data.player_coins) + " " + translate("coins")
		if best_score_label:
			best_score_label.text = translate("best") + ": " + str(game_data.best_score)
	
	if ad_manager and ad_manager.has_method("is_ad_available"):
		if daily_reward_button:
			daily_reward_button.disabled = not ad_manager.is_ad_available(GameEnums.AdType.DAILY_REWARD)

func update_ui_texts():
	if start_button:
		start_button.text = translate("start")
	if continue_button:
		continue_button.text = translate("continue")
	if mode_select_button:
		mode_select_button.text = translate("mode_select")
	if leaderboard_button:
		leaderboard_button.text = translate("leaderboard")
	if achievements_button:
		achievements_button.text = translate("achievements")
	if daily_reward_button:
		daily_reward_button.text = translate("daily_reward")
	if settings_button:
		settings_button.text = translate("settings")
	if quit_button:
		quit_button.text = translate("quit")
	
	if game_data:
		if coins_label:
			coins_label.text = str(game_data.player_coins) + " " + translate("coins")
		if best_score_label:
			best_score_label.text = translate("best") + ": " + str(game_data.best_score)

func translate(key):
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	elif translations.has("en") and translations["en"].has(key):
		return translations["en"][key]
	else:
		return key

# Функции для работы с выбором режима игры
func show_mode_select_dialog():
	if mode_select_window != null and is_instance_valid(mode_select_window):
		mode_select_window.queue_free()
		mode_select_window = null
		return
	
	if ResourceLoader.exists("res://scenes/ModeSelectDialog.tscn"):
		mode_select_window = load("res://scenes/ModeSelectDialog.tscn").instantiate()
		get_tree().root.add_child(mode_select_window)
		
		if mode_select_window.has_signal("close_requested"):
			mode_select_window.close_requested.connect(_on_mode_select_closed)
	else:
		push_error("ModeSelectDialog scene not found: res://scenes/ModeSelectDialog.tscn")
		create_fallback_mode_select_dialog()

func _on_mode_select_closed():
	mode_select_window = null

func create_fallback_mode_select_dialog():
	var dialog = Window.new()
	dialog.title = "Select Game Mode"
	dialog.size = Vector2(400, 500)
	dialog.unresizable = true
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(380, 480)
	vbox.position = Vector2(10, 10)
	dialog.add_child(vbox)
	
	var title = Label.new()
	title.text = "Select Game Mode"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	if game_modes:
		for mode in GameEnums.GameMode.values():
			var mode_button = Button.new()
			mode_button.text = game_modes.get_mode_name(mode) + "\n" + game_modes.get_mode_description(mode)
			mode_button.custom_minimum_size = Vector2(360, 80)
			mode_button.pressed.connect(_on_fallback_mode_selected.bind(mode))
			vbox.add_child(mode_button)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(dialog.queue_free)
	vbox.add_child(close_button)
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_fallback_mode_selected(mode):
	if game_modes:
		game_modes.set_game_mode(mode)
		print("Selected game mode: ", game_modes.get_mode_name(mode))

# Функции для киберпанк стиля
func setup_cyberpunk_buttons():
	print("Setting up cyberpunk menu buttons...")
	
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	print("Found ", buttons.size(), " menu buttons in group")
	
	# Проверяем, что CyberpunkUI загружен
	if has_node("/root/CyberpunkUI"):
		var cyberpunk_ui = get_node("/root/CyberpunkUI")
		cyberpunk_ui.setup_cyberpunk_buttons(buttons)
		
		# Подключаем сигналы, если нужно обрабатывать события
		if not cyberpunk_ui.button_hovered.is_connected(_on_cyberpunk_button_hovered):
			cyberpunk_ui.button_hovered.connect(_on_cyberpunk_button_hovered)
		if not cyberpunk_ui.button_pressed.is_connected(_on_cyberpunk_button_pressed):
			cyberpunk_ui.button_pressed.connect(_on_cyberpunk_button_pressed)
		if not cyberpunk_ui.button_released.is_connected(_on_cyberpunk_button_released):
			cyberpunk_ui.button_released.connect(_on_cyberpunk_button_released)
	else:
		print("CyberpunkUI not found, using fallback styling")
		# Fallback: применяем стили напряму
		setup_cyberpunk_buttons_fallback(buttons)

func setup_cyberpunk_buttons_fallback(buttons: Array):
	# Резервная функция на случай, если CyberpunkUI не загружен
	for button in buttons:
		if button is Button:
			print("Applying fallback cyberpunk style to: ", button.name)
			
			# Создаем базовые стили
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
			normal_style.border_width_left = 3
			normal_style.border_width_right = 3
			normal_style.border_width_top = 3
			normal_style.border_width_bottom = 3
			normal_style.border_color = Color(0.2, 0.8, 1.0)
			normal_style.corner_radius_top_left = 0
			normal_style.corner_radius_top_right = 0
			normal_style.corner_radius_bottom_right = 15
			normal_style.corner_radius_bottom_left = 15
			
			# Применяем стили
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_color_override("font_color", Color(1, 1, 1))
			button.add_theme_constant_override("outline_size", 2)
			button.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.8))

func _on_cyberpunk_button_hovered(button: Button):
	print("Menu button hovered: ", button.name)

func _on_cyberpunk_button_pressed(button: Button):
	print("Menu button pressed: ", button.name)

func _on_cyberpunk_button_released(button: Button):
	print("Menu button released: ", button.name)
