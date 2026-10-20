extends CharacterBody3D

# --- Movement ---
const WALK_SPEED       := 5.0
const SPRINT_SPEED     := 8.0
const JUMP_VELOCITY    := 10.0
const ACCELERATION     := 20.0
const FRICTION         := 18.0
const MESH_ROTATE_SPEED := 12.0   # rad/s – how fast the mesh turns to face movement

# --- Camera Orbit ---
const MOUSE_SENSITIVITY := 0.002
const LOOK_SPEED        := 2.0    # rad/s for keyboard / joystick orbit
const PITCH_MIN         := deg_to_rad(-80.0)
const PITCH_MAX         := deg_to_rad(45.0)
const CAM_RESET_SPEED   := 10.0    # rad/s for Z-key camera-reset lerp

@onready var spring_arm:  SpringArm3D    = $SpringArm3D
@onready var ranger:      Node3D         = $Ranger
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const ANIM_BLEND := 0.2
const ANIM_RUN   := "Rig_Medium_MovementBasic/Running_A"
const ANIM_WALK  := "Rig_Medium_MovementBasic/Walking_A"
const ANIM_IDLE  := "Rig_Medium_General/Idle_A"
const ANIM_JUMP  := "Rig_Medium_MovementBasic/Jump_Idle"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Quest ---
var _was_on_floor    := false
var _quest_complete  := false

# --- Fall detection ---
const FALL_THRESHOLD := -20.0
var _spawn_position:  Vector3
var _fell_off         := false
var _movement_enabled := true

# --- Camera reset state ---
var _cam_resetting := false


func _ready() -> void:
	spring_arm.add_excluded_object(self.get_rid())
	_spawn_position = global_position
	# Mouse capture is handled by the click-to-play overlay in quest_ui.gd.


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Orbit yaw: spin spring arm horizontally around the character.
		spring_arm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		# Orbit pitch: tilt spring arm up/down, clamped.
		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			PITCH_MIN, PITCH_MAX
		)
		_cam_resetting = false

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var ui := get_tree().get_first_node_in_group("quest_ui")
		if ui:
			ui.show_click_overlay()

	if event.is_action_pressed("camera_reset"):
		_cam_resetting = true


func _physics_process(delta: float) -> void:
	if not _movement_enabled:
		return

	# Fall-off detection.
	if not _fell_off and global_position.y < FALL_THRESHOLD:
		_fell_off = true
		_movement_enabled = false
		velocity = Vector3.ZERO
		var ui := get_tree().get_first_node_in_group("quest_ui")
		if ui:
			ui.show_fell_off(respawn)
		return

	# Gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Camera orbit: keyboard arrow keys and right touch joystick.
	var look := _get_look_input()
	if look.length_squared() > 0.0:
		spring_arm.rotation.y -= look.x * LOOK_SPEED * delta
		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x - look.y * LOOK_SPEED * delta,
			PITCH_MIN, PITCH_MAX
		)
		_cam_resetting = false

	# Camera reset (Z key): smoothly lerp orbit back to directly behind the mesh.
	if _cam_resetting:
		_update_cam_reset(delta)

	# Movement input: keyboard first, then mobile left joystick.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length_squared() < 0.01:
		input_dir = _get_joystick_input()

	# Build camera-relative horizontal wish direction from the spring arm's yaw only.
	# Using a yaw-only basis keeps movement flat regardless of camera pitch.
	var cam_yaw_basis := Basis(Vector3.UP, spring_arm.rotation.y)
	var wish_dir := (cam_yaw_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var sprinting := _is_sprinting()
	var target_speed: float = SPRINT_SPEED if sprinting else WALK_SPEED

	if wish_dir.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, wish_dir.x * target_speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, wish_dir.z * target_speed, ACCELERATION * delta)
		# Smoothly rotate the mesh to face the direction of travel.
		# atan2(-x, -z) accounts for the 180° baked into the Ranger model's transform.
		# comment added by user jonny. I removed the negative signs. Now it works as expected. the negative signs were causing moonwalking.
		var target_angle := atan2(wish_dir.x, wish_dir.z)
		ranger.rotation.y = lerp_angle(ranger.rotation.y, target_angle, MESH_ROTATE_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	var was_on_floor_before := _was_on_floor
	move_and_slide()
	_was_on_floor = is_on_floor()

	_update_animation(wish_dir, sprinting)

	if not was_on_floor_before and is_on_floor() and not _quest_complete:
		_check_bush_landing()


# ---------------------------------------------------------------------------
# Camera reset
# ---------------------------------------------------------------------------

func _update_cam_reset(delta: float) -> void:
	# Target yaw: +PI offset places the camera directly behind the player's
	# current facing direction (ranger.rotation.y encodes world-space facing).
	var target_yaw := ranger.rotation.y + PI
	spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, target_yaw, CAM_RESET_SPEED * delta)
	spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, 0.0, CAM_RESET_SPEED * delta)

	var yaw_diff   := absf(angle_difference(spring_arm.rotation.y, target_yaw))
	var pitch_diff := absf(spring_arm.rotation.x)
	if yaw_diff < 0.015 and pitch_diff < 0.015:
		spring_arm.rotation.y = target_yaw
		spring_arm.rotation.x = 0.0
		_cam_resetting = false


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func respawn() -> void:
	global_position = _spawn_position
	velocity        = Vector3.ZERO
	_fell_off        = false
	_movement_enabled = true
	var ui := get_tree().get_first_node_in_group("quest_ui")
	if ui:
		ui.show_click_overlay()


func _get_joystick_input() -> Vector2:
	var ui := get_tree().get_first_node_in_group("quest_ui")
	if ui and ui.has_method("get_joystick_vector"):
		return ui.get_joystick_vector()
	return Vector2.ZERO


func _get_look_input() -> Vector2:
	# Arrow keys take priority; fall back to right touch joystick.
	var key := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)
	if key.length_squared() > 0.01:
		return key
	var ui := get_tree().get_first_node_in_group("quest_ui")
	if ui and ui.has_method("get_look_vector"):
		return ui.get_look_vector()
	return Vector2.ZERO


func _check_bush_landing() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col and "Bush" in str(col.get_collider().get_path()):
			_quest_complete = true
			var ui := get_tree().get_first_node_in_group("quest_ui")
			if ui:
				ui.complete_quest()
			return


func _is_sprinting() -> bool:
	return Input.is_physical_key_pressed(KEY_SHIFT)


func _update_animation(wish_dir: Vector3, sprinting: bool) -> void:
	var target_anim: String
	if not is_on_floor():
		target_anim = ANIM_JUMP
	elif wish_dir or Vector2(velocity.x, velocity.z).length_squared() > 0.01:
		target_anim = ANIM_RUN if sprinting else ANIM_WALK
	else:
		target_anim = ANIM_IDLE

	if anim_player.current_animation != target_anim:
		anim_player.play(target_anim, ANIM_BLEND)
