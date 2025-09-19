# main.gd
extends Control

# Добавляем перечисления прямо в файл
enum GameMode {
	CLASSIC,    # Классический режим
	TIMED,      # Режим на время
	LIMITED,    # Режим с ограниченным количеством ходов
	CHALLENGE   # Режим испытаний
}

enum AdType {
	UNDO,           # Реклама за отмену хода
	CONTINUE,       # Реклама за продолжение игры
	LEADERBOARD,    # Реклама за просмотр лидерборда
	REWARD_COINS,   # Реклама за получение монет
	DAILY_REWARD    # Ежедневная награда за рекламу
}

# Game constants
const GRID_SIZE = 4
var TILE_SIZE = 100
var TILE_SPACING = 10
const ANIMATION_DURATION = 0.15
const SWIPE_MIN_DISTANCE = 20

# References
@onready var tiles_container = $TilesContainer
@onready var score_label = $UI/ScoreLabel
@onready var best_score_label = $UI/BestScoreLabel
@onready var coins_label = $UI/CoinsLabel
@onready var time_label = $UI/TimeLabel
@onready var moves_label = $UI/MovesLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var final_score_label = $UI/GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button = $UI/ButtonsContainer/VBoxContainer/RestartButton
@onready var undo_button = $UI/ButtonsContainer/VBoxContainer/UndoButton
@onready var menu_button = $UI/ButtonsContainer/VBoxContainer/MenuButton
@onready var new_game_button = $UI/ButtonsContainer/VBoxContainer/NewGameButton
@onready var settings_button = $UI/ButtonsContainer/VBoxContainer/SettingsButton
@onready var background = $Background
@onready var grid_background = $GridBackground
@onready var focus_capture = $FocusCapture
@onready var touch_controls = $TouchControls
@onready var ui_container = $UI/UIContainer
@onready var buttons_container = $UI/ButtonsContainer
@onready var hbox_container = $UI/HBoxContainer  # Добавляем ссылку на HBoxContainer

# Game state
var grid = []
var score = 0
var best_score = 0
var game_over = false
var game_started = false
var moving_tiles = 0
var previous_states = []
var can_undo = false
var is_moving = false
var continue_available = false
var continue_state = null
var max_tile_value = 0
var game_start_time = 0
var moves_count = 0
var merges_in_current_move = 0
var used_undo_in_game = false

# Settings
var music_volume = 0.5
var music_enabled = true
var background_index = 0
var language_index = 0
var is_window_focused = true

# Touch/swipe variables
var touch_start_position = Vector2.ZERO
var touch_end_position = Vector2.ZERO
var swiping = false

# Tile scene reference
var tile_scene = preload("res://scenes/tile.tscn")

# Background rotation timer
var bg_timer = null

# Ссылка на менеджер музыки
var music_manager
var device_manager
var web_bus

# Background textures
var background_textures = [
	preload("res://assets/backgrounds/bg1.webp"),
	preload("res://assets/backgrounds/bg2.webp"),
	preload("res://assets/backgrounds/bg3.webp"),
	preload("res://assets/backgrounds/bg4.webp"),
	preload("res://assets/backgrounds/bg5.webp"),
	preload("res://assets/backgrounds/bg6.webp"),
	preload("res://assets/backgrounds/bg7.webp")
]
var current_bg_index = 0

# Language options
var languages = ["English", "Russian", "Spanish", "French", "German"]
var language_codes = ["en", "ru", "es", "fr", "de"]

# Managers
var achievements_manager
var game_modes
var game_data
var ad_manager
var main_styles 

# Resource cache для оптимизации
var resource_cache = {
	"tile_scene": preload("res://scenes/tile.tscn"),
	"backgrounds": [
		preload("res://assets/backgrounds/bg1.webp"),
		preload("res://assets/backgrounds/bg2.webp"),
		preload("res://assets/backgrounds/bg3.webp"),
		preload("res://assets/backgrounds/bg4.webp"),
		preload("res://assets/backgrounds/bg5.webp"),
		preload("res://assets/backgrounds/bg6.webp"),
		preload("res://assets/backgrounds/bg7.webp")
	],
	"fonts": {
		"roboto_bold": load("res://assets/fonts/roboto-bold.ttf") if ResourceLoader.exists("res://assets/fonts/roboto-bold.ttf") else null
	}
}

# Локализация
var current_language = "en"
var translations = {
	"en": {
		"settings_title": "SETTINGS",
		"music_volume": "Music Volume",
		"music_enabled": "Music Enabled",
		"background": "Background",
		"language": "Language",
		"close": "CLOSE",
		"score": "Score",
		"best": "Best",
		"coins": "coins",
		"time": "Time",
		"moves": "Moves",
		"final_score": "Final Score",
		"restart": "Restart",
		"undo": "Undo",
		"menu": "Menu",
		"new_game": "New Game",
		"settings": "Settings",
		"game_over": "Game Over",
		"continue": "Continue",
		"quit": "Quit",
		"back_to_menu": "Back to Menu"
	},
	"ru": {
		"settings_title": "НАСТРОЙКИ",
		"music_volume": "Громкость музыки",
		"music_enabled": "Музыка включена",
		"background": "Фон",
		"language": "Язык",
		"close": "ЗАКРЫТЬ",
		"score": "Счёт",
		"best": "Лучший",
		"coins": "монеты",
		"time": "Время",
		"moves": "Ходы",
		"final_score": "Финальный счёт",
		"restart": "Заново",
		"undo": "Отмена",
		"menu": "Меню",
		"new_game": "Новая игра",
		"settings": "Настройки",
		"game_over": "Игра окончена",
		"continue": "Продолжить",
		"quit": "Выход",
		"back_to_menu": "В главное меню"
	},
	"es": {
		"settings_title": "AJUSTES",
		"music_volume": "Volumen de música",
		"music_enabled": "Música activada",
		"background": "Fondo",
		"language": "Idioma",
		"close": "CERRAR",
		"score": "Puntuación",
		"best": "Mejor",
		"coins": "monedas",
		"time": "Tiempo",
		"moves": "Movimientos",
		"final_score": "Puntuación final",
		"restart": "Reiniciar",
		"undo": "Deshacer",
		"menu": "Menú",
		"new_game": "Nuevo juego",
		"settings": "Ajustes",
		"game_over": "Juego terminado",
		"continue": "Continuar",
		"quit": "Salir",
		"back_to_menu": "Volver al menú"
	},
	"fr": {
		"settings_title": "PARAMÈTRES",
		"music_volume": "Volume de la musique",
		"music_enabled": "Musique activée",
		"background": "Arrière-plan",
		"language": "Langue",
		"close": "FERMER",
		"score": "Score",
		"best": "Meilleur",
		"coins": "pièces",
		"time": "Temps",
		"moves": "Mouvements",
		"final_score": "Score final",
		"restart": "Redémarrer",
		"undo": "Annuler",
		"menu": "Menu",
		"new_game": "Nouvelle partie",
		"settings": "Paramètres",
		"game_over": "Jeu terminado",
		"continue": "Continuer",
		"quit": "Quitter",
		"back_to_menu": "Retour au menu"
	},
	"de": {
		"settings_title": "EINSTELLUNGEN",
		"music_volume": "Musiklautstärke",
		"music_enabled": "Musik aktiviert",
		"background": "Hintergrund",
		"language": "Sprache",
		"close": "SCHLIEẞEN",
		"score": "Punktzahl",
		"best": "Beste",
		"coins": "münzen",
		"time": "Zeit",
		"moves": "Züge",
		"final_score": "Endstand",
		"restart": "Neustart",
		"undo": "Rückgängig",
		"menu": "Menü",
		"new_game": "Neues Spiel",
		"settings": "Einstellungen",
		"game_over": "Spiel beendet",
		"continue": "Fortsetzen",
		"quit": "Beenden",
		"back_to_menu": "Zurück zum Menü"
	}
}

