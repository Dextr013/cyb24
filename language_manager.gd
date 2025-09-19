# language_manager.gd
extends Node

# Убираем объявление класса, так как это автозагружаемый скрипт
# class_name LanguageManager

signal language_changed(new_language)

var current_language = "en"
var supported_languages = ["en", "ru"]

func _ready():
	detect_and_set_language()
	print("LanguageManager загружен. Текущий язык: ", current_language)

func detect_and_set_language():
	var detected_language = detect_language()
	set_language(detected_language)

func detect_language():
	var language = "en"  # Язык по умолчанию
	
	if OS.has_feature('web'):
		# Для веб-версии используем JavaScript
		var js_code = """
			try {
				var lang = navigator.language || navigator.userLanguage;
				return lang.split('-')[0];
			} catch (e) {
				return 'en';
			}
		"""
		
		var result = JavaScriptBridge.eval(js_code, true)
		if result and result in supported_languages:
			language = result
		else:
			language = "en"
	else:
		# Для десктоп/мобильных версий
		var system_language = OS.get_locale()
		if system_language:
			var lang_code = system_language.split('_')[0]
			if lang_code in supported_languages:
				language = lang_code
	
	return language

func set_language(language_code):
	if language_code in supported_languages:
		current_language = language_code
		language_changed.emit(current_language)
	else:
		current_language = "en"  # Fallback to English
		print("Язык '", language_code, "' не поддерживается. Используется английский.")

func get_current_language():
	return current_language

func is_language_supported(language_code):
	return language_code in supported_languages

func add_supported_language(language_code):
	if not language_code in supported_languages:
		supported_languages.append(language_code)

func remove_supported_language(language_code):
	if language_code in supported_languages:
		supported_languages.erase(language_code)
