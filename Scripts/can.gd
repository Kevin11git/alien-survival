extends RigidBody3D

var spawn: Vector3

func _ready() -> void:
	spawn = global_position

func _physics_process(delta: float) -> void:
	if global_position.y < -10:
		global_position = spawn
		global_rotation  = Vector3.ZERO
		linear_velocity  = Vector3.ZERO
		angular_velocity = Vector3.ZERO


func show_outline():
	%OutlineMesh.show()
	%HideOutlineTimer.start()

func hide_outline():
	%OutlineMesh.hide()


func _on_hide_outline_timer_timeout() -> void:
	hide_outline()