# Объявления для настроек UI
var music_slider: HSlider
var music_checkbox: CheckBox
var background_option: OptionButton
var language_option: OptionButton
var close_settings_button: Button
var back_to_menu_button: Button
var settings_panel: Panel

# Кастомная заставка
var custom_splash: TextureRect

# Функции для кастомной заставки
func show_custom_splash():
	# Создаем контейнер для центрирования
	var center_container = CenterContainer.new()
	center_container.name = "CustomSplashContainer"
	get_viewport().size_changed.connect(update_ui_layout)
	get_viewport().size_changed.connect(update_tile_sizes)
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	
	custom_splash = TextureRect.new()
	custom_splash.name = "CustomSplash"
	
	# Определяем язык для заставки
	var system_lang = OS.get_locale_language().to_lower()
	if system_lang == "ru" or system_lang.begins_with("ru"):
		custom_splash.texture = preload("res://assets/splash/splash_ru.png")
	else:
		custom_splash.texture = preload("res://assets/splash/splash_en.png")
	
	# Настраиваем размер текстуры, чтобы она не превышала размеры экрана
	var max_size = min(get_viewport().size.x, get_viewport().size.y) * 0.9
	custom_splash.custom_minimum_size = Vector2(max_size, max_size)
	custom_splash.expand = true  # Включаем расширение
	custom_splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	
	center_container.add_child(custom_splash)
	add_child(center_container)

func hide_custom_splash():
	var container = get_node_or_null("CustomSplashContainer")
	if container:
		container.queue_free()
	if custom_splash:
		custom_splash.queue_free()
	custom_splash = null

# Настройки для веб-сборки
func setup_web_settings():
	# Настройки рендеринга для веб
	get_viewport().msaa_2d = Viewport.MSAA_4X
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	
	# Улучшаем качество шрифтов для веб-сборки
	setup_web_fonts()
	
	# Оптимизация для мобильных устройств
	if OS.has_feature('web') and JavaScriptBridge.eval("navigator.userAgent").find("Mobile") != -1:
		Engine.max_fps = 60
		get_viewport().debounce_input_events = true

func setup_web_fonts():
	var font = load("res://assets/fonts/roboto-bold.ttf")
	if font:
		# Увеличиваем разрешение шрифтов для веб-сборки
		for label in get_tree().get_nodes_in_group("ui_labels"):
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 28)
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
			label.add_theme_constant_override("outline_size", 2)

# Функция настройки адаптивного UI
func setup_responsive_ui():
	if not device_manager:
		return
	
func _on_screen_resized():
	# Небольшая задержка для стабилизации размера
	await get_tree().create_timer(0.1).timeout
	update_tile_sizes()
	update_ui_layout()
	update_tile_positions()
# Функция обновления позиций плиток
func update_tile_positions():
	# Обновляем позиции всех плиток в соответствии с текущими размерами
	for tile in tiles_container.get_children():
		if tile.has_method("update_position"):
			tile.update_position()
		else:
			# Резервный расчет позиции
			var grid_pos = tile.grid_position
			tile.position = Vector2(
				grid_pos.x * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0,
				grid_pos.y * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0
			)
	print("Tile positions updated")
# Функция обновления размеров плиток
func update_tile_sizes():
	var screen_size = get_viewport().get_visible_rect().size
	var new_tile_size = 100  # базовый размер
	var new_tile_spacing = 10  # базовый отступ
	
	# Адаптивный расчет размеров на основе размера экрана
	var min_dimension = min(screen_size.x, screen_size.y)
	
	if device_manager and device_manager.is_mobile():
		if device_manager.is_portrait():
			# Вертикальная ориентация на мобильных
			new_tile_size = min_dimension * 0.18  # 18% от минимального размера
			new_tile_spacing = new_tile_size * 0.1  # 10% от размера плитки
		else:
			# Горизонтальная ориентация на мобильных
			new_tile_size = min_dimension * 0.15
			new_tile_spacing = new_tile_size * 0.1
	elif device_manager and device_manager.is_tablet():
		# Планшеты
		new_tile_size = min_dimension * 0.16
		new_tile_spacing = new_tile_size * 0.1
	else:
		# Десктоп
		new_tile_size = min(100, min_dimension * 0.15)
		new_tile_spacing = new_tile_size * 0.1
	
	# Обновляем глобальные переменные
	TILE_SIZE = new_tile_size
	TILE_SPACING = new_tile_spacing
	
	# Создаем фон сетки
	create_grid_background()
	print("Grid background created")
	
	# Инициализируем сетку
	initialize_grid()
	print("Grid initialized")
	
	# ОБЯЗАТЕЛЬНО обновляем UI после создания сетки
	call_deferred("update_ui_layout")
	call_deferred("update_tile_positions")

# Настраиваем touch controls
func setup_touch_controls():
	if device_manager and device_manager.is_touch_device():
		touch_controls.visible = true
	else:
		touch_controls.visible = false

# Функция отключения фокуса кнопок
func disable_button_focus():
	# Отключаем фокус для всех кнопок в группе
	for button in get_tree().get_nodes_in_group("buttons"):
		button.focus_mode = Control.FOCUS_NONE
		# Также отключаем возможность получения фокуса через таб
		button.focus_previous = NodePath("")
		button.focus_next = NodePath("")
	
	# Убедимся, что фокус захватывается специальным узлом
	if focus_capture:
		focus_capture.focus_mode = Control.FOCUS_ALL
		focus_capture.grab_focus()
	
	# Также отключаем фокус для кнопок в game_over_panel
	var continue_button = game_over_panel.get_node("VBoxContainer/ContinueButton") as Button
	var quit_button = game_over_panel.get_node("VBoxContainer/QuitButton") as Button
	var game_over_buttons = [continue_button, quit_button]
	
	for button in game_over_buttons:
		if button:
			button.add_to_group("buttons")
			button.focus_mode = Control.FOCUS_NONE
			print("Added to group: ", button.name)
	
	# Отключаем фокус для всех кнопок в группе
	for button in get_tree().get_nodes_in_group("buttons"):
		button.focus_mode = Control.FOCUS_NONE
		print("Disabled focus for: ", button.name)

