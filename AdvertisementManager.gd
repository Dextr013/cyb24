# AdvertisementManager.gd
extends Node

signal ad_completed(ad_type, reward)

# Добавляем перечисления для удобства
enum AdType {
	UNDO,           # Реклама за отмену хода
	CONTINUE,       # Реклама за продолжение игры
	LEADERBOARD,    # Реклама за просмотр лидерборда
	REWARD_COINS,   # Реклама за получение монет
	DAILY_REWARD    # Ежедневная награда за рекламу
}

# Симуляция доступности рекламы (в реальном проекте здесь будет проверка SDK)
var ad_availability = {
	AdType.UNDO: true,
	AdType.CONTINUE: true,
	AdType.LEADERBOARD: true,
	AdType.REWARD_COINS: true,
	AdType.DAILY_REWARD: true
}

func _ready():
	print("AdvertisementManager initialized")

# Функция для проверки доступности рекламы
func is_ad_available(ad_type: int) -> bool:
	if ad_availability.has(ad_type):
		return ad_availability[ad_type]
	return false

# Функция для показа рекламы
func show_advertisement(ad_type: int) -> void:
	print("Showing advertisement for type: ", ad_type)
	
	# В реальном проекте здесь будет вызов SDK рекламы
	# Для демонстрации симулируем завершение просмотра через 2 секунды
	await get_tree().create_timer(2.0).timeout
	
	# Определяем награду в зависимости от типа рекламы
	var reward = 0
	match ad_type:
		AdType.UNDO:
			reward = 0  # Награда за отмену - возможность отменить ход
		AdType.CONTINUE:
			reward = 0  # Награда за продолжение - возможность продолжить игру
		AdType.REWARD_COINS:
			reward = 50  # Награда за просмотр рекламы - 50 монет
		AdType.DAILY_REWARD:
			reward = 100  # Ежедневная награда - 100 монет
	
	# Отправляем сигнал о завершении просмотра рекламы
	ad_completed.emit(ad_type, reward)
	print("Ad completed. Reward: ", reward)

# Функция для установки доступности рекламы (для тестирования)
func set_ad_availability(ad_type: int, available: bool) -> void:
	if ad_availability.has(ad_type):
		ad_availability[ad_type] = available
		print("Ad type ", ad_type, " availability set to: ", available)

# Функция для получения информации о доступности всех типов рекламы
func get_ad_availability_info() -> Dictionary:
	return ad_availability.duplicate()
