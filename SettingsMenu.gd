# SettingsMenu.gd
extends Control

@onready var music_toggle = $VBoxContainer/MusicToggle
@onready var music_slider = $VBoxContainer/MusicSlider
@onready var language_option = $VBoxContainer/LanguageOption
@onready var back_button = $VBoxContainer/BackButton

var music_manager
var device_manager
var web_bus

# Добавляем объявления недостающих переменных
var music_volume = 0.5
var music_enabled = true

# Языковые настройки
var languages = ["English", "Russian", "Spanish", "French", "German"]
var language_codes = ["en", "ru", "es", "fr", "de"]
var current_language = "en"

func _ready():
	# Получаем DeviceManager
	device_manager = get_node_or_null("/root/DeviceManager")
	
	# Получаем экземпляр MusicManager
	music_manager = get_node_or_null("/root/MusicManager")
	
	# Получаем WebBus если доступен
	web_bus = get_node_or_null("/root/WebBus")
	
	# Загружаем настройки
	load_settings()
	
	# Добавляем элементы в группу для стилизации
	add_controls_to_group()
	
	# Настраиваем адаптивный интерфейс
	setup_responsive_ui()
	
	# Применяем киберпанк стиль
	setup_cyberpunk_style()
	
	# Подключаем сигналы
	music_toggle.toggled.connect(_on_music_toggle_toggled)
	music_slider.value_changed.connect(_on_music_slider_changed)
	language_option.item_selected.connect(_on_language_option_selected)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Устанавливаем начальные значения для элементов управления
	music_slider.value = music_volume
	music_toggle.button_pressed = music_enabled
	
	# Для веб-версии добавляем обработку видимости окна
	if OS.has_feature('web'):
		get_tree().get_root().get_window().visibility_changed.connect(_on_visibility_changed)
	
	# Подключаем обработчик изменения размера экрана
	get_viewport().size_changed.connect(_on_screen_resized)

func _on_visibility_changed():
	if OS.has_feature('web'):
		if get_tree().get_root().get_window().visible:
			# Окно стало видимым - возобновляем музыку
			if music_manager and music_enabled:
				music_manager.resume_music()
		else:
			# Окно стало невидимым - приостанавливаем музыку
			if music_manager and music_manager.is_playing():
				music_manager.pause_music()

func add_controls_to_group():
	# Добавляем все элементы управления в группу
	for control in [music_toggle, music_slider, language_option, back_button]:
		if control:
			control.add_to_group("settings_controls")
			print("Added to settings_controls group: ", control.name)

func setup_cyberpunk_style():
	print("Setting up cyberpunk style for settings menu...")
	
	# Проверяем, что CyberpunkUI загружен
	if has_node("/root/CyberpunkUI"):
		var cyberpunk_ui = get_node("/root/CyberpunkUI")
		var controls = get_tree().get_nodes_in_group("settings_controls")
		cyberpunk_ui.setup_cyberpunk_buttons(controls)
		
		# Подключаем сигналы, если нужно обрабатывать события
		if not cyberpunk_ui.button_hovered.is_connected(_on_cyberpunk_button_hovered):
			cyberpunk_ui.button_hovered.connect(_on_cyberpunk_button_hovered)
		if not cyberpunk_ui.button_pressed.is_connected(_on_cyberpunk_button_pressed):
			cyberpunk_ui.button_pressed.connect(_on_cyberpunk_button_pressed)
		if not cyberpunk_ui.button_released.is_connected(_on_cyberpunk_button_released):
			cyberpunk_ui.button_released.connect(_on_cyberpunk_button_released)
	else:
		print("CyberpunkUI not found, using fallback styling")
		setup_cyberpunk_style_fallback()

func setup_cyberpunk_style_fallback():
	# Резервная стилизация на случай отсутствия CyberpunkUI
	var controls = get_tree().get_nodes_in_group("settings_controls")
	
	for control in controls:
		if control is Button:
			apply_button_style_fallback(control)
		elif control is CheckBox:
			apply_checkbox_style_fallback(control)
		elif control is OptionButton:
			apply_option_button_style_fallback(control)
		elif control is HSlider:
			apply_slider_style_fallback(control)

func apply_button_style_fallback(button: Button):
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
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.8))

func apply_checkbox_style_fallback(checkbox: CheckBox):
	# Стилизация для CheckBox
	checkbox.add_theme_color_override("font_color", Color(1, 1, 1))
	checkbox.add_theme_constant_override("outline_size", 1)
	checkbox.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.6))