func load_saved_game():
	var has_save = false
	
	# Проверяем наличие сохранения через WebBus для веба
	if OS.has_feature('web') and web_bus and web_bus.has_method("hasKey"):
		has_save = web_bus.hasKey("game_save")
	else:
		# Локальная проверка для десктоп версии
		has_save = FileAccess.file_exists("user://game_save.dat")
	
	if has_save:
		print("Save file exists, loading...")
		var save_data = null
		
		# Загружаем через WebBus для веба
		if OS.has_feature('web') and web_bus and web_bus.has_method("loadData"):
			var save_data_str = web_bus.loadData("game_save")
			if save_data_str and save_data_str != "":
				save_data = JSON.parse_string(save_data_str)
		else:
			# Локальная загрузка для десктоп версии
			var file = FileAccess.open("user://game_save.dat", FileAccess.READ)
			if file:
				save_data = file.get_var()
				file.close()
		
		if save_data and typeof(save_data) == TYPE_DICTIONARY:
			print("Save data loaded successfully")
			restore_state(save_data)
			print("Game loaded from save")
		else:
			print("Invalid save data format, starting new game")
			start_new_game()
	else:
		print("No save file found, starting new game")
		start_new_game()

func _ready():
	print("Main scene _ready() started")
	
	main_styles = get_node_or_null("/root/MainStyles")
	# Проверяем наличие шрифтов
	if ResourceLoader.exists("res://assets/fonts/orbitron.ttf"):
		print("Orbitron font found")
	else:
		print("Orbitron font NOT found")
	if game_data and game_data.has_method("should_show_splash") and game_data.should_show_splash():
		show_custom_splash()
		# Создаем таймер для скрытия заставки через 2 секунды
		var splash_timer = Timer.new()
		splash_timer.wait_time = 2.0
		splash_timer.one_shot = true
		splash_timer.timeout.connect(_on_splash_timer_timeout)
		add_child(splash_timer)
		splash_timer.start()
	else:
		# Если заставка не нужна, сразу запускаем игру
		start_game_after_splash()
	
	# Настройка для веб-сборки
	if OS.has_feature('web'):
		setup_web_settings()
	
	# Подключаем обработчик изменения размера экрана
	get_viewport().size_changed.connect(_on_screen_resized)
	
	# Проверка перед экспортом
	print("Web export check:")
	print("Screen size: ", get_viewport().size)
	if OS.has_feature('web'):
		print("DPR: ", JavaScriptBridge.eval("window.devicePixelRatio", true))
		print("User Agent: ", JavaScriptBridge.eval("navigator.userAgent", true))

func initialize_game_elements():
	# Загружаем настройки
	load_player_settings()
	
	# Получаем ссылки на менеджеры
	game_data = get_node_or_null("/root/GameData")
	device_manager = get_node_or_null("/root/DeviceManager")
	achievements_manager = get_node_or_null("/root/AchievementsManager")
	game_modes = get_node_or_null("/root/GameModes")
	ad_manager = get_node_or_null("/root/AdvertisementManager")
	music_manager = get_node_or_null("/root/MusicManager")
	
	
	# Добавляем элементы в группы для применения шрифтов
	if score_label:
		score_label.add_to_group("ui_labels")
	if best_score_label:
		best_score_label.add_to_group("ui_labels")
	if coins_label:
		coins_label.add_to_group("ui_labels")
	if time_label:
		time_label.add_to_group("ui_labels")
	if moves_label:
		moves_label.add_to_group("ui_labels")
	if final_score_label:
		final_score_label.add_to_group("ui_labels")
	
	# Добавляем кнопки в группу
	if restart_button:
		restart_button.add_to_group("buttons")
	if undo_button:
		undo_button.add_to_group("buttons")
	if menu_button:
		menu_button.add_to_group("buttons")
	if new_game_button:
		new_game_button.add_to_group("buttons")
	if settings_button:
		settings_button.add_to_group("buttons")
	
	# Настраиваем TTF шрифты
	setup_ttf_font()
	
	# Инициализируем UI
	update_score()
	update_best_score()
	update_coins()
	game_over_panel.visible = false
	settings_panel.visible = false
	if undo_button:
		undo_button.disabled = true
	if time_label:
		time_label.visible = false
	if moves_label:
		moves_label.visible = false
	
	# Настраиваем UI настроек
	setup_settings_ui()
	
	# Создаем фон сетки
	create_grid_background()
	print("Grid background created")
	
	# Инициализируем сетку
	initialize_grid()
	print("Grid initialized")
	
	# Настраиваем адаптивный UI
	setup_responsive_ui()
	
	# Настраиваем TTF шрифты
	setup_ttf_font()
	
	# Подключаем сигналы
	connect_signals()
	
	# Обновляем тексты на текущем языке
	update_ui_texts()
	
	# Настраиваем touch controls
	setup_touch_controls()
	
	# Отключаем фокус для всех кнопок
	disable_button_focus()
	
	# Перемещаем кнопки слева от сетки
	reposition_buttons_left()
	
	# Принудительно обновляем UI
	update_ui_layout()
	update_tile_positions()
	
	call_deferred("update_ui_layout")
	call_deferred("update_tile_positions")
	call_deferred("check_grid_visibility")

func reposition_buttons_left():
	# Перемещаем контейнер с кнопками влево от игрового поля
	if buttons_container and grid_background:
		var _screen_size = get_viewport().get_visible_rect().size
		var grid_pos = grid_background.position
		var _grid_width = (TILE_SIZE + TILE_SPACING) * GRID_SIZE + TILE_SPACING
		var grid_height = (TILE_SIZE + TILE_SPACING) * GRID_SIZE + TILE_SPACING
		var grid_scale = grid_background.scale.x
		
		# Размещаем кнопки слева от сетки с небольшим отступом
		buttons_container.position = Vector2(
			max(20, grid_pos.x - buttons_container.size.x * grid_scale - 20 * grid_scale),  # слева от сетки или у края экрана
			grid_pos.y + (grid_height * grid_scale - buttons_container.size.y * grid_scale) / 2  # по вертикали центрируем
		)
		buttons_container.scale = Vector2(grid_scale, grid_scale)

func _on_splash_timer_timeout():
	hide_custom_splash()
	
	# После скрытия заставки запускаем игру
	start_game_after_splash()

