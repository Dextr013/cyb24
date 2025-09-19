# AutoButtonStyle.gd
extends Node

@export var default_button_size: Vector2 = Vector2(120, 40)
@export var text_horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
@export var text_vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER
@export var autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF
@export_enum("None:0", "Trim:1", "Trim Word:2", "Trim Ellipsis:3") var text_overrun_behavior: int = 3
@export var clip_text: bool = true

@export var button_textures: Dictionary = {
	"SettingsButton": "res://assets/buttons/settings.png",
	"RestartButton": "res://assets/buttons/restart.png",
	"UndoButton": "res://assets/buttons/undo.png",
	"MenuButton": "res://assets/buttons/menu.png",
	"NewGameButton": "res://assets/buttons/new_game.png"
}

@export var button_states: Dictionary = {
	"RestartButton": {
		"normal": "res://assets/buttons/restart_normal.png",
		"hover": "res://assets/buttons/restart_hover.png",
		"pressed": "res://assets/buttons/restart_pressed.png"
	},
	"UndoButton": {
		"normal": "res://assets/buttons/undo_normal.png",
		"hover": "res://assets/buttons/undo_hover.png",
		"pressed": "res://assets/buttons/undo_pressed.png"
	},
	"MenuButton": {
		"normal": "res://assets/buttons/menu_normal.png",
		"hover": "res://assets/buttons/menu_hover.png",
		"pressed": "res://assets/buttons/menu_pressed.png"
	},
	"SettingsButton": {
		"normal": "res://assets/buttons/settings_normal.png",
		"hover": "res://assets/buttons/settings_hover.png",
		"pressed": "res://assets/buttons/settings_pressed.png"
	},
	"NewGameButton": {
		"normal": "res://assets/buttons/new_game_normal.png",
		"hover": "res://assets/buttons/new_game_hover.png",
		"pressed": "res://assets/buttons/new_game_pressed.png"
	}
}

@export var icon_buttons: Dictionary = {
	"MenuButton": {
		"icon": "res://assets/icons/menu.png",
		"text": "Меню",
		"color": Color.WHITE,
		"font_size": 18
	}
}

@export var button_sizes: Dictionary = {
	"UndoButton": Vector2(100, 40),
	"SettingsButton": Vector2(120, 50)
}

func _ready():
	# Настраиваем все кнопки в сцене
	setup_all_buttons()

func setup_all_buttons():
	# Находим все кнопки в сцене
	var buttons = get_tree().get_nodes_in_group("buttons")
	
	# Преобразуем целое число в тип TextServer.OverrunBehavior
	var overrun_behavior := TextServer.OVERRUN_TRIM_ELLIPSIS
	match text_overrun_behavior:
		0: overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		1: overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
		2: overrun_behavior = TextServer.OVERRUN_TRIM_WORD
		3: overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	for button in buttons:
		var button_name = button.name
		
		# Настройка текстур для разных состояний
		if button_states.has(button_name):
			var states = button_states[button_name]
			ButtonStyle.setup_texture_button_states(
				button,
				states.get("normal", ""),
				states.get("hover", ""),
				states.get("pressed", "")
			)
		# Настройка простых текстур
		elif button_textures.has(button_name):
			ButtonStyle.setup_texture_button(button, button_textures[button_name])
		
		# Настройка кнопок с иконками
		if icon_buttons.has(button_name):
			var icon_data = icon_buttons[button_name]
			ButtonStyle.setup_icon_button(
				button,
				icon_data.get("icon", ""),
				icon_data.get("text", ""),
				icon_data.get("color", Color.WHITE),
				icon_data.get("font_size", 16)
			)
		
		# Установка размеров кнопок
		if button_sizes.has(button_name):
			ButtonStyle.set_button_min_size(button, button_sizes[button_name])
		else:
			# Используем размер по умолчанию, если индивидуальный не задан
			ButtonStyle.set_button_min_size(button, default_button_size)
		
		# Устанавливаем одинаковые настройки текста для всех кнопок
		ButtonStyle.setup_button_text_style(
			button,
			text_horizontal_alignment,
			text_vertical_alignment,
			autowrap_mode,
			overrun_behavior,
			clip_text
		)
		
		# Улучшаем видимость текста
		button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		button.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
		button.add_theme_color_override("font_pressed_color", Color(0.3, 0.3, 0.3))
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_constant_override("outline_size", 1)
		button.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
