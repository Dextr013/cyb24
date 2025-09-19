# MenuManager.gd
extends Node

# Цвета темы по умолчанию
var theme_colors = {
	"primary": Color(0.2, 0.6, 0.8),
	"secondary": Color(0.3, 0.7, 0.9),
	"background": Color(0.96, 0.96, 0.96),
	"text": Color(1, 1, 1)
}

# Настройки анимаций
var animation_speed: float = 0.3
var animation_type: String = "fade"

func _ready():
	print("Custom MenuManager initialized")

# Установка цвета темы
func set_theme_color(color_name: String, color: Color) -> void:
	if theme_colors.has(color_name):
		theme_colors[color_name] = color
		print("Set theme color '", color_name, "' to ", color)

# Получение цвета темы
func get_theme_color(color_name: String) -> Color:
	if theme_colors.has(color_name):
		return theme_colors[color_name]
	return Color.WHITE

# Установка скорости анимации
func set_animation_speed(speed: float) -> void:
	animation_speed = speed
	print("Set animation speed to ", speed)

# Установка типа анимации
func set_animation_type(type: String) -> void:
	animation_type = type
	print("Set animation type to ", type)

# Смена сцены с анимацией
func change_scene(scene_path: String) -> void:
	print("Changing scene to: ", scene_path)
	
	# Создаем анимацию перехода
	var transition = _create_transition()
	get_tree().root.add_child(transition)
	
	# Ждем завершения анимации и меняем сцену
	await get_tree().create_timer(animation_speed).timeout
	get_tree().change_scene_to_file(scene_path)
	transition.queue_free()

# Возврат к предыдущей сцене
func go_back() -> void:
	print("Going back to previous scene")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Настройка главного меню
func setup_main_menu(menu_node: Control) -> void:
	print("Setting up main menu")
	_apply_menu_style(menu_node, "main")

# Настройка меню настроек
func setup_settings_menu(menu_node: Control) -> void:
	print("Setting up settings menu")
	_apply_menu_style(menu_node, "settings")

# Создание анимации перехода
func _create_transition() -> Control:
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 1)
	transition.size = get_tree().root.size
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 0), animation_speed)
	
	return transition

# Применение стилей к меню
func _apply_menu_style(menu_node: Control, menu_type: String) -> void:
	# Применяем стиль к фону
	if menu_node.has_node("Background"):
		var background = menu_node.get_node("Background")
		if background is ColorRect:
			background.color = theme_colors.background
	
	# Применяем стиль к кнопкам
	for child in menu_node.get_children():
		if child is Button:
			_style_button(child, menu_type)

# Стилизация кнопки
func _style_button(button: Button, menu_type: String) -> void:
	var button_style = StyleBoxFlat.new()
	
	# Выбираем цвет в зависимости от типа меню и кнопки
	if menu_type == "main" or button.name.to_lower().contains("start") or button.name.to_lower().contains("quit"):
		button_style.bg_color = theme_colors.primary
	else:
		button_style.bg_color = theme_colors.secondary
	
	# Закругляем углы
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	
	# Применяем стиль
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_color_override("font_color", theme_colors.text)
	
	# Добавляем эффект при наведении
	var hover_style = button_style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