func start_game_after_splash():
	# Проверяем, нужно ли продолжить игру
	var should_continue = false
	if game_data and game_data.has_method("should_continue_game"):
		should_continue = game_data.should_continue_game()
		print("Should continue game: ", should_continue)
		game_data.reset_continue_game()  # Сбрасываем флаг
	
	# Запускаем музыку, если включена
	if music_manager:
		if music_manager.has_method("play_music"):
			music_manager.play_music("game")
		if music_manager.has_method("set_volume"):
			music_manager.set_volume(music_volume)
	
	# Запускаем вращение фона, если включено
	if game_data and game_data.background_rotation_enabled:
		start_background_timer()
	
	# Захватываем фокус
	if focus_capture is Control:
		focus_capture.focus_mode = Control.FOCUS_ALL
		focus_capture.grab_focus()
	
	# Настраиваем киберпанк кнопки
	call_deferred("setup_cyberpunk_buttons")
	
	# Запускаем игру
	if should_continue:
		print("Loading saved game...")
		load_saved_game()
	else:
		print("Starting new game...")
		start_new_game()
	
	print("Main scene initialization finished")

func update_ui_layout():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Рассчитываем реальные размеры сетки (в пикселях) без масштаба
	var grid_width = (TILE_SIZE + TILE_SPACING) * GRID_SIZE + TILE_SPACING
	var grid_height = (TILE_SIZE + TILE_SPACING) * GRID_SIZE + TILE_SPACING
	
	# Рассчитываем масштаб для вписывания в экран с отступами
	var max_scale_x = (screen_size.x - 80) / grid_width  # 40px отступ с каждой стороны
	var max_scale_y = (screen_size.y - 160) / grid_height  # 80px отступ сверху и снизу
	var grid_scale = min(max_scale_x, max_scale_y, 1.0)
	
	# Центрируем grid_background
	if grid_background:
		grid_background.position = Vector2(
			(screen_size.x - grid_width * grid_scale) / 2,
			(screen_size.y - grid_height * grid_scale) / 2
		)
		grid_background.scale = Vector2(grid_scale, grid_scale)
	
	# Центрируем tiles_container относительно grid_background
	if tiles_container and grid_background:
		tiles_container.position = grid_background.position
		tiles_container.scale = grid_background.scale
	
	# Центрируем верхнюю панель с монетами и рекордом
	if hbox_container:
		hbox_container.position = Vector2(
			(screen_size.x - hbox_container.size.x * grid_scale) / 2,
			20 * grid_scale
		)
		hbox_container.scale = Vector2(grid_scale, grid_scale)
	
	# Перемещаем кнопки слева от сетки
	reposition_buttons_left()
	
	# Центрируем панель настроек и игрового окна
	if game_over_panel:
		game_over_panel.position = Vector2(
			(screen_size.x - game_over_panel.size.x) / 2,
			(screen_size.y - game_over_panel.size.y) / 2
		)
	
	if settings_panel:
		settings_panel.position = Vector2(
			(screen_size.x - settings_panel.size.x) / 2,
			(screen_size.y - settings_panel.size.y) / 2
		)
	
	# Принудительно обновляем позиции плиток
	update_tile_positions()

func setup_ttf_font():
	# Загружаем шрифт
	var font_paths = [
		"res://assets/fonts/orbitron.ttf",
		"res://assets/fonts/roboto-bold.ttf"
	]
	
	var font = null
	for path in font_paths:
		if ResourceLoader.exists(path):
			font = load(path)
			if font:
				print("Loaded font from: ", path)
				break
	
	if not font:
		print("No TTF fonts found, using default font")
		return
	
	# Применяем шрифт ко всем элементам интерфейса
	for label in get_tree().get_nodes_in_group("ui_labels"):
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.4))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color(0.2, 0.2, 0.2, 0.8))
	
	for button in get_tree().get_nodes_in_group("buttons"):
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 16)
	
	if font:
		# Применяем шрифт ко всем элементам интерфейса
		for label in get_tree().get_nodes_in_group("ui_labels"):
			label.add_theme_font_override("font", font)
		
		for button in get_tree().get_nodes_in_group("buttons"):
			button.add_theme_font_override("font", font)
		
		print("TTF font applied successfully")
		
		# Fallback - используем встроенный шрифт
		var fallback_font = ThemeDB.fallback_font
		if fallback_font:
			for label in get_tree().get_nodes_in_group("ui_labels"):
				label.add_theme_font_override("font", fallback_font)
			for button in get_tree().get_nodes_in_group("buttons"):
				button.add_theme_font_override("font", fallback_font)
			print("Using fallback font")
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.border_width_bottom = 2
	button_style.border_width_top = 2
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_color = Color(0.5, 0.5, 0.5)
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.8, 0.75, 0.7, 0.9)
	button_hover_style.corner_radius_top_left = 10
	button_hover_style.corner_radius_top_right = 10
	button_hover_style.corner_radius_bottom_right = 10
	button_hover_style.corner_radius_bottom_left = 10
	button_hover_style.border_width_bottom = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_color = Color(0.6, 0.56, 0.52)
	
	for button in get_tree().get_nodes_in_group("buttons"):
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_stylebox_override("hover", button_hover_style)
		button.add_theme_stylebox_override("pressed", button_style)
		button.add_theme_stylebox_override("disabled", button_style)
		button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		button.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
		button.add_theme_color_override("font_pressed_color", Color(0.3, 0.3, 0.3))
		button.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7))
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_constant_override("outline_size", 1)
		button.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
	
	var label_font = resource_cache.fonts.roboto_bold
	
	for label in get_tree().get_nodes_in_group("labels"):
		if label_font:
			label.add_theme_font_override("font", label_font)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.4))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))

