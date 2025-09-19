# YandexIntegration.gd
extends Node

# Ссылка на Yandex SDK
var yandex_sdk = null
var sdk_initialized = false  # Переименовали переменную, чтобы избежать конфликта имен

# Добавляем переменные для проверки платформы
var _is_yandex_platform: bool = false
var _is_web_platform: bool = false

func _ready():
	# Проверяем доступность Yandex SDK
	_is_web_platform = OS.has_feature('web')
	
	if _is_web_platform and JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
		yandex_sdk = JavaScriptBridge.get_interface("YandexGames")
		_is_yandex_platform = true
		print("Yandex Games SDK found, initializing...")
		initialize_yandex_sdk()
	else:
		print("Yandex Games SDK not available")

func initialize_yandex_sdk() -> void:
	if yandex_sdk:
		JavaScriptBridge.eval("""
			YandexGames.ready().then(() => {
				console.log("Yandex Games SDK initialized");
				if (window.godotYandexSDKCallback) {
					window.godotYandexSDKCallback('initialized');
				}
			}).catch((error) => {
				console.error("Yandex Games SDK initialization failed:", error);
				if (window.godotYandexSDKCallback) {
					window.godotYandexSDKCallback('failed');
				}
			});
		""", true)
		
		# Устанавливаем callback для получения данных
		JavaScriptBridge.eval("""
			window.godotYandexSDKCallback = function(status) {
				// Вызываем Godot функцию через call_deferred чтобы избежать проблем с потоками
				call_deferred('on_yandex_sdk_initialized', status);
			};
		""", true)

func on_yandex_sdk_initialized(status):
	if status == 'initialized':
		sdk_initialized = true
		print("Yandex SDK successfully initialized")
	else:
		sdk_initialized = false
		print("Yandex SDK initialization failed")

# Переименовали функцию, чтобы избежать конфликта имен
func is_sdk_initialized() -> bool:
	return sdk_initialized

# Функции для проверки платформы (переименованы, чтобы избежать конфликта)
func is_yandex_platform() -> bool:
	return _is_yandex_platform

func is_web_platform() -> bool:
	return _is_web_platform

func load_player_data() -> void:
	if is_sdk_initialized():
		JavaScriptBridge.eval("""
			YandexGames.getPlayer().then(function(player) {
				console.log("Player data loaded:", player);
				// Вызываем Godot функцию для обработки данных
				if (window.godotPlayerDataCallback) {
					window.godotPlayerDataCallback(player);
				}
			}).catch(function(error) {
				console.error("Failed to load player data:", error);
			});
		""", true)
		
		# Устанавливаем callback для получения данных
		JavaScriptBridge.eval("""
			window.godotPlayerDataCallback = function(data) {
				// Вызываем Godot функцию через call_deferred чтобы избежать проблем с потоками
				call_deferred('on_player_data_loaded', data);
			};
		""", true)
	else:
		print("Yandex SDK not initialized")

func show_advertisement() -> void:
	if is_sdk_initialized():
		JavaScriptBridge.eval("""
			YandexGames.adv.showFullscreenAdv().then(function() {
				console.log("Advertisement shown successfully");
				// Call Godot callback on success
				if (window.godotAdCallback) {
					window.godotAdCallback('ad_success');
				}
			}).catch(function(error) {
				console.error("Failed to show advertisement:", error);
				// Call Godot callback on error
				if (window.godotAdCallback) {
					window.godotAdCallback('ad_error');
				}
			});
		""", true)
		
		# Устанавливаем глобальный callback в JavaScript для вызова из Godot
		JavaScriptBridge.eval("""
			window.godotAdCallback = function(status) {
				// Вызываем Godot функцию через call_deferred чтобы избежать проблем с потоками
				call_deferred('on_ad_callback', status);
			};
		""", true)
	else:
		print("Yandex SDK not initialized for advertisements")

func save_player_data(data: Dictionary) -> void:
	if is_sdk_initialized():
		var json_data = JSON.stringify(data)
		JavaScriptBridge.eval("YandexGames.setPlayerData(%s)".format([json_data]), true)
		print("Player data saved to Yandex SDK")
	else:
		print("Yandex SDK not initialized")

# Функция для обработки callback от загрузки данных игрока
func on_player_data_loaded(data):
	print("Player data received: ", data)
	# Распространяем данные по всем заинтересованным узлам
	for node in get_tree().get_nodes_in_group("yandex_data_listener"):
		if node.has_method("on_player_data_loaded"):
			node.on_player_data_loaded(data)
	
# Функция для обработки callback от реклама
func on_ad_callback(status):
	print("Ad callback received: ", status)
	# Передаем статус в основную игру, если она существует
	if get_tree().current_scene.has_method("on_ad_callback"):
		get_tree().current_scene.on_ad_callback(status)
	
	# Также уведомляем все узлы, которые могут быть заинтересованы
	for node in get_tree().get_nodes_in_group("ad_callback_listener"):
		if node.has_method("on_ad_callback"):
			node.on_ad_callback(status)

# Функция для показа rewarded рекламы
func show_rewarded_ad() -> void:
	if is_sdk_initialized():
		JavaScriptBridge.eval("""
			YandexGames.adv.showRewardedVideo({
				callbacks: {
					onOpen: function() {
						console.log("Rewarded ad opened");
					},
					onRewarded: function() {
						console.log("Rewarded ad completed");
						if (window.godotRewardedAdCallback) {
							window.godotRewardedAdCallback('rewarded');
						}
					},
					onClose: function() {
						console.log("Rewarded ad closed");
						if (window.godotRewardedAdCallback) {
							window.godotRewardedAdCallback('closed');
						}
					},
					onError: function(error) {
						console.error("Rewarded ad error:", error);
						if (window.godotRewardedAdCallback) {
							window.godotRewardedAdCallback('error');
						}
					}
				}
			});
		""", true)
		
		# Устанавливаем callback для rewarded рекламы
		JavaScriptBridge.eval("""
			window.godotRewardedAdCallback = function(status) {
				// Вызываем Godot функцию через call_deferred чтобы избежать проблем с потоками
				call_deferred('on_rewarded_ad_callback', status);
			};
		""", true)
	else:
		print("Yandex SDK not initialized for rewarded advertisements")

func on_rewarded_ad_callback(status):
	print("Rewarded ad callback received: ", status)
	# Передаем статус в основную игру
	if get_tree().current_scene.has_method("on_rewarded_ad_callback"):
		get_tree().current_scene.on_rewarded_ad_callback(status)
	
	# Уведомляем все заинтересованные узлы
	for node in get_tree().get_nodes_in_group("rewarded_ad_listener"):
		if node.has_method("on_rewarded_ad_callback"):
			node.on_rewarded_ad_callback(status)
