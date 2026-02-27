extends CharacterBody3D

@export var sensitivity: float = 1.0

const SPEED = 4.0
const JUMP_VELOCITY = 5
const GRAVITY_MULTIPLIER = 1.1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += (get_gravity() * GRAVITY_MULTIPLIER) * delta

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if global_position.y < -3:
		global_position = Vector3(0, 5, 0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y += (-event.relative.x / 10) * sensitivity
		%CollisionShape3D.global_rotation_degrees.y = 0
		$BlockPlaceCheckArea3D/CollisionShape3D.global_rotation_degrees.y = 0
		%CameraAnchor.rotation_degrees.x += (-event.relative.y / 10) * sensitivity
		%CameraAnchor.rotation_degrees.x = clampf(%CameraAnchor.rotation_degrees.x, -90.0, 90.0)
	
func _process(delta: float) -> void:
	var normal: Vector3            # The side of the block being looked at
	var ray_hit_pos: Vector3       # The exact position of the collison in the ray
	var target_block_pos: Vector3  # The center position of block being looked at
	var placing_block_pos: Vector3 # The center position of block to be placed with right click
	if %BlockInteractionRay.is_colliding():
		# Get and calculate positions
		normal = %BlockInteractionRay.get_collision_normal() / 2
		ray_hit_pos = %BlockInteractionRay.get_collision_point()
		target_block_pos = Global.world_gridmap.map_to_local(Global.world_gridmap.local_to_map(ray_hit_pos - normal)) 
		placing_block_pos = target_block_pos + (normal * 2)
		
		# Show where a block can be placed
		%BlockPlacingPreview.global_position = placing_block_pos
		%BlockPlacingPreview.show()
		
		# Placing and breaking block
		if Input.is_action_just_pressed("place_block"):
			Global.world_gridmap.set_cell_item(Global.world_gridmap.local_to_map(placing_block_pos), 0)
			#print(str(%BlockPlaceCheckArea3D.has_overlapping_bodies()) + ", " + str(%BlockPlaceCheckArea3D.has_overlapping_areas()))
		
		if Input.is_action_just_pressed("break_block"):
			Global.world_gridmap.set_cell_item(Global.world_gridmap.local_to_map(target_block_pos), -1)
	else:
		%BlockPlacingPreview.hide()
	