func connect_signals():
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	undo_button.pressed.connect(_on_undo_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	
	# Connect settings signals
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
	if music_checkbox:
		music_checkbox.toggled.connect(_on_music_checkbox_toggled)
	if background_option:
		background_option.item_selected.connect(_on_background_option_selected)
	if language_option:
		language_option.item_selected.connect(_on_language_option_selected)
	if close_settings_button:
		close_settings_button.pressed.connect(_on_close_settings_button_pressed)
	
	# Connect ad manager signals if available
	if ad_manager and ad_manager.has_signal("ad_completed"):
		ad_manager.ad_completed.connect(_on_ad_completed)
	
func create_settings_panel():
	# Объявляем стили для кнопок в начале функции
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.border_width_bottom = 2
	button_style.border_width_top = 2
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_color = Color(0.5, 0.5, 0.5)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.4, 0.4, 0.4, 0.9)
	
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	
	# Создаем основную панель настроек
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.size = Vector2(400, 500)
	settings_panel.visible = false
	
	# Создаем стиль для панели - темный с полупрозрачностью
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.border_width_bottom = 3
	panel_style.border_width_top = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.5, 0.5, 0.5)
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	$UI.add_child(settings_panel)
	
	# Создаем контейнер для элементов настроек
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size = Vector2(380, 480)
	vbox.position = Vector2(10, 10)
	settings_panel.add_child(vbox)
	
	# Заголовок настроек
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title_label)
	
	# Разделитор
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Создаем элементы управления громкостью музыки
	var music_hbox = HBoxContainer.new()
	music_hbox.name = "MusicHBox"
	var music_label = Label.new()
	music_label.name = "MusicLabel"
	music_label.add_theme_color_override("font_color", Color(1, 1, 1))
	music_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider = HSlider.new()
	music_slider.name = "MusicSlider"
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.1
	music_slider.value = music_volume
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_hbox.add_child(music_label)
	music_hbox.add_child(music_slider)
	vbox.add_child(music_hbox)
	
	# Создаем элементы управления включением/выключением музыки
	var music_toggle_hbox = HBoxContainer.new()
	music_toggle_hbox.name = "MusicToggleHBox"
	var music_toggle_label = Label.new()
	music_toggle_label.name = "MusicToggleLabel"
	music_toggle_label.add_theme_color_override("font_color", Color(1, 1, 1))
	music_toggle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_checkbox = CheckBox.new()
	music_checkbox.name = "MusicCheckBox"
	music_checkbox.button_pressed = music_enabled
	music_toggle_hbox.add_child(music_toggle_label)
	music_toggle_hbox.add_child(music_checkbox)
	vbox.add_child(music_toggle_hbox)
	
	# Создаем элементы выбора фона
	var background_hbox = HBoxContainer.new()
	background_hbox.name = "BackgroundHBox"
	var background_label = Label.new()
	background_label.name = "BackgroundLabel"
	background_label.add_theme_color_override("font_color", Color(1, 1, 1))
	background_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background_option = OptionButton.new()
	background_option.name = "BackgroundOption"
	background_hbox.add_child(background_label)
	background_hbox.add_child(background_option)
	vbox.add_child(background_hbox)
	
	# Создаем элементы выбора языка
	var language_hbox = HBoxContainer.new()
	language_hbox.name = "LanguageHBox"
	var language_label = Label.new()
	language_label.name = "LanguageLabel"
	language_label.add_theme_color_override("font_color", Color(1, 1, 1))
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_option = OptionButton.new()
	language_option.name = "LanguageOption"
	language_hbox.add_child(language_label)
	language_hbox.add_child(language_option)
	vbox.add_child(language_hbox)
	
	# Кнопка закрытия
	close_settings_button = Button.new()
	close_settings_button.name = "CloseSettingsButton"
	close_settings_button.add_theme_color_override("font_color", Color(1, 1, 1))
	close_settings_button.add_theme_stylebox_override("normal", button_style)
	close_settings_button.add_theme_stylebox_override("hover", button_hover_style)
	close_settings_button.add_theme_stylebox_override("pressed", button_pressed_style)
	vbox.add_child(close_settings_button)
	
	# Кнопка возврата в главное меню
	back_to_menu_button = Button.new()
	back_to_menu_button.name = "BackToMenuButton"
	back_to_menu_button.add_theme_color_override("font_color", Color(1, 1, 1))
	back_to_menu_button.add_theme_stylebox_override("normal", button_style)
	back_to_menu_button.add_theme_stylebox_override("hover", button_hover_style)
	back_to_menu_button.add_theme_stylebox_override("pressed", button_pressed_style)
	vbox.add_child(back_to_menu_button)
	
	# Центрируем панель настроек
	var viewport_size = get_viewport().get_visible_rect().size
	settings_panel.position = Vector2(
		(viewport_size.x - settings_panel.size.x) / 2,
		(viewport_size.y - settings_panel.size.y) / 2
	)
	
	# Подключаем кнопку возврата в меню
	back_to_menu_button.pressed.connect(_on_back_to_menu_button_pressed)
	
	# Отключаем фокус для кнопок в настройках
	close_settings_button.focus_mode = Control.FOCUS_NONE
	back_to_menu_button.focus_mode = Control.FOCUS_NONE

func _get_music_manager():
	return get_node_or_null("/root/MusicManager")

func load_player_settings():
	# Используем WebBus для загрузки настроек если доступен
	if OS.has_feature('web') and web_bus and web_bus.has_method("loadData"):
		var settings_data_str = web_bus.loadData("player_settings")
		if settings_data_str and settings_data_str != "":
			var settings_data = JSON.parse_string(settings_data_str)
			if settings_data:
				music_volume = settings_data.get("music_volume", 0.5)
				music_enabled = settings_data.get("music_enabled", true)
				background_index = settings_data.get("background_index", 0)
				language_index = settings_data.get("language_index", 0)
				current_language = settings_data.get("language", "en")
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			music_volume = config.get_value("audio", "music_volume", 0.5)
			music_enabled = config.get_value("audio", "music_enabled", true)
			background_index = config.get_value("video", "background_index", 0)
			language_index = config.get_value("ui", "language_index", 0)
			current_language = config.get_value("ui", "language", "en")
		
	# Apply background setting
	if background_index < background_textures.size():
		background.texture = background_textures[background_index]
		current_bg_index = background_index
		
	# Apply music settings to MusicManager
	if music_manager:
		if music_manager.has_method("set_volume"):
			music_manager.set_volume(music_volume)
		if music_manager.has_method("set_music_enabled"):
			music_manager.set_music_enabled(music_enabled)

func save_player_settings():
	var settings_data = {
		"music_volume": music_volume,
		"music_enabled": music_enabled,
		"background_index": background_index,
		"language_index": language_index,
		"language": current_language
	}
	
	# Используем WebBus для сохранения если доступен
	if OS.has_feature('web') and web_bus and web_bus.has_method("saveData"):
		web_bus.saveData("player_settings", JSON.stringify(settings_data))
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", music_volume)
		config.set_value("audio", "music_enabled", music_enabled)
		config.set_value("video", "background_index", background_index)
		config.set_value("ui", "language_index", language_index)
		config.set_value("ui", "language", current_language)
		config.save("user://player_settings.cfg")

func setup_settings_ui():
	# Set initial values for settings UI
	music_slider.value = music_volume
	music_checkbox.button_pressed = music_enabled
	
	# Fill background options
	background_option.clear()
	for i in range(background_textures.size()):
		background_option.add_item("Background " + str(i + 1), i)
	background_option.selected = background_index
	
	# Fill language options
	language_option.clear()
	for i in range(languages.size()):
		language_option.add_item(languages[i], i)
	language_option.selected = language_index

