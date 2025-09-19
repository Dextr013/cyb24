# ButtonStyle.gd
class_name ButtonStyle
extends Node

# Перечисление режимов растяжения текстуры
enum StretchMode {
	SCALE,              # Растянуть с искажением
	KEEP_CENTERED,      # Сохранить размер, центрировать
	KEEP_ASPECT,        # Сохранить пропорции, заполнить
	KEEP_ASPECT_CENTERED # Сохранить пропорции, центрировать
}

# Настройка внешнего вида кнопки с помощью текстуры
static func setup_texture_button(button: Button, texture_path: String, 
							   stretch_mode: StretchMode = StretchMode.KEEP_ASPECT_CENTERED,
							   margins: Vector4 = Vector4(10, 10, 10, 10)) -> void:
	
	var texture = load(texture_path)
	if not texture:
		push_error("Texture not found: " + texture_path)
		return
	
	var style = StyleBoxTexture.new()
	style.texture = texture
	
	# Настройка режима растяжения
	match stretch_mode:
		StretchMode.SCALE:
			style.set("expand_mode", 0)  # EXPAND_FIT (растянуть)
		StretchMode.KEEP_CENTERED:
			style.set("expand_mode", 1)  # EXPAND_STRETCH (растянуть с сохранением центра)
		StretchMode.KEEP_ASPECT:
			style.set("expand_mode", 2)  # EXPAND_TILE (замостить)
		StretchMode.KEEP_ASPECT_CENTERED:
			style.set("expand_mode", 3)  # EXPAND_TILE_FIT (замостить с подгонкой)
	
	# Настройка отступов
	style.content_margin_left = margins.x
	style.content_margin_right = margins.y
	style.content_margin_top = margins.z
	style.content_margin_bottom = margins.w
	
	# Применяем стиль ко всем состояниям кнопки
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	
	# Убираем текст по умолчанию
	button.text = ""

# Настройка кнопки с разными текстурами для разных состояний
static func setup_texture_button_states(button: Button, normal_texture: String, 
									  hover_texture: String = "", pressed_texture: String = "",
									  disabled_texture: String = "", stretch_mode: StretchMode = StretchMode.KEEP_ASPECT_CENTERED) -> void:
	
	# Настройка нормального состояния
	if normal_texture:
		var normal_style = create_stylebox(normal_texture, stretch_mode)
		if normal_style:
			button.add_theme_stylebox_override("normal", normal_style)
	
	# Настройка состояния при наведении
	if hover_texture:
		var hover_style = create_stylebox(hover_texture, stretch_mode)
		if hover_style:
			button.add_theme_stylebox_override("hover", hover_style)
	
	# Настройка состояния при нажатии
	if pressed_texture:
		var pressed_style = create_stylebox(pressed_texture, stretch_mode)
		if pressed_style:
			button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Настройка отключенного состояния
	if disabled_texture:
		var disabled_style = create_stylebox(disabled_texture, stretch_mode)
		if disabled_style:
			button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Убираем текст по умолчанию
	button.text = ""

# Создание StyleBox с указанными параметрами
static func create_stylebox(texture_path: String, stretch_mode: StretchMode) -> StyleBoxTexture:
	var texture = load(texture_path)
	if not texture:
		push_error("Texture not found: " + texture_path)
		return null
	
	var style = StyleBoxTexture.new()
	style.texture = texture
	
	# Настройка режима растяжения
	match stretch_mode:
		StretchMode.SCALE:
			style.set("expand_mode", 0)  # EXPAND_FIT (растянуть)
		StretchMode.KEEP_CENTERED:
			style.set("expand_mode", 1)  # EXPAND_STRETCH (растянуть с сохранением центра)
		StretchMode.KEEP_ASPECT:
			style.set("expand_mode", 2)  # EXPAND_TILE (замостить)
		StretchMode.KEEP_ASPECT_CENTERED:
			style.set("expand_mode", 3)  # EXPAND_TILE_FIT (замостить с подгонкой)
	
	return style

# Настройка кнопки с иконкой и текста
static func setup_icon_button(button: Button, texture_path: String, button_text: String = "",
							text_color: Color = Color.WHITE, font_size: int = 16) -> void:
	
	# Создаем контейнер для иконки и текста
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Добавляем иконку
	if texture_path:
		var texture = load(texture_path)
		if texture:
			var icon = TextureRect.new()
			icon.texture = texture
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(24, 24)
			hbox.add_child(icon)
	
	# Добавляем текст
	if button_text:
		var label = Label.new()
		label.text = button_text
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_font_size_override("font_size", font_size)
		# Настройки текста для одинакового отображения
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
		hbox.add_child(label)
	
	# Очищаем кнопку и добавляем контейнер
	for child in button.get_children():
		child.queue_free()
	
	button.add_child(hbox)

# Установка минимального размера для кнопки
static func set_button_min_size(button: Button, min_size: Vector2) -> void:
	button.custom_minimum_size = min_size

# Установка расширенного размера для кнопки
static func set_button_size(button: Button, size: Vector2) -> void:
	button.custom_minimum_size = size
	button.size = size

# Настройка стиля текста для кнопки
static func setup_button_text_style(button: Button, 
								  horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
								  vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER,
								  autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF,
								  overrun_behavior: TextServer.OverrunBehavior = TextServer.OVERRUN_TRIM_ELLIPSIS,
								  clip_text: bool = true) -> void:
	button.horizontal_alignment = horizontal_alignment
	button.vertical_alignment = vertical_alignment
	button.autowrap_mode = autowrap_mode
	button.text_overrun_behavior = overrun_behavior
	button.clip_text = clip_text

# Отладочная версия для проверки доступных констант
static func debug_stretch_modes():
	var _style = StyleBoxTexture.new()
	print("Available expand_mode values:")
	print("0 = EXPAND_FIT (растянуть)")
	print("1 = EXPAND_STRETCH (растянуть с сохранением центра)")
	print("2 = EXPAND_TILE (замостить)")
	print("3 = EXPAND_TILE_FIT (замостить с подгонкой)")
