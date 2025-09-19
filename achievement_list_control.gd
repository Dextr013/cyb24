# achievement_list_control.gd (бывший list_option_control.gd)
extends Control

# Заменим этот скрипт на более простой вариант без OptionButton
@export var option_titles: Array[String] = []:
	set(value):
		option_titles = value
		_set_option_list()

@export var default_selected: int = 0

var _option_button: OptionButton

func _ready():
	_set_option_list()

func _set_option_list():
	# Ищем OptionButton среди дочерних нод
	_option_button = find_child("OptionButton")
	
	if _option_button == null:
		# Если OptionButton не найден, создаем его
		_option_button = OptionButton.new()
		_option_button.name = "OptionButton"
		add_child(_option_button)
	
	# Очищаем и заполняем OptionButton
	_option_button.clear()
	for title in option_titles:
		_option_button.add_item(title)
	
	# Устанавливаем выбранный элемент
	if default_selected < _option_button.item_count:
		_option_button.select(default_selected)

func get_selected_index() -> int:
	if _option_button:
		return _option_button.selected
	return -1

func get_selected_text() -> String:
	if _option_button and _option_button.selected >= 0:
		return _option_button.get_item_text(_option_button.selected)
	return ""