func update_ui_texts():
	# Update settings panel texts
	if settings_panel:
		var title_label = settings_panel.get_node("VBoxContainer/TitleLabel")
		if title_label:
			title_label.text = translate("settings_title")
		
		var music_label = settings_panel.get_node("VBoxContainer/MusicHBox/MusicLabel")
		if music_label:
			music_label.text = translate("music_volume")
		
		var music_toggle_label = settings_panel.get_node("VBoxContainer/MusicToggleHBox/MusicToggleLabel")
		if music_toggle_label:
			music_toggle_label.text = translate("music_enabled")
		
		var background_label = settings_panel.get_node("VBoxContainer/BackgroundHBox/BackgroundLabel")
		if background_label:
			background_label.text = translate("background")
		
		var language_label = settings_panel.get_node("VBoxContainer/LanguageHBox/LanguageLabel")
		if language_label:
			language_label.text = translate("language")
		
		var close_button = settings_panel.get_node("VBoxContainer/CloseSettingsButton")
		if close_button:
			close_button.text = translate("close")
		
		if back_to_menu_button:
			back_to_menu_button.text = translate("back_to_menu")
	
	# Update main UI texts
	score_label.text = translate("score") + ": " + str(score)
	best_score_label.text = translate("best") + ": " + str(best_score)
	coins_label.text = str(game_data.player_coins) + " " + translate("coins") if game_data else "0 " + translate("coins")
	time_label.text = translate("time") + ": 0"
	moves_label.text = translate("moves") + ": 0"
	final_score_label.text = translate("final_score") + ": " + str(score)
	
	restart_button.text = translate("restart")
	undo_button.text = translate("undo")
	menu_button.text = translate("menu")
	new_game_button.text = translate("new_game")
	settings_button.text = translate("settings")
	
	# Update game over panel
	var game_over_label = game_over_panel.get_node("VBoxContainer/GameOverLabel")
	if game_over_label:
		game_over_label.text = translate("game_over")
	
	var continue_button = game_over_panel.get_node("VBoxContainer/ContinueButton")
	if continue_button:
		continue_button.text = translate("continue")
	
	var quit_button = game_over_panel.get_node("VBoxContainer/QuitButton")
	if quit_button:
		quit_button.text = translate("quit")

func translate(key):
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	elif translations.has("en") and translations["en"].has(key):
		return translations["en"][key]
	else:
		return key

func update_best_score_display(new_best):
	best_score_label.text = translate("best") + ": " + str(new_best)

func update_best_score():
	if game_data and score > game_data.best_score:
		game_data.set_best_score(score)
		update_best_score_display(score)

func update_coins():
	if game_data:
		coins_label.text = str(game_data.player_coins) + " " + translate("coins")
		
func create_grid_background():
	print("Creating grid background...")
	for child in grid_background.get_children():
		child.queue_free()
	
func check_grid_visibility():
	# Принудительно обновляем отображение сетки
	create_grid_background()
	update_tile_positions()
	# Обновляем UI
	update_ui_layout()
	# Создаем фон для всей сетки
	var grid_bg = ColorRect.new()
	grid_bg.color = Color(0.8, 0.75, 0.7, 0.5)  # Увеличиваем непрозрачность
	grid_bg.size = Vector2(grid_width, grid_height)
	grid_bg.position = Vector2(0, 0)
	grid_background.add_child(grid_bg)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var cell_bg = ColorRect.new()
			cell_bg.color = Color(0.73, 0.68, 0.62, 0.8)  # Увеличиваем непрозрачность
			cell_bg.size = Vector2(TILE_SIZE, TILE_SIZE)
			cell_bg.position = Vector2(
				x * (TILE_SIZE + TILE_SPACING) + TILE_SPACING,
				y * (TILE_SIZE + TILE_SPACING) + TILE_SPACING
			)
			
			# Добавляем обводку для лучшей видимости
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.73, 0.68, 0.62, 0.8)
			style.border_width_bottom = 2
			style.border_width_top = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_color = Color(0.6, 0.55, 0.5)
			cell_bg.add_theme_stylebox_override("panel", style)
			grid_background.add_child(cell_bg)
	
	print("Grid background created with ", GRID_SIZE * GRID_SIZE, " cells")

func initialize_grid():
	grid = []
	for x in range(GRID_SIZE):
		grid.append([])
		for y in range(GRID_SIZE):
			grid[x].append(null)
	
	for child in tiles_container.get_children():
		child.queue_free()

func start_new_game():
	# Reset game state
	score = 0
	game_over = false
	game_started = true
	moving_tiles = 0
	previous_states = []
	can_undo = false
	continue_available = false
	continue_state = null
	max_tile_value = 0
	game_start_time = Time.get_unix_time_from_system()
	moves_count = 0
	merges_in_current_move = 0
	used_undo_in_game = false
	
	# Clear the grid
	initialize_grid()
	
	# Spawn initial tiles
	spawn_random_tile()
	spawn_random_tile()
	
	# Update UI
	update_score()
	update_coins()
	game_over_panel.visible = false
	undo_button.disabled = true
	
	# Notify achievements manager
	if achievements_manager and achievements_manager.has_method("on_game_start"):
		achievements_manager.on_game_start()
	
	# Start game mode specific timers/counters
	if game_modes and game_modes.has_method("start_game"):
		game_modes.start_game()
		
		# Show/hide mode-specific UI
		if game_modes.current_mode == 0:  # CLASSIC
			time_label.visible = true
			moves_label.visible = false
		elif game_modes.current_mode == 2:  # LIMITED
			time_label.visible = false
			moves_label.visible = true
			moves_label.text = translate("moves") + ": " + str(game_modes.moves_left)
		else:
			time_label.visible = false
			moves_label.visible = false

func restart_game():
	start_new_game()

func undo_move():
	if can_undo and previous_states.size() > 0:
		var previous_state = previous_states.pop_back()
		restore_state(previous_state)
		can_undo = false
		undo_button.disabled = true
		used_undo_in_game = true
		
		# Notify achievements manager
		if achievements_manager and achievements_manager.has_method("on_move"):
			achievements_manager.on_move(Vector2i.ZERO, 0, true)
	elif ad_manager and ad_manager.has_method("show_advertisement"):
		ad_manager.show_advertisement(AdType.UNDO)

func continue_game():
	if continue_available and continue_state:
		restore_state(continue_state)
		continue_available = false
		game_over = false
		game_over_panel.visible = false
	elif ad_manager and ad_manager.has_method("show_advertisement"):
		ad_manager.show_advertisement(AdType.CONTINUE)

func save_state():
	var state = {
		"grid": [],
		"score": score,
		"max_tile_value": max_tile_value
	}
	
	for x in range(GRID_SIZE):
		state.grid.append([])
		for y in range(GRID_SIZE):
			if grid[x][y]:
				state.grid[x].append({
					"value": grid[x][y].value,
					"position": grid[x][y].grid_position
				})
			else:
				state.grid[x].append(null)
	
	return state

