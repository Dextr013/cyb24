# AchievementStyles.gd
extends Node

static func get_achievement_style(unlocked: bool) -> Dictionary:
	if unlocked:
		return {
			"title_color": Color.WHITE,
			"description_color": Color(0.8, 0.8, 0.8),
			"reward_color": Color(1, 0.9, 0),
			"icon": "✓",
			"icon_color": Color.GREEN
		}
	else:
		return {
			"title_color": Color(0.6, 0.6, 0.6),
			"description_color": Color(0.5, 0.5, 0.5),
			"reward_color": Color(0.6, 0.55, 0.3),
			"icon": "🔒",
			"icon_color": Color.GRAY
		}
