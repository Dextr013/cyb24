# MusicManager.gd
extends Node

# Приватные переменные
var _music_enabled: bool = true
var _current_track_index: int = 0
var _audio_player: AudioStreamPlayer
var _music_tracks: Array = []
var _volume: float = 0.5
var _is_playing: bool = false
var _current_track_name: String = ""

# Сигналы для уведомления о изменениях
signal music_toggled(enabled)
signal volume_changed(volume)
signal track_changed(track_name)

# Ссылка на интеграцию с Яндекс для сохранения настроек
var yandex_integration

func _ready():
	print("MusicManager initializing...")
	
	# Получаем интеграцию с Яндекс
	yandex_integration = get_node_or_null("/root/WebBus")
	
	# Создаем и настраиваем аудиоплеер
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.finished.connect(_on_audio_finished)
	
	# Загружаем треки
	_load_music_tracks()
	
	# Загружаем настройки
	load_settings()
	
	# Начинаем воспроизведение, если музыка включена
	if _music_enabled:
		play_music("main")
	
	print("MusicManager initialized with ", _music_tracks.size(), " tracks")
	
	# Для веб-версии добавляем обработку видимости окна
	if OS.has_feature('web'):
		get_tree().get_root().get_window().visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if OS.has_feature('web'):
		if get_tree().get_root().get_window().visible:
			# Окно стало видимым - возобновляем музыку
			resume_music()
		else:
			# Окно стало невидимым - приостанавливаем музыку
			if is_playing():
				pause_music()

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if _is_playing:
				pause_music()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if _music_enabled and not _is_playing:
				resume_music()

# Загрузка музыкальных треков
func _load_music_tracks():
	# Очищаем текущие треки
	_music_tracks.clear()
	
	# Список возможных путей к трекам
	var possible_tracks = [
		"res://assets/audio/track1.ogg",
		"res://assets/audio/track2.ogg", 
		"res://assets/audio/track3.ogg",
		"res://assets/audio/music/main_theme.ogg",
		"res://assets/audio/music/game_theme.ogg",
		"res://assets/audio/music/menu_theme.ogg"
	]
	
	# Пытаемся загрузить каждый трек
	for track_path in possible_tracks:
		if ResourceLoader.exists(track_path):
			var track = load(track_path)
			if track:
				_music_tracks.append(track)
				print("Loaded music track: ", track_path)
	
	# Если треков не найдено, создаем заглушку
	if _music_tracks.is_empty():
		print("Warning: No music tracks found. Creating a silent placeholder.")
		# Создаем пустой аудио поток в качестве заглушки
		var empty_stream = AudioStreamWAV.new()
		empty_stream.mix_rate = 44100
		empty_stream.stereo = true
		_music_tracks.append(empty_stream)

# Загрузка настроек
func load_settings():
	# Пытаемся загрузить настройки через WebBus
	if yandex_integration and yandex_integration.has_method("load_data"):
		var settings_data = yandex_integration.load_data("player_settings")
		if settings_data:
			_volume = settings_data.get("music_volume", 0.5)
			_music_enabled = settings_data.get("music_enabled", true)
			
			# Применяем настройки
			_audio_player.volume_db = _linear_to_db(_volume)
			print("Music settings loaded: volume=", _volume, ", enabled=", _music_enabled)
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		var err = config.load("user://player_settings.cfg")
		if err == OK:
			_volume = config.get_value("audio", "music_volume", 0.5)
			_music_enabled = config.get_value("audio", "music_enabled", true)
			
			# Применяем настройки
			_audio_player.volume_db = _linear_to_db(_volume)
			print("Music settings loaded: volume=", _volume, ", enabled=", _music_enabled)
		else:
			print("No music settings found, using defaults")

# Сохранение настроек
func save_settings():
	var data = {
		"music_volume": _volume,
		"music_enabled": _music_enabled
	}
	
	# Пытаемся сохранить настройки через WebBus
	if yandex_integration and yandex_integration.has_method("save_data"):
		yandex_integration.save_data("player_settings", data)
	else:
		# Локальное сохранение
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", _volume)
		config.set_value("audio", "music_enabled", _music_enabled)
		
		var err = config.save("user://player_settings.cfg")
		if err == OK:
			print("Music settings saved")
		else:
			print("Error saving music settings: ", err)

# Преобразование линейной громкости в dB с ограничением
func _linear_to_db(linear_volume: float) -> float:
	# Ограничиваем диапазон
	var clamped_volume = clamp(linear_volume, 0.0, 1.0)
	
	# Преобразуем в dB с нелинейной кривой для лучшего восприятия
	if clamped_volume <= 0:
		return -80.0  # Полная тишина
	
	# Нелинейное преобразование для более естественного звучания
	var db_volume = linear_to_db(clamped_volume)
	
	# Ограничиваем максимальную громкость до -5 dB вместо 0 dB
	db_volume = min(db_volume, -5.0)
	
	return db_volume

# Публичные методы доступа
func is_music_enabled() -> bool:
	return _music_enabled

func set_music_enabled(enabled: bool) -> void:
	if _music_enabled != enabled:
		_music_enabled = enabled
		
		if _music_enabled:
			play_music()
		else:
			stop_music()
		
		music_toggled.emit(_music_enabled)
		save_settings()
		print("Music ", "enabled" if _music_enabled else "disabled")

func get_volume() -> float:
	return _volume

func set_volume(volume: float) -> void:
	var new_volume = clamp(volume, 0.0, 1.0)
	if _volume != new_volume:
		_volume = new_volume
		_audio_player.volume_db = _linear_to_db(_volume)
		volume_changed.emit(_volume)
		save_settings()
		print("Volume changed to: ", _volume)