func restore_state(state):
	# Clear current tiles
	for child in tiles_container.get_children():
		child.queue_free()
	
	# Restore grid state
	score = state.score
	max_tile_value = state.max_tile_value
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			grid[x][y] = null
			
			if state.grid[x][y]:
				var tile_data = state.grid[x][y]
				spawn_tile(tile_data.value, Vector2i(x, y))
	
	update_score()
	update_best_score()
	update_coins()

func spawn_random_tile():
	var empty_cells = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == null:
				empty_cells.append(Vector2i(x, y))
	
	if empty_cells.size() > 0:
		var random_cell = empty_cells[randi() % empty_cells.size()]
		var value = 2 if randf() < 0.9 else 4
		spawn_tile(value, random_cell)
		
		# Notify achievements manager
		if achievements_manager and achievements_manager.has_method("on_tile_created"):
			achievements_manager.on_tile_created(value)
		
		return true
	
	return false

func spawn_tile(value, tile_position):
	var tile = resource_cache.tile_scene.instantiate()
	tiles_container.add_child(tile)
	tile.initialize(value, tile_position)
	grid[tile_position.x][tile_position.y] = tile
	tile.spawn_animation()
	
	if value > max_tile_value:
		max_tile_value = value

func move(direction):
	if is_moving or game_over:
		return
	
	# Save current state for undo
	previous_states.append(save_state())
	if previous_states.size() > 5:  # Limit undo history
		previous_states.pop_front()
	
	can_undo = true
	undo_button.disabled = false
	is_moving = true
	moves_count += 1
	merges_in_current_move = 0
	
	var moved = false
	var merged = false
	
	# Process movement based on direction
	match direction:
		Vector2i.UP:
			moved = move_up()
		Vector2i.DOWN:
			moved = move_down()
		Vector2i.LEFT:
			moved = move_left()
		Vector2i.RIGHT:
			moved = move_right()
	
	# Notify achievements manager
	if achievements_manager and achievements_manager.has_method("on_move"):
		achievements_manager.on_move(direction, merges_in_current_move, used_undo_in_game)
	
	# Notify game modes manager
	if game_modes and game_modes.has_method("on_move"):
		game_modes.on_move()
		if game_modes.current_mode == 2:  # LIMITED
			moves_label.text = translate("moves") + ": " + str(game_modes.moves_left)
	
	# If any movement happened, spawn a new tile
	if moved or merged:
		await get_tree().create_timer(ANIMATION_DURATION * 1.5).timeout
		if not spawn_random_tile():
			# If no empty cells, check if game is over
			check_game_over()
	
	is_moving = false

func move_up():
	var moved = false
	for x in range(GRID_SIZE):
		for y in range(1, GRID_SIZE):
			if grid[x][y] != null:
				var new_y = y
				while new_y > 0 and grid[x][new_y - 1] == null:
					new_y -= 1
				
				if new_y > 0 and grid[x][new_y - 1] != null and grid[x][new_y - 1].value == grid[x][y].value:
					# Merge tiles
					merge_tiles(grid[x][y], grid[x][new_y - 1])
					moved = true
				elif new_y != y:
					# Move tile
					move_tile(grid[x][y], Vector2i(x, new_y))
					moved = true
	return moved

func move_down():
	var moved = false
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE - 2, -1, -1):
			if grid[x][y] != null:
				var new_y = y
				while new_y < GRID_SIZE - 1 and grid[x][new_y + 1] == null:
					new_y += 1
				
				if new_y < GRID_SIZE - 1 and grid[x][new_y + 1] != null and grid[x][new_y + 1].value == grid[x][y].value:
					# Merge tiles
					merge_tiles(grid[x][y], grid[x][new_y + 1])
					moved = true
				elif new_y != y:
					# Move tile
					move_tile(grid[x][y], Vector2i(x, new_y))
					moved = true
	return moved



func move_left():
	var moved = false
	for y in range(GRID_SIZE):
		for x in range(1, GRID_SIZE):
			if grid[x][y] != null:
				var new_x = x
				while new_x > 0 and grid[new_x - 1][y] == null:
					new_x -= 1
				
				if new_x > 0 and grid[new_x - 1][y] != null and grid[new_x - 1][y].value == grid[x][y].value:
					# Merge tiles
					merge_tiles(grid[x][y], grid[new_x - 1][y])
					moved = true
				elif new_x != x:
					# Move tile
					move_tile(grid[x][y], Vector2i(new_x, y))
					moved = true
	return moved

func move_right():
	var moved = false
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE - 2, -1, -1):
			if grid[x][y] != null:
				var new_x = x
				while new_x < GRID_SIZE - 1 and grid[new_x + 1][y] == null:
					new_x += 1
				
				if new_x < GRID_SIZE - 1 and grid[new_x + 1][y] != null and grid[new_x + 1][y].value == grid[x][y].value:
					# Merge tiles
					merge_tiles(grid[x][y], grid[new_x + 1][y])
					moved = true
				elif new_x != x:
					# Move tile
					move_tile(grid[x][y], Vector2i(new_x, y))
					moved = true
	return moved

func move_tile(tile, new_position):
	grid[tile.grid_position.x][tile.grid_position.y] = null
	grid[new_position.x][new_position.y] = tile
	tile.move_to(new_position)

func merge_tiles(source_tile, target_tile):
	grid[source_tile.grid_position.x][source_tile.grid_position.y] = null
	source_tile.merge_to(target_tile)
	score += target_tile.value * 2
	merges_in_current_move += 1
	update_score()
	update_best_score()

func check_game_over():
	# Check if any moves are possible
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == null:
				return  # There's an empty cell, game can continue
			
			# Check adjacent tiles for possible merges
			if x < GRID_SIZE - 1 and grid[x + 1][y] != null and grid[x][y].value == grid[x + 1][y].value:
				return
			if y < GRID_SIZE - 1 and grid[x][y + 1] != null and grid[x][y].value == grid[x][y + 1].value:
				return
	
	# No moves possible, game over
	game_over = true
	game_over_panel.visible = true
	final_score_label.text = translate("final_score") + ": " + str(score)
	
	# Save continue state
	continue_state = save_state()
	continue_available = true
	
	save_game()
	
	# Notify achievements manager
	if achievements_manager and achievements_manager.has_method("on_game_end"):
		var game_time = Time.get_unix_time_from_system() - game_start_time
		achievements_manager.on_game_end(score, used_undo_in_game, max_tile_value, game_time)

func update_score():
	score_label.text = translate("score") + ": " + str(score)

func start_background_timer():
	if bg_timer:
		bg_timer.stop()
		bg_timer.queue_free()
	
	bg_timer = Timer.new()
	bg_timer.wait_time = 10.0  # Change background every 10 seconds
	bg_timer.timeout.connect(_on_background_timer_timeout)
	add_child(bg_timer)
	bg_timer.start()

