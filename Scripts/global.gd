extends Node


var world_gridmap: GridMap = null
var player: Player = null

func  _ready() -> void:
	get_viewport().get_window().mode = Window.MODE_FULLSCREEN


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		if get_viewport().get_window().mode == Window.MODE_FULLSCREEN:
			get_viewport().get_window().mode = Window.MODE_WINDOWED
			var ratio = Vector2(get_viewport().get_window().size) / Vector2(DisplayServer.screen_get_size())
			var percent = (ratio.x + ratio.y) / 2
			if percent > .75:
				get_viewport().get_window().size.x /= 1.5
				get_viewport().get_window().size.y /= 1.472
			get_viewport().get_window().move_to_center()
		else:
			get_viewport().get_window().mode = Window.MODE_FULLSCREEN
