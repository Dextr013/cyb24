# GameModes.gd
extends Node

signal game_mode_changed(mode)

enum GameMode {
	CLASSIC,    # Классический режим
	TIMED,      # Режим на время
	LIMITED,    # Режим с ограниченным количеством ходов
	CHALLENGE   # Режим испытаний
}

var current_mode = GameMode.CLASSIC
var time_left = 180  # 3 минуты для режима на время
var moves_left = 50   # 50 ходов для ограниченного режима
var game_timer = null
var game_start_time = 0

func set_game_mode(mode):
	current_mode = mode
	game_mode_changed.emit(mode)
	
	# Сбрасываем параметры режима
	if mode == GameMode.TIMED:
		time_left = 180
	elif mode == GameMode.LIMITED:
		moves_left = 50

func start_game():
	game_start_time = Time.get_unix_time_from_system()
	
	if current_mode == GameMode.TIMED:
		start_timer()

func start_timer():
	if game_timer:
		game_timer.stop()
		game_timer.queue_free()
	
	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_timer_tick)
	add_child(game_timer)
	game_timer.start()

func _on_timer_tick():
	if current_mode == GameMode.TIMED:
		time_left -= 1
		if time_left <= 0:
			game_timer.stop()
			# Завершаем игру
			if get_tree().current_scene.has_method("end_game"):
				get_tree().current_scene.end_game("Time's up!")

func on_move():
	if current_mode == GameMode.LIMITED:
		moves_left -= 1
		if moves_left <= 0:
			# Завершаем игру
			if get_tree().current_scene.has_method("end_game"):
				get_tree().current_scene.end_game("No moves left!")

func get_game_time():
	return Time.get_unix_time_from_system() - game_start_time

func get_mode_description(mode):
	match mode:
		GameMode.CLASSIC:
			return "Классический режим: играйте без ограничений"
		GameMode.TIMED:
			return "Режим на время: наберите максимум очков за 3 минуты"
		GameMode.LIMITED:
			return "Режим с ограниченными ходами: у вас есть 50 ходов"
		GameMode.CHALLENGE:
			return "Режим испытаний: специальные задания и вызовы"
		_:
			return ""

func get_mode_name(mode):
	match mode:
		GameMode.CLASSIC:
			return "Классический"
		GameMode.TIMED:
			return "На время"
		GameMode.LIMITED:
			return "Ограниченные ходы"
		GameMode.CHALLENGE:
			return "Испытания"
		_:
			return ""
