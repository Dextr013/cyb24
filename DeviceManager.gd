# DeviceManager.gd
extends Node

enum DeviceType { DESKTOP, MOBILE, TABLET }
enum Orientation { PORTRAIT, LANDSCAPE }

signal device_changed(device_type)
signal orientation_changed(orientation)
signal language_changed(language_code)
signal input_method_changed(input_method)

var current_device = DeviceType.DESKTOP
var current_orientation = Orientation.LANDSCAPE
var _is_touch_device: bool = false  # Переименовали переменную
var current_language: String = "en"
var current_input_method: String = "keyboard_mouse"

# Поддерживаемые языки
var languages = ["English", "Russian", "Spanish", "French", "German"]
var language_codes = ["en", "ru", "es", "fr", "de"]

# Переводчик
var translation_manager

# WebBus ссылка
var web_bus

# Кэш для производительности
var _screen_info_cache := {}
var _last_orientation_check := 0.0
var _orientation_check_delay := 0.5

# Переводы для системных сообщений
var translations = {
	"en": {
		"device_desktop": "Desktop",
		"device_mobile": "Mobile",
		"device_tablet": "Tablet",
		"orientation_portrait": "Portrait",
		"orientation_landscape": "Landscape"
	},
	"ru": {
		"device_desktop": "Компьютер",
		"device_mobile": "Мобильный",
		"device_tablet": "Планшет",
		"orientation_portrait": "Портретная",
		"orientation_landscape": "Альбомная"
	},
	"es": {
		"device_desktop": "Escritorio",
		"device_mobile": "Мобильный",
		"device_tablet": "Tableta",
		"orientation_portrait": "Vertical",
		"orientation_landscape": "Horizontal"
	},
	"fr": {
		"device_desktop": "Bureau",
		"device_mobile": "Mobile",
		"device_tablet": "Tablette",
		"orientation_portrait": "Portrait",
		"orientation_landscape": "Paysage"
	},
	"de": {
		"device_desktop": "Desktop",
		"device_mobile": "Mobil",
		"device_tablet": "Tablet",
		"orientation_portrait": "Hochformat",
		"orientation_landscape": "Querformat"
	}
}

func _ready():
	print("[DeviceManager] Инициализация менеджера устройств")
	
	# Получаем WebBus если доступен
	if OS.has_feature('web') and Engine.has_singleton("WebBus"):
		web_bus = Engine.get_singleton("WebBus")
		print("[DeviceManager] WebBus доступен")
	
	# Получаем менеджер переводов
	translation_manager = get_node_or_null("/root/TranslationManager")
	
	# Определяем тип устройства
	determine_device_type()
	
	# Определяем ориентацию
	check_orientation(true)
	
	# Проверяем, touch-ли это устройство
	check_touch_device()
	
	# Определяем метод ввода
	update_input_method()
	
	# Подписываемся на изменение размера окна
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Подписываемся на события ввода
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	# Загружаем настройки языка
	load_language_settings()
	
	print("[DeviceManager] Текущее устройство: ", get_device_type_name())
	print("[DeviceManager] Ориентация: ", get_orientation_name())
	print("[DeviceManager] Язык: ", current_language)
	print("[DeviceManager] Метод ввода: ", current_input_method)
	
	# Применяем оптимальные настройки графики
	apply_optimal_settings()

func _input(event):
	# Обновляем метод ввода при изменении типа ввода
	if event is InputEventKey or event is InputEventMouse or event is InputEventScreenTouch:
		update_input_method()

func _on_joy_connection_changed(_device_id, _connected):
	# Обновляем метод ввода при подключении/отключении геймпада
	update_input_method()

func update_input_method():
	var new_input_method = get_input_method()
	if new_input_method != current_input_method:
		current_input_method = new_input_method
		input_method_changed.emit(current_input_method)
		print("[DeviceManager] Метод ввода изменен: ", current_input_method)

