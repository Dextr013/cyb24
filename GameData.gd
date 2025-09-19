# GameData.gd
extends Node

signal coins_changed(amount)

var player_coins = 0
var best_score = 0
var music_enabled = true
var sound_enabled = true
var background_rotation_enabled = true
var current_skin = "default"
var unlocked_skins = ["default"]
var ads_watched = 0
var continue_game = false
var show_splash = true  # Добавлено: флаг показа заставки

# Добавляем ссылку на WebBus
var web_bus

func _ready():
	web_bus = get_node_or_null("/root/WebBus")
	load_player_data()
	print("GameData loaded. Continue game: ", continue_game)
	print("Show splash: ", show_splash)

func set_continue_game(value: bool):
	continue_game = value
	print("Set continue_game to: ", value)
	save_player_data()

func should_continue_game() -> bool:
	print("Should continue game: ", continue_game)
	return continue_game

func reset_continue_game():
	print("Resetting continue_game")
	continue_game = false
	save_player_data()

# Добавлено: методы для управления заставкой
func set_show_splash(value: bool):
	show_splash = value
	print("Set show_splash to: ", value)
	save_player_data()

func should_show_splash() -> bool:
	return show_splash

func add_coins(amount):
	player_coins += amount
	coins_changed.emit(player_coins)
	save_player_data()

func spend_coins(amount):
	if player_coins >= amount:
		player_coins -= amount
		coins_changed.emit(player_coins)
		save_player_data()
		return true
	return false

func unlock_skin(skin_name):
	if not unlocked_skins.has(skin_name):
		unlocked_skins.append(skin_name)
		save_player_data()

func set_skin(skin_name):
	if unlocked_skins.has(skin_name):
		current_skin = skin_name
		save_player_data()

func set_music_enabled(enabled):
	music_enabled = enabled
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager and music_manager.has_method("set_music_enabled"):
		music_manager.set_music_enabled(music_enabled)
	save_player_data()

func set_sound_enabled(enabled):
	sound_enabled = enabled
	save_player_data()

func set_background_rotation_enabled(enabled):
	background_rotation_enabled = enabled
	save_player_data()

func set_best_score(score):
	if score > best_score:
		best_score = score
		save_player_data()

func ad_watched():
	ads_watched += 1
	save_player_data()

func save_player_data():
	var save_data = {
		"player_coins": player_coins,
		"best_score": best_score,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"background_rotation_enabled": background_rotation_enabled,
		"current_skin": current_skin,
		"unlocked_skins": unlocked_skins,
		"ads_watched": ads_watched,
		"continue_game": continue_game,
		"show_splash": show_splash  # Добавлено: сохранение флага заставки
	}
	
	# Используем WebBus для сохранения если доступен
	if web_bus and web_bus.has_method("save_data"):
		web_bus.save_data("player_data", save_data)
		print("GameData saved via WebBus")
	else:
		# Локальное сохранение
		var file = FileAccess.open("user://player_data.save", FileAccess.WRITE)
		if file:
			file.store_var(save_data)
			print("GameData saved locally")
		else:
			print("Error saving GameData")

func load_player_data():
	# Используем WebBus для загрузки если доступен
	if web_bus and web_bus.has_method("load_data"):
		var save_data = web_bus.load_data("player_data")
		if save_data and typeof(save_data) == TYPE_DICTIONARY:
			player_coins = save_data.get("player_coins", 0)
			best_score = save_data.get("best_score", 0)
			music_enabled = save_data.get("music_enabled", true)
			sound_enabled = save_data.get("sound_enabled", true)
			background_rotation_enabled = save_data.get("background_rotation_enabled", true)
			current_skin = save_data.get("current_skin", "default")
			unlocked_skins = save_data.get("unlocked_skins", ["default"])
			ads_watched = save_data.get("ads_watched", 0)
			continue_game = save_data.get("continue_game", false)
			show_splash = save_data.get("show_splash", true)  # Добавлено: загрузка флага заставки
			print("GameData loaded via WebBus")
		else:
			# Fallback to local storage
			_load_local_data()
	else:
		# Локальная загрузка
		_load_local_data()

func _load_local_data():
	var file = FileAccess.open("user://player_data.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		if save_data and typeof(save_data) == TYPE_DICTIONARY:
			player_coins = save_data.get("player_coins", 0)
			best_score = save_data.get("best_score", 0)
			music_enabled = save_data.get("music_enabled", true)
			sound_enabled = save_data.get("sound_enabled", true)
			background_rotation_enabled = save_data.get("background_rotation_enabled", true)
			current_skin = save_data.get("current_skin", "default")
			unlocked_skins = save_data.get("unlocked_skins", ["default"])
			ads_watched = save_data.get("ads_watched", 0)
			continue_game = save_data.get("continue_game", false)
			show_splash = save_data.get("show_splash", true)  # Добавлено: загрузка флага заставки
			print("GameData loaded locally")
		else:
			print("Invalid save data format, using defaults")
	else:
		print("No GameData found, using defaults")