func apply_option_button_style_fallback(option_button: OptionButton):
	# Стилизация для OptionButton
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
	
	option_button.add_theme_stylebox_override("normal", normal_style)
	option_button.add_theme_color_override("font_color", Color(1, 1, 1))
	option_button.add_theme_constant_override("outline_size", 1)
	option_button.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.6))

func apply_slider_style_fallback(slider: HSlider):
	# Стилизация для HSlider
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.2, 0.8, 1.0)
	grabber_style.corner_radius_top_left = 3
	grabber_style.corner_radius_top_right = 3
	grabber_style.corner_radius_bottom_right = 3
	grabber_style.corner_radius_bottom_left = 3
	
	var grabber_highlight_style = StyleBoxFlat.new()
	grabber_highlight_style.bg_color = Color(0.8, 0.2, 1.0)
	grabber_highlight_style.corner_radius_top_left = 3
	grabber_highlight_style.corner_radius_top_right = 3
	grabber_highlight_style.corner_radius_bottom_right = 3
	grabber_highlight_style.corner_radius_bottom_left = 3
	
	slider.add_theme_stylebox_override("grabber", grabber_style)
	slider.add_theme_stylebox_override("grabber_highlight", grabber_highlight_style)
	slider.add_theme_stylebox_override("grabber_disabled", grabber_style)
	
	# Стиль для трека слайдера
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	track_style.corner_radius_top_left = 2
	track_style.corner_radius_top_right = 2
	track_style.corner_radius_bottom_right = 2
	track_style.corner_radius_bottom_left = 2
	
	slider.add_theme_stylebox_override("slider", track_style)

func _on_cyberpunk_button_hovered(button: Control):
	print("Settings button hovered: ", button.name)

func _on_cyberpunk_button_pressed(button: Control):
	print("Settings button pressed: ", button.name)

func _on_cyberpunk_button_released(button: Control):
	print("Settings button released: ", button.name)

func setup_responsive_ui():
	if not device_manager:
		return
	
	# Добавляем в группу для получения уведомлений об изменении размера
	add_to_group("responsive")
	
	# Настраиваем UI в зависимости от типа устройства
	update_layout()

func update_layout():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Универсальное масштабирование для всех платформ
	var scale_factor = min(1.0, min(screen_size.x / 1280.0, screen_size.y / 720.0))
	var base_width = 400 * scale_factor
	var base_height = 500 * scale_factor
	
	$VBoxContainer.custom_minimum_size = Vector2(base_width, base_height)
	$VBoxContainer.position = Vector2(
		(screen_size.x - base_width) / 2,
		(screen_size.y - base_height) / 2
	)
	
	# Масштабируем все элементы управления
	for control in get_tree().get_nodes_in_group("settings_controls"):
		if control is Button:
			control.custom_minimum_size = Vector2(base_width * 0.8, 40 * scale_factor)
			control.add_theme_font_size_override("font_size", int(16 * scale_factor))
		elif control is OptionButton:
			control.custom_minimum_size = Vector2(base_width * 0.8, 35 * scale_factor)
			control.add_theme_font_size_override("font_size", int(14 * scale_factor))
		elif control is HSlider:
			control.custom_minimum_size = Vector2(base_width * 0.6, 20 * scale_factor)
		elif control is CheckBox:
			control.custom_minimum_size = Vector2(base_width * 0.8, 30 * scale_factor)
			control.add_theme_font_size_override("font_size", int(14 * scale_factor))
	
	# Масштабируем текстовые метки
	$VBoxContainer/MusicLabel.add_theme_font_size_override("font_size", int(16 * scale_factor))
	$VBoxContainer/MusicToggleLabel.add_theme_font_size_override("font_size", int(16 * scale_factor))
	$VBoxContainer/LanguageLabel.add_theme_font_size_override("font_size", int(16 * scale_factor))

func _on_screen_resized():
	update_layout()

