# TouchControls.gd
extends Control

@onready var swipe_area = $SwipeArea
@onready var buttons_container = $ButtonsContainer

var device_manager
var swipe_start_position = Vector2.ZERO
var swipe_min_distance = 50

# Для обработки мультитач
var touch_points = {}

func _ready():
	device_manager = get_node_or_null("/root/DeviceManager")
	
	# Показываем/скрываем элементы управления в зависимости от устройства
	if device_manager and device_manager.is_touch_device:
		visible = true
		setup_touch_controls()
	else:
		visible = false

func setup_touch_controls():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Настраиваем область для жестов
	swipe_area.custom_minimum_size = screen_size
	swipe_area.position = Vector2.ZERO
	
	# Настраиваем кнопки для устройств без жестов
	if device_manager.is_mobile() and device_manager.is_portrait():
		# В портретной ориентации показываем кнопки
		buttons_container.visible = true
		
		# Создаем кнопки управления
		create_control_buttons()
	else:
		buttons_container.visible = false

func create_control_buttons():
	# Очищаем контейнер
	for child in buttons_container.get_children():
		child.queue_free()
	
	# Создаем кнопки направлений
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var button_textures = {
		Vector2i.UP: "res://assets/touch/up.png",
		Vector2i.DOWN: "res://assets/touch/down.png", 
		Vector2i.LEFT: "res://assets/touch/left.png",
		Vector2i.RIGHT: "res://assets/touch/right.png"
	}
	
	for direction in directions:
		var button = TextureButton.new()
		# Загружаем текстуру или создаем fallback
		if ResourceLoader.exists(button_textures[direction]):
			button.texture_normal = load(button_textures[direction])
		else:
			# Fallback - цветная кнопка с текстом
			button.text = str(direction)
			button.add_theme_color_override("font_color", Color(1, 1, 1))
		
		button.custom_minimum_size = Vector2(80, 80)
		button.pressed.connect(_on_direction_button_pressed.bind(direction))
		buttons_container.add_child(button)

func _on_direction_button_pressed(direction):
	# Передаем направление в основную игру
	if get_tree().current_scene.has_method("move"):
		get_tree().current_scene.move(direction)

func _on_swipe_area_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Запоминаем начальную позицию касания
			touch_points[event.index] = event.position
			swipe_start_position = event.position
		else:
			# Удаляем информацию о завершенном касании
			if touch_points.has(event.index):
				var swipe_end_position = event.position
				var swipe = swipe_end_position - touch_points[event.index]
				
				if swipe.length() > swipe_min_distance:
					var direction = Vector2i.ZERO
					
					if abs(swipe.x) > abs(swipe.y):
						# Горизонтальный swipe
						direction = Vector2i.RIGHT if swipe.x > 0 else Vector2i.LEFT
					else:
						# Вертикальный swipe
						direction = Vector2i.DOWN if swipe.y > 0 else Vector2i.UP
					
					# Передаем направление в основную игру
					if get_tree().current_scene.has_method("move"):
						get_tree().current_scene.move(direction)
				
				touch_points.erase(event.index)
	
	elif event is InputEventScreenDrag:
		# Обновляем позицию касания для обработки drag
		if touch_points.has(event.index):
			touch_points[event.index] = event.position
