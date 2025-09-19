# splash_screen.gd
extends Control

@onready var splash_texture = $SplashTexture
@onready var animation_player = $AnimationPlayer

# Загрузочные экраны для разных языков
var splash_screens = {
	"ru": "res://assets/splash/splash_ru.png",
	"en": "res://assets/splash/splash_en.png"
}

func _ready():
	print("Splash screen initializing...")
	
	# Проверяем, нужно ли показывать заставку
	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("should_show_splash") and not game_data.should_show_splash():
		print("Splash screen skipped by GameData")
		# Пропускаем заставку и сразу переходим к меню
		call_deferred("transition_to_main_menu")
		return
	
	# Устанавливаем соответствующую текстуру
	var system_lang = OS.get_locale_language().to_lower()
	var texture_path = splash_screens.en  # По умолчанию английская
	
	if system_lang == "ru" or system_lang.begins_with("ru"):
		texture_path = splash_screens.ru
		print("Russian splash screen selected")
	else:
		print("English splash screen selected (default)")
	
	# Загружаем текстуру
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if texture:
			splash_texture.texture = texture
			print("Splash texture loaded: ", texture_path)
		else:
			print("Error loading splash texture: ", texture_path)
			# Создаем цветной фон как запасной вариант
			create_fallback_background()
	else:
		print("Splash texture not found: ", texture_path)
		# Создаем цветной фон как запасной вариант
		create_fallback_background()
	
	# Настраиваем режим отображения текстуры
	splash_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	splash_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	splash_texture.size = Vector2(1155, 651)  # Устанавливаем размер из сцены
	
	# Создаем анимацию программно, если она не существует
	if not animation_player.has_animation("fade_in_out"):
		create_fade_animation()
	
	# Запускаем анимацию
	animation_player.play("fade_in_out")
	print("Splash animation started")
	
	# Ждем завершения анимации и переходим к главному меню
	await animation_player.animation_finished
	print("Splash animation finished")
	transition_to_main_menu()

func create_fallback_background():
	# Создаем цветной фон как запасной вариант
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.1, 0.1, 0.2)  # Темно-синий фон
	color_rect.size = splash_texture.size
	add_child(color_rect)
	
	# Добавляем текст с логотипом
	var label = Label.new()
	label.text = "2048 GAME"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.position = Vector2(splash_texture.size.x / 2 - 100, splash_texture.size.y / 2 - 24)
	add_child(label)
	
	print("Fallback background created")

func create_fade_animation():
	print("Creating fade animation...")
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	
	# Устанавливаем путь к свойству modulate текстуры
	animation.track_set_path(track_index, "SplashTexture:modulate")
	
	# Добавляем ключевые кадры для анимации прозрачности
	animation.track_insert_key(track_index, 0.0, Color(1, 1, 1, 0))  # Начало: полностью прозрачный
	animation.track_insert_key(track_index, 1.0, Color(1, 1, 1, 1))  # Появление: полностью непрозрачный
	animation.track_insert_key(track_index, 2.0, Color(1, 1, 1, 1))  # Пауза: оставаться видимым
	animation.track_insert_key(track_index, 3.0, Color(1, 1, 1, 0))  # Исчезновение: снова прозрачный
	
	# Устанавливаем длительность анимации
	animation.length = 3.0
	
	# Добавляем анимацию в AnimationPlayer
	animation_player.add_animation("fade_in_out", animation)
	print("Fade animation created")

func transition_to_main_menu():
	print("Transitioning to main menu...")
	
	# Плавный переход к главному меню
	var transition_time = 0.5
	
	# Создаем эффект затемнения
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), transition_time)
	await tween.finished
	
	# Загружаем главное меню
	var main_menu_path = "res://scenes/main_menu.tscn"
	if ResourceLoader.exists(main_menu_path):
		var result = get_tree().change_scene_to_file(main_menu_path)
		if result != OK:
			print("Error changing scene to main menu: ", result)
	else:
		print("Main menu scene not found: ", main_menu_path)

# Обработка изменения размера окна
func _on_viewport_size_changed():
	if splash_texture:
		# Обновляем размер текстуры при изменении размера окна
		var viewport_size = get_viewport().get_visible_rect().size
		splash_texture.size = Vector2(
			min(viewport_size.x, viewport_size.y) * 0.9,
			min(viewport_size.x, viewport_size.y) * 0.9
		)
		splash_texture.position = (viewport_size - splash_texture.size) / 2

# Обработка прерывания заставки (например, клик мыши или касание)
func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			print("Splash screen interrupted by user input")
			# Останавливаем анимацию и сразу переходим к меню
			animation_player.stop()
			transition_to_main_menu()