func play_music(track_name: String = "") -> void:
	if not _music_enabled or _music_tracks.is_empty():
		return
	
	# Если указано имя трека, пытаемся найти его
	var track_index = _current_track_index
	if not track_name.is_empty():
		# В реальном проекте здесь была бы логика поиска трека по имени
		# Для простоты просто используем случайный трек
		track_index = randi() % _music_tracks.size()
	
	# Если уже воспроизводится этот же трек, ничего не делаем
	if _audio_player.playing and track_index == _current_track_index:
		return
	
	_current_track_index = track_index
	_audio_player.stream = _music_tracks[_current_track_index]
	
	# Устанавливаем громкость с ограничением
	_audio_player.volume_db = _linear_to_db(_volume)
	
	_audio_player.play()
	_is_playing = true
	
	# Формируем имя текущего трека
	_current_track_name = "Track_%d" % (_current_track_index + 1)
	if not track_name.is_empty():
		_current_track_name = track_name
	
	track_changed.emit(_current_track_name)
	print("Now playing: ", _current_track_name)

func stop_music() -> void:
	if _audio_player.playing:
		_audio_player.stop()
		_is_playing = false
		print("Music stopped")

func pause_music() -> void:
	if _audio_player.playing:
		_audio_player.stream_paused = true
		_is_playing = false
		print("Music paused")

func resume_music() -> void:
	if _music_enabled and not _audio_player.playing and _audio_player.stream_paused:
		_audio_player.stream_paused = false
		_is_playing = true
		print("Music resumed")
	elif _music_enabled and not _audio_player.playing and not _audio_player.stream_paused:
		play_music()

func next_track() -> void:
	if _music_tracks.is_empty():
		return
	
	_current_track_index = (_current_track_index + 1) % _music_tracks.size()
	play_music()

func previous_track() -> void:
	if _music_tracks.is_empty():
		return
	
	_current_track_index = (_current_track_index - 1) % _music_tracks.size()
	if _current_track_index < 0:
		_current_track_index = _music_tracks.size() - 1
	
	play_music()

func is_playing() -> bool:
	return _is_playing

func is_paused() -> bool:
	return _audio_player.stream_paused

func get_current_track_name() -> String:
	return _current_track_name

func get_total_tracks() -> int:
	return _music_tracks.size()

func get_track_progress() -> float:
	if _audio_player.playing and _audio_player.stream:
		var length = _audio_player.stream.get_length()
		if length > 0:
			return _audio_player.get_playback_position() / length
	return 0.0

func get_track_duration() -> float:
	if _audio_player.stream:
		return _audio_player.stream.get_length()
	return 0.0

func _on_audio_finished() -> void:
	print("Track finished: ", _current_track_name)
	next_track()

# Методы для удобства работы из других скриптов
func toggle_music() -> void:
	set_music_enabled(not _music_enabled)

func increase_volume(amount: float = 0.1) -> void:
	set_volume(min(_volume + amount, 1.0))

func decrease_volume(amount: float = 0.1) -> void:
	set_volume(max(_volume - amount, 0.0))

# Метод для проверки доступности треков
func has_music_tracks() -> bool:
	return _music_tracks.size() > 0

# Метод для добавления треков динамически
func add_music_track(track_path: String) -> bool:
	if ResourceLoader.exists(track_path):
		var track = load(track_path)
		if track:
			_music_tracks.append(track)
			print("Added music track: ", track_path)
			return true
		else:
			print("Failed to load track: ", track_path)
	else:
		print("Track file not found: ", track_path)
	
	return false

# Метод для очистки списка треков
func clear_music_tracks() -> void:
	_music_tracks.clear()
	_current_track_index = 0
	stop_music()
	print("All music tracks cleared")

# Метод для установки конкретного трека по индексу
func set_track_by_index(index: int) -> bool:
	if index >= 0 and index < _music_tracks.size():
		_current_track_index = index
		play_music()
		return true
	return false

# Метод для поиска трека по имени (базовый)
func set_track_by_name(track_name: String) -> bool:
	# В реальном проекте здесь была бы более сложная логика поиска
	# Для простоты просто переключаем на случайный трек
	print("Setting track by name: ", track_name)
	play_music(track_name)
	return true

# Метод для переключения между треками меню и игры
func set_context_music(context: String) -> void:
	match context:
		"menu":
			set_track_by_name("menu_theme")
		"game":
			set_track_by_name("game_theme")
		"main":
			set_track_by_name("main_theme")
		_:
			print("Unknown music context: ", context)

# Метод для плавного изменения громкости
func fade_volume(target_volume: float, duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_method(_set_volume_smooth, _volume, target_volume, duration)

func _set_volume_smooth(volume: float) -> void:
	# Временная установка громкости без сохранения в настройках
	_audio_player.volume_db = _linear_to_db(volume)

# Метод для восстановления громкости после плавного изменения
func restore_volume() -> void:
	_audio_player.volume_db = _linear_to_db(_volume)

# Обработка данных игрока из Яндекс SDK
func on_player_data_loaded(data):
	if data and data.has("music_volume"):
		_volume = data["music_volume"]
		_audio_player.volume_db = _linear_to_db(_volume)
	
	if data and data.has("music_enabled"):
		_music_enabled = data["music_enabled"]
		if _music_enabled:
			play_music()
		else:
			stop_music()

# Отладочная информация
func get_debug_info() -> Dictionary:
	return {
		"enabled": _music_enabled,
		"volume": _volume,
		"volume_db": _audio_player.volume_db,
		"playing": _is_playing,
		"paused": _audio_player.stream_paused,
		"current_track": _current_track_name,
		"current_index": _current_track_index,
		"total_tracks": _music_tracks.size(),
		"progress": get_track_progress(),
		"duration": get_track_duration()
	}
