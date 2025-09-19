# tile.gd
extends Area2D

# Tile properties
var value: int = 0
var grid_position: Vector2i = Vector2i.ZERO
var merged: bool = false
var moving: bool = false

# Constants
const TILE_SIZE = 100
const TILE_SPACING = 10
const ANIMATION_DURATION = 0.15

# References
@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D
# Убрали ссылку на Label

# Tween for animations
var tween: Tween

func _ready():
	add_to_group("tiles")
	# Убедитесь, что CollisionShape2D имеет правильный размер
	if collision_shape:
		collision_shape.shape = RectangleShape2D.new()
		collision_shape.shape.extents = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	# Устанавливаем начальный масштаб
	scale = Vector2.ONE

func initialize(initial_value: int, initial_position: Vector2i):
	value = initial_value
	grid_position = initial_position
	update_appearance()
	update_position()

func update_appearance():
	# Загружаем текстуру для этого значения плитки
	var texture_path = "res://assets/tiles/tile_%d.png" % value
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		sprite.texture = texture
		
		# Масштабируем текстуру до нужного размера
		var texture_size = texture.get_size()
		var scale_x = TILE_SIZE / texture_size.x
		var scale_y = TILE_SIZE / texture_size.y
		sprite.scale = Vector2(scale_x, scale_y)
	else:
		push_error("Texture not found: " + texture_path)
	
	# Убрали весь код, связанный с текстовой меткой
	
	# Гарантируем, что масштаб плитки всегда равен 1
	scale = Vector2.ONE

func update_position():
	# Правильное позиционирование плитки в сетке
	position = Vector2(
		grid_position.x * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0,
		grid_position.y * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0
	)

# Остальные функции остаются без изменений
func move_to(new_position: Vector2i):
	moving = true
	add_to_group("moving_tiles")
	
	# Сохраняем старую позицию для анимации
	var _old_position = position
	
	grid_position = new_position
	
	if tween:
		tween.kill()
		tween = null
	self.scale = Vector2.ONE  # Сброс масштаба перед новой анимацией
	
	tween = create_tween()
	tween.tween_property(self, "position", 
		Vector2(
			new_position.x * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0,
			new_position.y * (TILE_SIZE + TILE_SPACING) + TILE_SPACING + TILE_SIZE / 2.0
		), 
		ANIMATION_DURATION
	).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_move_complete)

func merge_to(target_tile):
	moving = true
	add_to_group("moving_tiles")
	merged = true
	
	if tween:
		tween.kill()
		tween = null
	self.scale = Vector2.ONE  # Сброс масштаба перед новой анимацией
	
	tween = create_tween()
	tween.tween_property(self, "position", target_tile.position, ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_merge_complete.bind(target_tile))

func _on_move_complete():
	moving = false
	remove_from_group("moving_tiles")
	if get_parent() != null and get_parent().has_method("_on_tile_movement_finished"):
		get_parent()._on_tile_movement_finished()

func _on_merge_complete(target_tile):
	# Увеличиваем значение целевой плитки
	target_tile.value *= 2
	target_tile.update_appearance()
	target_tile.merge_animation()
	
	# Удаляем эту плитку
	queue_free()
	
	if get_parent() != null and get_parent().has_method("_on_tile_movement_finished"):
		get_parent()._on_tile_movement_finished()

func spawn_animation():
	scale = Vector2(0.1, 0.1)
	if tween:
		tween.kill()
		tween = null
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), ANIMATION_DURATION / 2).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_spawn_animation_complete)

func _on_spawn_animation_complete():
	# Гарантируем, что масштаб точно равен 1 после анимации
	scale = Vector2.ONE

func merge_animation():
	if tween:
		tween.kill()
		tween = null
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), ANIMATION_DURATION / 2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), ANIMATION_DURATION / 2).set_ease(Tween.EASE_IN)