# Функция для проверки, является ли устройство touch-устройством
func check_touch_device():
	# Универсальная проверка на сенсорное устройство
	if OS.has_feature("mobile") or OS.has_feature("tablet"):
		_is_touch_device = true
	elif OS.has_feature("web"):
		# Для веба используем улучшенную проверку
		var user_agent = JavaScriptBridge.eval("navigator.userAgent", true) if OS.has_feature('web') else ""
		var max_touch_points = JavaScriptBridge.eval("navigator.maxTouchPoints", true) if OS.has_feature('web') else 0
		var has_touch_start = JavaScriptBridge.eval("'ontouchstart' in window", true) if OS.has_feature('web') else false
		
		# Проверяем различные признаки сенсорного устройства
		_is_touch_device = (
			(max_touch_points != null and max_touch_points > 0) or
			(has_touch_start != null and has_touch_start) or
			(user_agent != null and (
				user_agent.contains("Android") or
				user_agent.contains("iPhone") or
				user_agent.contains("iPad") or
				user_agent.contains("iPod") or
				user_agent.contains("Windows Phone")
			))
		)
	else:
		_is_touch_device = false
	
	print("[DeviceManager] Сенсорное устройство: ", _is_touch_device)

# Функция для проверки, является ли устройство touch-устройством
func is_touch_device() -> bool:
	return _is_touch_device

func determine_device_type():
	var screen_size = DisplayServer.screen_get_size()
	var aspect_ratio = screen_size.x / screen_size.y
	
	if OS.has_feature("mobile") or OS.has_feature("web"):
		# Для веба определяем устройство по userAgent
		if OS.has_feature("web"):
			var user_agent = JavaScriptBridge.eval("navigator.userAgent", true) if OS.has_feature('web') else ""
			if user_agent:
				if user_agent.contains("Android") or user_agent.contains("iPhone"):
					current_device = DeviceType.MOBILE
				elif user_agent.contains("iPad"):
					current_device = DeviceType.TABLET
				else:
					# Определяем по соотношению сторон
					if aspect_ratio < 1.0 or (aspect_ratio >= 1.0 and aspect_ratio < 1.4):
						current_device = DeviceType.MOBILE
					else:
						current_device = DeviceType.TABLET
			else:
				# Fallback по соотношению сторон
				if aspect_ratio < 1.0 or (aspect_ratio >= 1.0 and aspect_ratio < 1.4):
					current_device = DeviceType.MOBILE
				else:
					current_device = DeviceType.TABLET
		else:
			# Для мобильных устройств определяем по соотношению сторон
			if aspect_ratio < 1.0 or (aspect_ratio >= 1.0 and aspect_ratio < 1.4):
				current_device = DeviceType.MOBILE
			else:
				current_device = DeviceType.TABLET
	else:
		current_device = DeviceType.DESKTOP
	
	device_changed.emit(current_device)

func load_language_settings():
	# Используем WebBus для загрузки настроек если доступен
	if OS.has_feature('web') and web_bus and web_bus.has_method("loadData"):
		var settings_data_str = web_bus.loadData("player_settings")
		if settings_data_str and settings_data_str != "":
			var settings_data = JSON.parse_string(settings_data_str)
			if settings_data and typeof(settings_data) == TYPE_DICTIONARY:
				current_language = settings_data.get("language", OS.get_locale_language())
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			current_language = config.get_value("ui", "language", OS.get_locale_language())
		else:
			# Используем системный язык
			var system_lang = OS.get_locale_language()
			if language_codes.has(system_lang):
				current_language = system_lang
			else:
				current_language = "en"  # По умолчанию английский
	
	# Убедимся, что язык поддерживается
	if not language_codes.has(current_language):
		current_language = "en"
	
	# Применяем язык
	apply_language()

func save_language_settings():
	var data = {"language": current_language}
	
	# Используем WebBus для сохранения если доступен
	if OS.has_feature('web') and web_bus and web_bus.has_method("saveData"):
		web_bus.saveData("player_settings", JSON.stringify(data))
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		config.set_value("ui", "language", current_language)
		config.save("user://player_settings.cfg")