func _on_background_timer_timeout():
	current_bg_index = (current_bg_index + 1) % background_textures.size()
	background.texture = background_textures[current_bg_index]

func _input(event):
	if event is InputEventKey and is_window_focused:
		if event.pressed and not event.is_echo():
			match event.keycode:
				KEY_UP, KEY_W:
					move(Vector2i.UP)
				KEY_DOWN, KEY_S:
					move(Vector2i.DOWN)
				KEY_LEFT, KEY_A:
					move(Vector2i.LEFT)
				KEY_RIGHT, KEY_D:
					move(Vector2i.RIGHT)
	
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start_position = event.position
			swiping = true
		else:
			swiping = false
	
	elif event is InputEventScreenDrag and swiping:
		touch_end_position = event.position
		var swipe = touch_end_position - touch_start_position
		
		if swipe.length() > SWIPE_MIN_DISTANCE:
			swiping = false
			
			if abs(swipe.x) > abs(swipe.y):
				if swipe.x > 0:
					move(Vector2i.RIGHT)
				else:
					move(Vector2i.LEFT)
			else:
				if swipe.y > 0:
					move(Vector2i.DOWN)
				else:
					move(Vector2i.UP)

func _on_restart_button_pressed():
	restart_game()

func _on_undo_button_pressed():
	undo_move()

func _on_menu_button_pressed():
	save_game()
	if OS.has_feature('web'):
		get_tree().change_scene_to_packed(preload("res://scenes/main_menu.tscn"))
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_new_game_button_pressed():
	start_new_game()

func save_game():
	if game_over:  # Не сохраняем если игра уже завершена
		return
		
	var save_data = save_state()
	
	# Сохраняем через WebBus для веба
	if OS.has_feature('web') and web_bus and web_bus.has_method("saveData"):
		web_bus.saveData("game_save", JSON.stringify(save_data))
		print("Game saved via WebBus")
	else:
		# Локальное сохранение для десктоп версии
		var file = FileAccess.open("user://game_save.dat", FileAccess.WRITE)
		if file:
			file.store_var(save_data)
			file.close()
			print("Game saved locally")
		

func _on_settings_button_pressed():
	settings_panel.visible = true
	# При открытии настроек возвращаем фокус кнопкам
	for button in get_tree().get_nodes_in_group("buttons"):
		button.focus_mode = Control.FOCUS_ALL

func _on_music_slider_changed(value):
	print("Изменение громкости музыки: ", value)
	music_volume = value
	if music_manager and music_manager.has_method("set_volume"):
		music_manager.set_volume(music_volume)
		print("Громкость установлена: ", value)
	else:
		print("Ошибка: MusicManager не найден или не имеет метода set_volume")
	save_player_settings()

func _on_music_checkbox_toggled(button_pressed):
	print("Переключение музыки: ", button_pressed)
	music_enabled = button_pressed
	if music_manager and music_manager.has_method("set_music_enabled"):
		music_manager.set_music_enabled(music_enabled)
		print("Музыка ", "включена" if button_pressed else "выключена")
	else:
		print("Ошибка: MusicManager не найден или не имеет метода set_music_enabled")
	save_player_settings()

func _on_background_option_selected(index):
	background_index = index
	if background_index < background_textures.size():
		background.texture = background_textures[background_index]
		current_bg_index = background_index
	save_player_settings()

func _on_language_option_selected(index):
	language_index = index
	if index < language_codes.size():
		current_language = language_codes[index]
		update_ui_texts()
		save_player_settings()

func _on_close_settings_button_pressed():
	settings_panel.visible = false
	# При закрытии настроек снова отключаем фокус кнопок
	disable_button_focus()
	call_deferred("setup_cyberpunk_buttons")

func _on_back_to_menu_button_pressed():
	save_game()
	if OS.has_feature('web'):
		get_tree().change_scene_to_packed(preload("res://scenes/main_menu.tscn"))
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_ad_completed(ad_type, reward):
	if ad_type == AdType.UNDO:
		undo_move()
	elif ad_type == AdType.CONTINUE:
		continue_game()
	elif ad_type == AdType.REWARD_COINS or ad_type == AdType.DAILY_REWARD:
		if game_data:
			game_data.add_coins(reward)
			update_coins()

func _on_window_focus_entered():
	is_window_focused = true
	if music_manager and music_manager.has_method("resume_music"):
		music_manager.resume_music()

func _on_window_focus_exited():
	is_window_focused = false
	if music_manager and music_manager.has_method("pause_music"):
		music_manager.pause_music()
	
	# Для веб-платформы также сохраняем игру при потере фокуса
	if OS.has_feature('web'):
		save_game()

# Добавьте эти функции в main.gd и MainMenu.gd

func setup_cyberpunk_buttons():
	print("Setting up cyberpunk buttons...")
	
	# Небольшая задержка для гарантии, что все кнопки загружены
	await get_tree().process_frame
	
	var buttons = get_tree().get_nodes_in_group("buttons")
	print("Found ", buttons.size(), " buttons in group")
	
	# Выводим имена всех кнопок в группе
	for button in buttons:
		print("Button in group: ", button.name)
	
	if buttons.size() == 0:
		print("No buttons found in group, trying alternative approach...")
		# Альтернативный подход: получаем кнопки напрямую
		buttons = []
		var game_buttons = [restart_button, undo_button, menu_button, new_game_button, settings_button]
		for button in game_buttons:
			if button:
				buttons.append(button)
				print("Added button directly: ", button.name)
		
		# Также добавляем кнопки из game_over_panel
		var continue_button = game_over_panel.get_node("VBoxContainer/ContinueButton") as Button
		var quit_button = game_over_panel.get_node("VBoxContainer/QuitButton") as Button
		if continue_button:
			buttons.append(continue_button)
			print("Added continue button directly: ", continue_button.name)
		if quit_button:
			buttons.append(quit_button)
			print("Added quit button directly: ", quit_button.name)
	
	# УБИРАЕМ объявление var main_styles здесь
	if main_styles and main_styles.has_method("setup_cyberpunk_buttons"):
		main_styles.setup_cyberpunk_buttons(buttons)
	else:
		setup_cyberpunk_buttons_fallback(buttons)


func setup_cyberpunk_buttons_fallback(buttons: Array):
	# Резервная функция на случай, если CyberpunkUI не загружен
	for button in buttons:
		button.queue_redraw()
		print("Button in group: ", button.name)
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
	print("Button hovered: ", button.name)

func _on_cyberpunk_button_pressed(button: Button):
	print("Button pressed: ", button.name)

func _on_cyberpunk_button_released(button: Button):
	print("Button released: ", button.name)
