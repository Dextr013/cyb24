# WebBusWrapper.gd
extends Node

# Статические методы для работы с WebBus
class_name WebBusWrapper

static func save_data(key: String, data) -> bool:
	if OS.has_feature('web'):
		# Пытаемся использовать WebBus если доступен
		if Engine.has_singleton("WebBus"):
			var web_bus = Engine.get_singleton("WebBus")
			web_bus.saveData(key, JSON.stringify(data))
			return true
		# Fallback на прямой вызов Яндекс SDK
		elif JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
			JavaScriptBridge.eval("YandexGames.setPlayerData('%s', %s)".format([key, JSON.stringify(data)]), true)
			return true
	
	# Локальное сохранение для десктопной версии
	var file = FileAccess.open("user://%s.save" % key, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		return true
	
	return false

static func load_data(key: String):
	if OS.has_feature('web'):
		# Пытаемся использовать WebBus если доступен
		if Engine.has_singleton("WebBus"):
			var web_bus = Engine.get_singleton("WebBus")
			var result = web_bus.loadData(key)
			if result and result != "":
				return JSON.parse_string(result)
		# Fallback на прямой вызов Яндекс SDK
		elif JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
			var result = JavaScriptBridge.eval("YandexGames.getPlayerData('%s')".format([key]), true)
			if result and result != "":
				return JSON.parse_string(result)
	
	# Локальная загрузка для десктопной версии
	var file = FileAccess.open("user://%s.save" % key, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		if content != "":
			return JSON.parse_string(content)
	
	return null

static func has_saved_game() -> bool:
	if OS.has_feature('web'):
		# Проверяем через WebBus
		if Engine.has_singleton("WebBus"):
			var web_bus = Engine.get_singleton("WebBus")
			return web_bus.hasKey("game_save")
		# Fallback на проверку через Яндекс SDK
		elif JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
			var result = JavaScriptBridge.eval("YandexGames.hasPlayerData('game_save')", true)
			return bool(result) if result != null else false
	
	# Локальная проверка
	return FileAccess.file_exists("user://game_save.save")

static func is_available() -> bool:
	return OS.has_feature('web') and (
		Engine.has_singleton("WebBus") or 
		JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true)
	)

static func show_advertisement(ad_type: String) -> void:
	if OS.has_feature('web'):
		if Engine.has_singleton("WebBus"):
			var web_bus = Engine.get_singleton("WebBus")
			web_bus.showAd(ad_type)
		elif JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
			JavaScriptBridge.eval("""
				YandexGames.adv.showFullscreenAdv().then(() => {
					if (window.godotAdCallback) {
						window.godotAdCallback('ad_success', '%s');
					}
				}).catch((error) => {
					if (window.godotAdCallback) {
						window.godotAdCallback('ad_error', '%s');
					}
				});
			""".format([ad_type, ad_type]), true)

static func show_rewarded_ad(ad_type: String) -> void:
	if OS.has_feature('web'):
		if Engine.has_singleton("WebBus"):
			var web_bus = Engine.get_singleton("WebBus")
			web_bus.showRewardedAd(ad_type)
		elif JavaScriptBridge.eval("typeof window.YandexGames !== 'undefined'", true):
			JavaScriptBridge.eval("""
				YandexGames.adv.showRewardedVideo({
					callbacks: {
						onRewarded: function() {
							if (window.godotRewardedAdCallback) {
								window.godotRewardedAdCallback('rewarded', '%s');
							}
						},
						onClose: function() {
							if (window.godotRewardedAdCallback) {
								window.godotRewardedAdCallback('closed', '%s');
							}
						},
						onError: function(error) {
							if (window.godotRewardedAdCallback) {
								window.godotRewardedAdCallback('error', '%s');
							}
						}
					}
				});
			""".format([ad_type, ad_type, ad_type]), true)