func set_language(language_code: String):
	if language_codes.has(language_code) and language_code != current_language:
		current_language = language_code
		save_language_settings()
		apply_language()
		language_changed.emit(current_language)
		print("[DeviceManager] Язык изменен: ", get_language_name())

func apply_language():
	# Применяем язык к TranslationServer
	if TranslationServer.has_method("set_locale"):
		TranslationServer.set_locale(current_language)
	else:
		print("[DeviceManager] TranslationServer не поддерживает set_locale")

func get_current_language():
	return current_language

func get_language_name(language_code = null):
	var lang_code = language_code if language_code else current_language
	var index = language_codes.find(lang_code)
	if index >= 0 and index < languages.size():
		return languages[index]
	return "Unknown"

func get_language_list():
	var result = []
	for i in range(languages.size()):
		result.append({
			"name": languages[i],
			"code": language_codes[i],
			"is_current": language_codes[i] == current_language
		})
	return result

func translate(key, language = null):
	var lang = language if language else current_language
	
	# Пытаемся использовать менеджер переводов, если доступен
	if translation_manager and translation_manager.has_method("translate"):
		return translation_manager.translate(key, lang)
	
	# Fallback на локальные переводы
	if translations.has(lang) and translations[lang].has(key):
		return translations[lang][key]
	elif translations.has("en") and translations["en"].has(key):
		return translations["en"][key]
	else:
		return key

# Функции для удобства работы из других скриптов
func get_recommended_font_size(base_size = 16):
	var scale_factor = get_scale_factor()
	return base_size * scale_factor

func get_recommended_button_size(base_size = Vector2(100, 40)):
	var scale_factor = get_scale_factor()
	return Vector2(base_size.x * scale_factor, base_size.y * scale_factor)

func get_recommended_margin(base_margin = 10):
	var scale_factor = get_scale_factor()
	return base_margin * scale_factor

func is_high_dpi():
	var scale = get_scale_factor()
	return scale > 1.5

func get_device_capabilities():
	return {
		"has_touch": _is_touch_device,
		"has_mouse": not _is_touch_device,
		"has_keyboard": is_desktop(),
		"has_gamepad": Input.get_connected_joypads().size() > 0,
		"is_high_dpi": is_high_dpi(),
		"supports_vibration": OS.has_feature("mobile") or OS.has_feature("web")
	}

# Функции для обработки ввода в зависимости от устройства
func get_input_method():
	if _is_touch_device:
		return "touch"
	elif Input.get_connected_joypads().size() > 0:
		return "gamepad"
	else:
		return "keyboard_mouse"

func should_show_touch_controls():
	return _is_touch_device and not Input.get_connected_joypads().size() > 0

func get_optimal_ui_scale():
	var screen_size = get_viewport().get_visible_rect().size
	var min_dimension = min(screen_size.x, screen_size.y)
	
	if is_mobile():
		if is_portrait():
			return min_dimension / 480.0  # Базовый размер для мобильных в портретной ориентации
		else:
			return min_dimension / 320.0  # Базовый размер для мобильных в альбомной ориентации
	elif is_tablet():
		return min_dimension / 600.0  # Базовый размер для планшетов
	else:
		return min_dimension / 800.0  # Базовый размер для десктопов

# Функция для применения оптимальных настроек графики в зависимости от устройства
func apply_optimal_settings():
	if is_mobile() or is_tablet():
		# Для мобильных устройств и планшетов применяем оптимизированные настройки
		ProjectSettings.set_setting("rendering/scaling_3d/scale", 0.75)
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa", 2)
		print("[DeviceManager] Применены мобильные настройки графики")
	else:
		# Для десктопов используем более высокие настройки
		ProjectSettings.set_setting("rendering/scaling_3d/scale", 1.0)
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa", 4)
		print("[DeviceManager] Применены десктопные настройки графики")

