# ResourcePreloader.gd
extends Node

# Критически важные ресурсы для предзагрузки
var critical_resources = [
	"res://scenes/AchievementNotification.tscn",
	"res://assets/audio/music/main_theme.ogg",
	"res://assets/audio/music/game_theme.ogg",
	"res://assets/audio/music/menu_theme.ogg",
	"res://assets/backgrounds/bg1.webp",
	"res://assets/backgrounds/bg2.webp",
	"res://assets/backgrounds/bg3.webp",
	"res://assets/backgrounds/bg4.webp",
	"res://assets/backgrounds/bg5.webp",
	"res://assets/backgrounds/bg6.webp",
	"res://assets/backgrounds/bg7.webp"
]

# Кэш загруженных ресурсов
var resource_cache = {}

func _ready():
	# Предзагружаем критические ресурсы
	preload_critical_resources()

func preload_critical_resources():
	print("[ResourcePreloader] Начинаем предзагрузку критических ресурсов")
	
	for path in critical_resources:
		if ResourceLoader.exists(path):
			# Загружаем ресурс в фоновом режиме
			ResourceLoader.load_threaded_request(path)
			print("[ResourcePreloader] Запрос на загрузку: ", path)
		else:
			print("[ResourcePreloader] Ресурс не найден: ", path)
	
	# Ждем завершения загрузки
	await get_tree().create_timer(1.0).timeout
	check_loading_progress()

func check_loading_progress():
	for path in critical_resources:
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				print("[ResourcePreloader] Загрузка в процессе: ", path)
			ResourceLoader.THREAD_LOAD_LOADED:
				var resource = ResourceLoader.load_threaded_get(path)
				resource_cache[path] = resource
				print("[ResourcePreloader] Ресурс загружен: ", path)
			ResourceLoader.THREAD_LOAD_FAILED:
				print("[ResourcePreloader] Ошибка загрузки: ", path)
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				print("[ResourcePreloader] Неверный ресурс: ", path)

func get_resource(path):
	# Возвращаем ресурс из кэша или загружаем его
	if resource_cache.has(path):
		return resource_cache[path]
	
	# Пытаемся загрузить синхронно
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path)
		resource_cache[path] = resource
		return resource
	
	return null

func clear_cache():
	resource_cache.clear()
	print("[ResourcePreloader] Кэш очищен")

# Функция для проверки загружены ли все критические ресурсы
func all_critical_resources_loaded() -> bool:
	for path in critical_resources:
		if not resource_cache.has(path):
			return false
	return true

# Функция для получения прогресса загрузки
func get_loading_progress() -> float:
	var loaded = 0
	for path in critical_resources:
		if resource_cache.has(path):
			loaded += 1
	return float(loaded) / critical_resources.size()
