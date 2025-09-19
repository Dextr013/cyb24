# ModeSelectDialog.gd
extends Window

@onready var classic_button = $VBoxContainer/ClassicButton
@onready var timed_button = $VBoxContainer/TimedButton
@onready var limited_button = $VBoxContainer/LimitedButton
@onready var challenge_button = $VBoxContainer/ChallengeButton
@onready var close_button = $VBoxContainer/CloseButton

var game_modes

func _ready():
	classic_button.pressed.connect(_on_classic_pressed)
	timed_button.pressed.connect(_on_timed_pressed)
	limited_button.pressed.connect(_on_limited_pressed)
	challenge_button.pressed.connect(_on_challenge_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылку на менеджер режимов
	game_modes = get_node_or_null("/root/GameModes")
	
	# Устанавливаем описания для кнопок
	if game_modes:
		classic_button.text = "Классический\n" + game_modes.get_mode_description(0)
		timed_button.text = "На время\n" + game_modes.get_mode_description(1)
		limited_button.text = "Ограниченные ходы\n" + game_modes.get_mode_description(2)
		challenge_button.text = "Испытания\n" + game_modes.get_mode_description(3)
		
		# Временно отключаем режим испытаний, если он не реализован
		challenge_button.disabled = true

func _on_classic_pressed():
	if game_modes:
		game_modes.set_game_mode(0)  # CLASSIC
	hide()

func _on_timed_pressed():
	if game_modes:
		game_modes.set_game_mode(1)  # TIMED
	hide()

func _on_limited_pressed():
	if game_modes:
		game_modes.set_game_mode(2)  # LIMITED
	hide()

func _on_challenge_pressed():
	if game_modes:
		game_modes.set_game_mode(3)  # CHALLENGE
	hide()

func _on_close_pressed():
	hide()