func load_settings():
	# Используем WebBus для загрузки настроек если доступен
	if web_bus and web_bus.has_method("load_data"):
		var settings_data = web_bus.load_data("player_settings")
		if settings_data:
			music_volume = settings_data.get("music_volume", 0.5)
			music_enabled = settings_data.get("music_enabled", true)
			current_language = settings_data.get("language", "en")
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			music_volume = config.get_value("audio", "music_volume", 0.5)
			music_enabled = config.get_value("audio", "music_enabled", true)
			current_language = config.get_value("ui", "language", "en")
	
	# Заполняем опции языка
	language_option.clear()
	for i in range(languages.size()):
		language_option.add_item(languages[i], i)
	
	# Устанавливаем текущий язык
	var language_index = language_codes.find(current_language)
	if language_index >= 0:
		language_option.selected = language_index
	
	# Применяем настройки музыки
	if music_manager:
		music_toggle.button_pressed = music_enabled
		music_slider.value = music_volume

func _on_music_toggle_toggled(button_pressed: bool) -> void:
	# Сохраняем новое состояние
	music_enabled = button_pressed
	
	# Устанавливаем новое состояние музыки
	if music_manager:
		music_manager.set_music_enabled(music_enabled)
		
		# Сохраняем настройку в GameData, если он существует
		if has_node("/root/GameData"):
			var game_data = get_node("/root/GameData")
			if game_data.has_method("set_music_enabled"):
				game_data.set_music_enabled(music_enabled)
	
	# Сохраняем настройки
	save_settings()

func _on_music_slider_changed(value: float) -> void:
	# Сохраняем новое значение
	music_volume = value
	
	# Устанавливаем новую громкость
	if music_manager:
		music_manager.set_volume(music_volume)
	
	# Сохраняем настройки
	save_settings()

func _on_language_option_selected(index: int) -> void:
	if index < language_codes.size():
		current_language = language_codes[index]
		print("Selected language: ", current_language)
		
		# Сохраняем настройки
		save_settings()
		
		# Обновляем тексты интерфейса
		update_ui_texts()
		
		# Уведомляем другие сцены об изменении языка
		notify_language_change()

func _on_back_button_pressed() -> void:
	# Возвращаемся в главное меню
	if OS.has_feature('web'):
		# Для веба используем специальный переход
		get_tree().change_scene_to_packed(preload("res://scenes/main_menu.tscn"))
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_settings():
	var settings_data = {
		"music_volume": music_volume,
		"music_enabled": music_enabled,
		"language": current_language
	}
	
	# Используем WebBus для сохранения если доступен
	if web_bus and web_bus.has_method("save_data"):
		web_bus.save_data("player_settings", settings_data)
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", music_volume)
		config.set_value("audio", "music_enabled", music_enabled)
		config.set_value("ui", "language", current_language)
		config.save("user://player_settings.cfg")

func update_ui_texts():
	# Локализация для настроек
	var translations = {
		"en": {
			"music_volume": "Music Volume",
			"music_enabled": "Music Enabled",
			"language": "Language",
			"back": "Back"
		},
		"ru": {
			"music_volume": "Громкость музыки",
			"music_enabled": "Музыка включена",
			"language": "Язык",
			"back": "Назад"
		},
		"es": {
			"music_volume": "Volumen de música",
			"music_enabled": "Música activada",
			"language": "Idioma",
			"back": "Atrás"
		},
		"fr": {
			"music_volume": "Volume de la musique",
			"music_enabled": "Musique activée",
			"language": "Langue",
			"back": "Retour"
		},
		"de": {
			"music_volume": "Musiklautstärke",
			"music_enabled": "Musik aktiviert",
			"language": "Sprache",
			"back": "Zurück"
		}
	}
	
	# Обновляем тексты
	if translations.has(current_language):
		var lang_dict = translations[current_language]
		$VBoxContainer/MusicLabel.text = lang_dict.get("music_volume", "Music Volume")
		$VBoxContainer/MusicToggleLabel.text = lang_dict.get("music_enabled", "Music Enabled")
		$VBoxContainer/LanguageLabel.text = lang_dict.get("language", "Language")
		back_button.text = lang_dict.get("back", "Back")
	else:
		# Fallback to English
		$VBoxContainer/MusicLabel.text = "Music Volume"
		$VBoxContainer/MusicToggleLabel.text = "Music Enabled"
		$VBoxContainer/LanguageLabel.text = "Language"
		back_button.text = "Back"

func notify_language_change():
	# Уведомляем главное меню об изменении языка
	var main_menu = get_tree().get_first_node_in_group("main_menu")
	if main_menu and main_menu.has_method("on_language_changed"):
		main_menu.on_language_changed(current_language)
	
	# Уведомляем игру об изменении языка
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene and game_scene.has_method("on_language_changed"):
		game_scene.on_language_changed(current_language)
