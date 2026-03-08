class_name Enemy
extends CharacterBody3D

const GRAVITY_MULTIPLIER = 1.1

@export var speed = 1
@export var speed_variance = 0.0
@export var mass_kg = 50.0
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
	
	_push_away_rigid_bodies()
	move_and_slide()
	
	if global_position.y < -3:
		global_position = spawn


func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
			var mass_ratio = min(1., mass_kg / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.25:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			# 5.0 is a magic number, adjust to your needs
			var push_force = mass_ratio / 5.0
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)
