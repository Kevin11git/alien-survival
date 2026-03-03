class_name Player
extends CharacterBody3D

@export var sensitivity: float = 1.0

const SPEED = 4.0
const JUMP_VELOCITY = 5
const GRAVITY_MULTIPLIER = 1.1

var selected_block: int = 0:
	set(val):
		selected_block = wrapi(val, 0, Global.world_gridmap.mesh_library.get_item_list().size())
		update_selected_block()
# Before placing a block it can be rotated
# in the Y axis using the "rotate_block" action which is R by default
var selected_rotation: float = 0: # (In degrees)
	set(val):
		selected_rotation = fposmod(val, 360.0)
		%BlockPlacingPreviewAnchor.rotation_degrees.y = selected_rotation

func update_selected_block():
	if not Global.world_gridmap:
		printerr("Gridmap not set!")
		return
	
	selected_rotation = 0 # Reset rotation
	%BlockPlacingPreview.mesh = Global.world_gridmap.mesh_library.get_item_mesh(selected_block)
	# Some block meshes are not fully centered
	%BlockPlacingPreview.transform = Global.world_gridmap.mesh_library.get_item_mesh_transform(selected_block)
	var hotbar_item = get_node_or_null("%HotbarItem" + str(selected_block + 1))
	if hotbar_item:
		%SelectedHotbarItem.reparent(get_node("%HotbarItem" + str(selected_block + 1)), false)
		%SelectedHotbarItem.show()
	else:
		%SelectedHotbarItem.hide()


func _ready() -> void:
	Global.player = self
	%Hotbar.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Wait for gridmap to be ready
	await get_tree().process_frame
	# setup hotbar
	for i in 4:
		var hotbar_item: TextureRect = get_node("%HotbarItem" + str(i + 1))
		hotbar_item.texture = Global.world_gridmap.mesh_library.get_item_preview(i)
	%Hotbar.show()
	selected_block = selected_block # run setter
	
	

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
		
	# Select block from hotbar using scroll wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_block += 1
		if event.button_index == MOUSE_BUTTON_WHEEL_UP :
			selected_block -= 1


func _process(delta: float) -> void:
	# Select block from hotbar using number keys
	if Input.is_physical_key_pressed(KEY_1):
		selected_block = 0
	if Input.is_physical_key_pressed(KEY_2):
		selected_block = 1
	if Input.is_physical_key_pressed(KEY_3):
		selected_block = 2
	if Input.is_physical_key_pressed(KEY_4):
		selected_block = 3
	
	# rotate block to place
	if Input.is_action_just_pressed("rotate_block"):
		selected_rotation += 90
	
	# process block breaking, placing and showing %BlockPlacingPreview
	process_block_interaction()

func process_block_interaction():
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
		%BlockPlacingPreviewAnchor.global_position = placing_block_pos
		%BlockPlacingPreview.show()
		
		# Placing and breaking block
		if Input.is_action_just_pressed("place_block"):
			Global.world_gridmap.set_cell_item(Global.world_gridmap.local_to_map(placing_block_pos), selected_block, rotation_to_gridmap_orientation(selected_rotation))
			#print(str(%BlockPlaceCheckArea3D.has_overlapping_bodies()) + ", " + str(%BlockPlaceCheckArea3D.has_overlapping_areas()))
		
		if Input.is_action_just_pressed("break_block"):
			Global.world_gridmap.set_cell_item(Global.world_gridmap.local_to_map(target_block_pos), -1)
	else:
		%BlockPlacingPreview.hide()

func rotation_to_gridmap_orientation(angle_degrees: float, axis: Vector3 = Vector3.UP):
	var toQuaternion: Quaternion = Quaternion(axis, deg_to_rad(angle_degrees))
	var cell_item_orientation: int = Global.world_gridmap.get_orthogonal_index_from_basis(Basis(toQuaternion))
	return cell_item_orientation
