# MainSceneStyles.gd
extends Node

# Стили для кнопок в игровой сцене
var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var pressed_style: StyleBoxFlat
var disabled_style: StyleBoxFlat

func _ready():
	initialize_styles()

func initialize_styles():
	# Основной стиль кнопки (normal)
	normal_style = StyleBoxFlat.new()
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
	normal_style.shadow_color = Color(0.0, 0.5, 0.8, 0.3)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(2, 2)
	
	# Стиль для состояния наведения (hover)
	hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	hover_style.border_color = Color(0.8, 0.2, 1.0)
	hover_style.shadow_size = 6
	hover_style.shadow_color = Color(0.8, 0.2, 1.0, 0.4)
	
	# Стиль для нажатого состояния (pressed)
	pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	pressed_style.border_color = Color(1.0, 0.5, 0.8)
	pressed_style.shadow_offset = Vector2(1, 1)
	pressed_style.shadow_size = 2
	
	# Стиль для отключенного состояния (disabled)
	disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.05, 0.05, 0.1, 0.5)
	disabled_style.border_color = Color(0.2, 0.8, 1.0, 0.5)

func setup_cyberpunk_buttons(buttons: Array):
	print("Setting up cyberpunk buttons for main scene...")
	
	for button in buttons:
		if button is Button:
			print("Applying cyberpunk style to: ", button.name)
			setup_single_cyberpunk_button(button)
		else:
			print("Skipping non-Button node: ", button.name)
	
	print("Main scene cyberpunk buttons setup complete")

func setup_single_cyberpunk_button(button: Button):
	# Применяем стили
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	button.queue_redraw()
	# Настройки текста
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(0.8, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.8, 0.2, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.8))
	button.add_theme_font_size_override("font_size", 18)
	
	
	# Адаптация для мобильных устройств
	if OS.has_feature("mobile") or OS.has_feature("web"):
		button.custom_minimum_size = Vector2(120, 50)
		button.add_theme_font_size_override("font_size", 22)
		var style = button.get_theme_stylebox("normal").duplicate()
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		button.add_theme_stylebox_override("normal", style)
	
	# Добавляем анимацию
	add_glow_animation(button)

func add_glow_animation(button: Button):
	var border_tween = create_tween()
	border_tween.set_loops()
	border_tween.tween_method(animate_border_color.bind(button), 0.0, 1.0, 2.0)
	
	var text_tween = create_tween()
	text_tween.set_loops()
	text_tween.tween_method(animate_text_color.bind(button), 0.0, 1.0, 1.5)
	
	var scan_tween = create_tween()
	scan_tween.set_loops()
	scan_tween.tween_method(animate_scan_effect.bind(button), 0.0, 1.0, 3.0)

func animate_border_color(progress: float, button: Button):
	var pulse = abs(sin(progress * PI * 2))
	var color = Color(
		0.2 + 0.6 * pulse,
		0.2 + 0.6 * (1.0 - pulse),
		0.8 + 0.2 * pulse
	)
	
	var style = button.get_theme_stylebox("normal").duplicate()
	style.border_color = color
	
	button.add_theme_stylebox_override("normal", style)

func animate_text_color(progress: float, button: Button):
	var pulse = abs(sin(progress * PI * 2))
	var color = Color(1.0, 1.0, 1.0 + 0.5 * pulse)
	
	button.add_theme_color_override("font_color", color)

func animate_scan_effect(progress: float, button: Button):
	var scan_pos = progress * 2 - 1
	var style = button.get_theme_stylebox("normal").duplicate()
	style.shadow_offset = Vector2(2, 2 + scan_pos * 10)
	style.shadow_size = 4 + abs(scan_pos) * 2
	
	button.add_theme_stylebox_override("normal", style)