# Функция для перезагрузки игры с применением новых настроек
func restart_game():
	print("[DeviceManager] Перезагрузка игры...")
	get_tree().reload_current_scene()

# Отладочные функции
func print_debug_info():
	var screen_info = get_screen_info()
	var capabilities = get_device_capabilities()
	
	print("=== DeviceManager Debug Info ===")
	print("Устройство: ", screen_info.device_type)
	print("Ориентация: ", screen_info.orientation)
	print("Разрешение: ", screen_info.width, "x", screen_info.height)
	print("Соотношение сторон: ", screen_info.aspect_ratio)
	print("Язык: ", get_language_name())
	print("Масштаб: ", get_scale_factor())
	print("Сенсорный ввод: ", screen_info.is_touch)
	print("Метод ввода: ", get_input_method())
	print("Поддержка вибрации: ", capabilities.supports_vibration)
	print("Подключенные геймпады: ", Input.get_connected_joypads().size())
	print("================================")

# Функция для проверки поддержки определенных функций
func supports_feature(feature_name):
	match feature_name:
		"vibration":
			return OS.has_feature("mobile") or OS.has_feature("web")
		"gamepad":
			return Input.get_connected_joypads().size() > 0
		"touch":
			return _is_touch_device
		"keyboard":
			return is_desktop()
		"high_dpi":
			return is_high_dpi()
		_:
			return false

# Функция для получения рекомендуемых настроек UI
func get_ui_config():
	var config = {
		"font_sizes": {},
		"button_sizes": {},
		"spacings": {},
		"grid_size": 4
	}
	
	var ui_scale = get_optimal_ui_scale()
	
	# Базовые размеры
	var base_font_sizes = {"small": 14, "medium": 18, "large": 24}
	var base_button_sizes = {"small": Vector2(80, 40), "medium": Vector2(100, 50), "large": Vector2(120, 60)}
	var base_spacings = {"small": 5, "medium": 10, "large": 15}
	
	# Масштабируем значения
	for key in base_font_sizes:
		config.font_sizes[key] = base_font_sizes[key] * ui_scale
		
	for key in base_button_sizes:
		config.button_sizes[key] = base_button_sizes[key] * ui_scale
		
	for key in base_spacings:
		config.spacings[key] = base_spacings[key] * ui_scale
	
	# Корректируем размер сетки для мобильных устройств
	if is_mobile() and is_portrait():
		config.grid_size = 4  # Уменьшаем сетку для мобильных в портретной ориентации
	
	return config

# Функция для эмуляции вибрации (если поддерживается)
func vibrate(duration_ms = 100):
	if OS.has_feature("mobile") and supports_feature("vibration"):
		# Здесь будет код для вызова вибрации на мобильных устройствах
		print("[DeviceManager] Вибрация: ", duration_ms, "ms")
		# На практике здесь будет вызов нативного кода через GDExtension или плагины
		return true
	elif OS.has_feature("web"):
		# Для веба используем API вибрации браузера
		JavaScriptBridge.eval("""
			if (navigator.vibrate) {
				navigator.vibrate(%d);
			}
		""" % duration_ms, true)
		return true
	return false

# Функция для обработки изменения плотности пикселей
func handle_density_change():
	var new_density = get_scale_factor()
	print("[DeviceManager] Изменение плотности пикселей: ", new_density)
	
	# Уведомляем все UI элементы об изменении плотности
	for node in get_tree().get_nodes_in_group("responsive"):
		if node.has_method("on_density_changed"):
			node.on_density_changed(new_density)
	
	return new_density

# Функции для проверки типа устройства
func is_desktop():
	return current_device == DeviceType.DESKTOP

func is_mobile():
	return current_device == DeviceType.MOBILE

func is_tablet():
	return current_device == DeviceType.TABLET

func is_portrait():
	return current_orientation == Orientation.PORTRAIT

