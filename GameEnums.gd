# GameEnums.gd
extends Node

enum GameMode {
	CLASSIC,    # Классический режим
	TIMED,      # Режим на время
	LIMITED,    # Режим с ограниченным количеством ходов
	CHALLENGE   # Режим испытаний
}

enum AdType {
	UNDO,           # Реклама за отмену хода
	CONTINUE,       # Реклама за продолжение игры
	LEADERBOARD,    # Реклама за просмотр лидерборда
	REWARD_COINS,   # Реклама за получение монет
	DAILY_REWARD    # Ежедневная награда за рекламу
}
