class_name Enemy
extends CharacterBody3D

const GRAVITY_MULTIPLIER = 1.1

@export var speed = 1
@export var speed_variance = 0.0
@onready var model: Node3D = $model

var spawn: Vector3

func _ready() -> void:
	speed += randf_range(-speed_variance, speed_variance)
	spawn = global_position

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += (get_gravity() * GRAVITY_MULTIPLIER) * delta
	
	if not Global.player: return
	var player: Player = Global.player
	
	# Get the input direction and handle the movement/deceleration.
	var direction: Vector3 = global_position.direction_to(player.global_position).normalized()
	direction.y = 0.0
	
	if direction:
		# Rotate in the direction of movement
		var before_rotation := model.rotation
		model.look_at(model.global_position + direction)
		var target_rotation: float = model.rotation.y
		model.rotation = before_rotation
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, 0.1)
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	move_and_slide()
	
	if global_position.y < -3:
		global_position = spawn
