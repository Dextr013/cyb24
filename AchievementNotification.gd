# AchievementNotification.gd
extends Control

@onready var achievement_name_label = $Panel/VBoxContainer/AchievementName
@onready var animation_player = $AnimationPlayer
var notification_scene = preload("res://scenes/AchievementNotification.tscn")
func _ready():
	# Проверяем, что все узлы существуют
	if not achievement_name_label:
		push_error("AchievementName label not found!")
		return
		
	if not animation_player:
		push_error("AnimationPlayer not found!")
		return
	
	# Центрируем уведомление на экране
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(viewport_size.x - size.x) / 2,
		50  # Отступ сверху
	)
	
	# Начинаем анимацию появления
	animation_player.play("show_notification")
	
	# Устанавливаем таймер для автоматического закрытия
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func set_achievement(achievement_name):
	if achievement_name_label:
		achievement_name_label.text = "Достижение: " + achievement_name

func _on_timer_timeout():
	# Запускаем анимацию исчезновения
	if animation_player:
		animation_player.play("hide_notification")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "hide_notification":
		queue_free()
