# CyberpunkUI.gd
extends Node

# Сигналы для обработки событий кнопок
signal button_hovered(button)
signal button_pressed(button)
signal button_released(button)

# Настройки стиля
var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var pressed_style: StyleBoxFlat
var disabled_style: StyleBoxFlat

# Цвета для текста
var font_color := Color(1, 1, 1)
var font_hover_color := Color(0.8, 1.0, 1.0)
var font_pressed_color := Color(0.8, 0.2, 1.0)
var font_disabled_color := Color(0.5, 0.5, 0.5)

# Ссылки на твины для очистки
var active_tweens: Array = []

func _ready():
	# Инициализируем стили при загрузке
	initialize_styles()

func _exit_tree():
	# Очищаем все твины при выходе
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()

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
	print("Setting up cyberpunk buttons...")
	
	for button in buttons:
		if button is Button:
			print("Applying cyberpunk style to: ", button.name)
			setup_single_cyberpunk_button(button)
		else:
			print("Skipping non-Button node: ", button.name)
	
	print("Cyberpunk buttons setup complete")

func setup_single_cyberpunk_button(button: Button):
	# Применяем стили
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	var _border_tween = create_tween()
	# Настройки текста
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_hover_color)
	button.add_theme_color_override("font_pressed_color", font_pressed_color)
	button.add_theme_color_override("font_disabled_color", font_disabled_color)
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
	
	# Подключаем сигналы для обработки событий
	if not button.mouse_entered.is_connected(_on_button_mouse_entered):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	if not button.mouse_exited.is_connected(_on_button_mouse_exited):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed.bind(button))
	if not button.button_up.is_connected(_on_button_released):
		button.button_up.connect(_on_button_released.bind(button))
	
	# Добавляем анимацию
	add_glow_animation(button)

func add_glow_animation(button: Button):
	var border_tween = create_tween()
	border_tween.set_loops()
	border_tween.tween_method(animate_border_color.bind(button), 0.0, 1.0, 2.0)
	active_tweens.append(border_tween)
	
	var text_tween = create_tween()
	text_tween.set_loops()
	text_tween.tween_method(animate_text_color.bind(button), 0.0, 1.0, 1.5)
	active_tweens.append(text_tween)
	
	var scan_tween = create_tween()
	scan_tween.set_loops()
	scan_tween.tween_method(animate_scan_effect.bind(button), 0.0, 1.0, 3.0)
	active_tweens.append(scan_tween)

func animate_border_color(progress: float, button: Button):
	if not is_instance_valid(button):
		return
		
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
	if not is_instance_valid(button):
		return
		
	var pulse = abs(sin(progress * PI * 2))
	var color = Color(1.0, 1.0, 1.0 + 0.5 * pulse)
	
	button.add_theme_color_override("font_color", color)

func animate_scan_effect(progress: float, button: Button):
	if not is_instance_valid(button):
		return
		
	var scan_pos = progress * 2 - 1
	var style = button.get_theme_stylebox("normal").duplicate()
	style.shadow_offset = Vector2(2, 2 + scan_pos * 10)
	style.shadow_size = 4 + abs(scan_pos) * 2
	
	button.add_theme_stylebox_override("normal", style)

func _on_button_mouse_entered(button: Button):
	if not is_instance_valid(button):
		return
		
	# Дополнительный эффект при наведении
	var hover_effect = hover_style.duplicate()
	hover_effect.shadow_size = 8
	button.add_theme_stylebox_override("hover", hover_effect)
	emit_signal("button_hovered", button)

func _on_button_mouse_exited(button: Button):
	if not is_instance_valid(button):
		return
		
	# Восстанавливаем обычный стиль при уходе курсора
	button.add_theme_stylebox_override("hover", hover_style)
	emit_signal("button_hovered", button)

func _on_button_pressed(button: Button):
	if not is_instance_valid(button):
		return
		
	# Эффект при нажатии
	var pressed_effect = pressed_style.duplicate()
	pressed_effect.border_width_left = 4
	pressed_effect.border_width_right = 4
	pressed_effect.border_width_top = 4
	pressed_effect.border_width_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed_effect)
	emit_signal("button_pressed", button)

func _on_button_released(button: Button):
	if not is_instance_valid(button):
		return
		
	# Восстанавливаем обычный стиль при отпускании
	button.add_theme_stylebox_override("pressed", pressed_style)
	emit_signal("button_released", button)
