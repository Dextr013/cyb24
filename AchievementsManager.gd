# AchievementsManager.gd
extends Node

@warning_ignore("unused_signal")
signal achievement_unlocked(achievement_id, achievement_name, reward_coins)

var achievements = {
	"first_game": {
		"name": "Первая игра", 
		"description": "Завершите свою первую игру",
		"unlocked": false,
		"reward_coins": 10
	},
	"novice": {
		"name": "Новичок", 
		"description": "Достигните 256 очков",
		"unlocked": false,
		"target_score": 256,
		"reward_coins": 20
	},
	"expert": {
		"name": "Эксперт", 
		"description": "Достигните 2048 очков",
		"unlocked": false,
		"target_score": 2048,
		"reward_coins": 50
	},
	"master": {
		"name": "Мастер", 
		"description": "Достигните 16384 очков",
		"unlocked": false,
		"target_score": 16384,
		"reward_coins": 100
	},
	"collector": {
		"name": "Собиратель", 
		"description": "Соберите плитку 2048",
		"unlocked": false,
		"reward_coins": 75
	},
	"combo_king": {
		"name": "Король комбо", 
		"description": "Сделайте 3 слияния подряд за один ход",
		"unlocked": false,
		"reward_coins": 30
	},
	"speedrunner": {
		"name": "Спидраннер", 
		"description": "Достигните 1024 очков менее чем за 2 минуты",
		"unlocked": false,
		"reward_coins": 40
	},
	"perfectionist": {
		"name": "Перфекционист", 
		"description": "Завершите игру без использования отмены хода",
		"unlocked": false,
		"reward_coins": 60
	},
	"lucky": {
		"name": "Везунчик", 
		"description": "Получите плитку 4 три раза подряд",
		"unlocked": false,
		"reward_coins": 25
	},
	"strategist": {
		"name": "Стратег", 
		"description": "Достигните 512 очков без перемещения плиток вверх",
		"unlocked": false,
		"reward_coins": 35
	},
	"persistent": {
		"name": "Настойчивый", 
		"description": "Сыграйте 10 игр подряд",
		"unlocked": false,
		"reward_coins": 80
	},
	"undo_master": {
		"name": "Мастер отмены", 
		"description": "Используйте отмену хода 5 раз в одной игре",
		"unlocked": false,
		"reward_coins": 45
	},
	"tile_hunter": {
		"name": "Охотник за плитками", 
		"description": "Создайте плитку 512 в трех разных играх",
		"unlocked": false,
		"reward_coins": 70
	},
	"time_traveler": {
		"name": "Путешественник во времени", 
		"description": "Играйте в течение 7 дней подряд",
		"unlocked": false,
		"reward_coins": 90
	}
}

var games_played = 0
var games_without_undo = 0
var consecutive_4_tiles = 0
var consecutive_moves_without_up = 0
var max_combo_in_move = 0
var games_with_512_tile = 0
var last_play_date = ""
var current_streak = 0
var max_streak = 0
var undo_count_in_current_game = 0
var max_consecutive_moves_without_up = 0
var has_created_512_in_current_game = false
var current_game_start_time = 0

func _ready():
	print("[AchievementsManager] Инициализация менеджера достижений")
	load_achievements()
	print("[AchievementsManager] Загружено достижений: ", achievements.size())

func save_achievements():
	var save_data = {
		"achievements": {},
		"stats": {
			"games_played": games_played,
			"games_without_undo": games_without_undo,
			"games_with_512_tile": games_with_512_tile,
			"last_play_date": last_play_date,
			"current_streak": current_streak,
			"max_streak": max_streak
		}
	}
	
	for achievement_id in achievements:
		save_data.achievements[achievement_id] = achievements[achievement_id].unlocked
	
	# Используем WebBusWrapper для сохранения
	if WebBusWrapper.save_data("achievements", save_data):
		print("[AchievementsManager] Достижения сохранены через WebBusWrapper")
	else:
		print("[AchievementsManager] Ошибка: не удалось сохранить достижения")

func load_achievements():
	var save_data = WebBusWrapper.load_data("achievements")
	
	if save_data and typeof(save_data) == TYPE_DICTIONARY:
		if save_data.has("achievements"):
			for achievement_id in save_data.achievements:
				if achievements.has(achievement_id):
					achievements[achievement_id].unlocked = save_data.achievements[achievement_id]
					if save_data.achievements[achievement_id]:
						print("[AchievementsManager] Загружено разблокированное достижение: ", achievement_id)
		
		if save_data.has("stats"):
			games_played = save_data.stats.get("games_played", 0)
			games_without_undo = save_data.stats.get("games_without_undo", 0)
			games_with_512_tile = save_data.stats.get("games_with_512_tile", 0)
			last_play_date = save_data.stats.get("last_play_date", "")
			current_streak = save_data.stats.get("current_streak", 0)
			max_streak = save_data.stats.get("max_streak", 0)
			
			print("[AchievementsManager] Загружена статистика: ", games_played, " игр")
	else:
		print("[AchievementsManager] Файл сохранений не найден, используются значения по умолчанию")


func get_unlocked_achievements():
	var unlocked = []
	for achievement_id in achievements:
		if achievements[achievement_id].unlocked:
			unlocked.append(achievements[achievement_id])
	return unlocked

func get_locked_achievements():
	var locked = []
	for achievement_id in achievements:
		if not achievements[achievement_id].unlocked:
			locked.append(achievements[achievement_id])
	return locked

func get_achievement_progress(achievement_id):
	if not achievements.has(achievement_id):
		return null
	
	var achievement = achievements[achievement_id]
	var progress = {
		"id": achievement_id,
		"name": achievement.name,
		"description": achievement.description,
		"unlocked": achievement.unlocked,
		"reward_coins": achievement.reward_coins
	}
	
	# Добавляем информацию о прогрессе для конкретных достижений
	match achievement_id:
		"novice", "expert", "master":
			progress["current"] = 0  # Будет устанавливаться извне
			progress["target"] = achievement.target_score
			progress["progress_text"] = "Набрано очков: %d/%d"
		
		"persistent":
			progress["current"] = games_played
			progress["target"] = 10
			progress["progress_text"] = "Сыграно игр: %d/%d"
		
		"tile_hunter":
			progress["current"] = games_with_512_tile
			progress["target"] = 3
			progress["progress_text"] = "Игр с плиткой 512: %d/%d"
		
		"time_traveler":
			progress["current"] = current_streak
			progress["target"] = 7
			progress["progress_text"] = "Дней подряд: %d/%d"
	
	return progress

func reset_achievements():
	print("[AchievementsManager] Сброс всех достижений")
	
	for achievement_id in achievements:
		achievements[achievement_id].unlocked = false
	
	games_played = 0
	games_without_undo = 0
	consecutive_4_tiles = 0
	consecutive_moves_without_up = 0
	max_combo_in_move = 0
	games_with_512_tile = 0
	last_play_date = ""
	current_streak = 0
	max_streak = 0
	undo_count_in_current_game = 0
	max_consecutive_moves_without_up = 0
	has_created_512_in_current_game = false
	
	save_achievements()
	
	print("[AchievementsManager] Все достижения сброшены")