func is_landscape():
	return current_orientation == Orientation.LANDSCAPE

func get_device_type_name():
	match current_device:
		DeviceType.DESKTOP:
			return "Desktop"
		DeviceType.MOBILE:
			return "Mobile"
		DeviceType.TABLET:
			return "Tablet"
		_:
			return "Unknown"

func get_orientation_name():
	match current_orientation:
		Orientation.PORTRAIT:
			return "Portrait"
		Orientation.LANDSCAPE:
			return "Landscape"
		_:
			return "Unknown"

func get_screen_info():
	# Используем кэш для производительности
	var current_time = Time.get_ticks_msec()
	if _screen_info_cache.has("last_update") and current_time - _screen_info_cache.last_update < 1000:
		return _screen_info_cache
	
	var screen_size = DisplayServer.screen_get_size()
	var info = {
		"device_type": get_device_type_name(),
		"orientation": get_orientation_name(),
		"width": screen_size.x,
		"height": screen_size.y,
		"aspect_ratio": screen_size.x / screen_size.y,
		"is_touch": _is_touch_device,
		"last_update": current_time
	}
	
	_screen_info_cache = info
	return info

func get_scale_factor():
	var _screen_size = DisplayServer.screen_get_size()  # Добавлено подчеркивание для неиспользуемой переменной
	var base_dpi = 96.0  # Базовый DPI для расчетов
	var dpi = DisplayServer.screen_get_dpi()
	
	if dpi <= 0:
		dpi = base_dpi
	
	return dpi / base_dpi

func _on_viewport_size_changed():
	# Проверяем ориентацию при изменении размера окна (с задержкой)
	var current_time = Time.get_ticks_msec()
	if current_time - _last_orientation_check > _orientation_check_delay * 1000:
		check_orientation()
		_last_orientation_check = current_time

func check_orientation(force = false):
	var new_orientation = Orientation.LANDSCAPE
	var viewport_size = get_viewport().get_visible_rect().size
	
	if viewport_size.x < viewport_size.y:
		new_orientation = Orientation.PORTRAIT
	
	if new_orientation != current_orientation or force:
		current_orientation = new_orientation
		orientation_changed.emit(current_orientation)
		print("[DeviceManager] Ориентация изменена: ", get_orientation_name())
		return true
	
	return false

# Новая функция для принудительного обновления информации об устройстве
func refresh_device_info():
	determine_device_type()
	check_orientation(true)
	check_touch_device()
	update_input_method()
	print("[DeviceManager] Информация об устройстве обновлена")

# Новая функция для получения рекомендуемых настроек контроля в зависимости от устройства
func get_recommended_controls():
	var controls = {}
	
	if _is_touch_device:
		controls["input_mode"] = "touch"
		controls["button_size"] = get_recommended_button_size(Vector2(120, 60))
		controls["show_virtual_joystick"] = true
	elif Input.get_connected_joypads().size() > 0:
		controls["input_mode"] = "gamepad"
		controls["button_size"] = get_recommended_button_size(Vector2(100, 40))
		controls["show_virtual_joystick"] = false
	else:
		controls["input_mode"] = "keyboard_mouse"
		controls["button_size"] = get_recommended_button_size(Vector2(80, 30))
		controls["show_virtual_joystick"] = false
	
	return controls

# Новая функция для проверки поддержки определенного языка
func supports_language(language_code):
	return language_codes.has(language_code)

# Новая функция для получения списка поддерживаемых языков с флагами
func get_languages_with_flags():
	return {
		"en": {"name": "English", "flag": "res://assets/flags/us.png"},
		"ru": {"name": "Russian", "flag": "res://assets/flags/ru.png"},
		"es": {"name": "Spanish", "flag": "res://assets/flags/es.png"},
		"fr": {"name": "French", "flag": "res://assets/flags/fr.png"},
		"de": {"name": "German", "flag": "res://assets/flags/de.png"}
	}
