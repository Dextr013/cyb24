# MediaQueries.gd
extends Node

static func get_config_for_device(device_type, orientation) -> Dictionary:
	var config = {
		"font_sizes": {},
		"button_sizes": {},
		"spacings": {},
		"grid_size": 4
	}
	
	match device_type:
		DeviceManager.DeviceType.MOBILE:
			if orientation == DeviceManager.Orientation.PORTRAIT:
				config.font_sizes = {"small": 14, "medium": 18, "large": 24}
				config.button_sizes = {"small": Vector2(80, 40), "medium": Vector2(100, 50), "large": Vector2(120, 60)}
				config.spacings = {"small": 5, "medium": 10, "large": 15}
				config.grid_size = 4
			else:
				config.font_sizes = {"small": 16, "medium": 20, "large": 26}
				config.button_sizes = {"small": Vector2(70, 35), "medium": Vector2(90, 45), "large": Vector2(110, 55)}
				config.spacings = {"small": 8, "medium": 12, "large": 18}
				config.grid_size = 4
		
		DeviceManager.DeviceType.TABLET:
			config.font_sizes = {"small": 18, "medium": 22, "large": 28}
			config.button_sizes = {"small": Vector2(90, 45), "medium": Vector2(110, 55), "large": Vector2(130, 65)}
			config.spacings = {"small": 10, "medium": 15, "large": 20}
			config.grid_size = 4
		
		DeviceManager.DeviceType.DESKTOP:
			config.font_sizes = {"small": 16, "medium": 20, "large": 24}
			config.button_sizes = {"small": Vector2(100, 40), "medium": Vector2(120, 50), "large": Vector2(140, 60)}
			config.spacings = {"small": 10, "medium": 15, "large": 20}
			config.grid_size = 4
	
	return config
