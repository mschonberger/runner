extends CharacterBody2D

enum PlayerState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	LAND,
	HIT,
	DASH
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var cam: Camera2D = get_node_or_null("Camera2D") as Camera2D

@onready var standard_shape: CollisionShape2D = $StandardShape
@onready var dash_shape: CollisionShape2D = $DashShape

@export var base_gravity: float = 1800.0

@export var jump_velocity_min: float = -560.0
@export var jump_velocity_max: float = -760.0
@export var gravity_scale_min: float = 1.20
@export var gravity_scale_max: float = 0.95

@export var run_threshold: float = 360.0

@export var coyote_time_max: float = 0.12
@export var jump_cut_multiplier: float = 0.5

@export var hit_lock_time: float = 0.25

@export var shake_time: float = 0.15
@export var shake_strength: float = 6.0

@export var fall_reset_y: float = 900.0

# Dash
@export var dash_speed_bonus: float = 300.0
@export var dash_duration: float = 99.0
@export var dash_cooldown: float = 1.0

# Air dash
@export var air_dash_duration: float = 0.18
@export var dash_air_boost_velocity: float = -220.0
@export var dash_gravity_multiplier: float = 1.20

var _is_dashing: bool = false
var _dash_started_in_air: bool = false
var _dash_time_left: float = 0.0

# Only used to block AIR dash
var _dash_cooldown_left: float = 0.0

# Air dash usage control
var _air_dash_used_this_air: bool = false
var _start_cooldown_on_next_landing: bool = false

# Cache animation length so air dash can play fully
var _air_spin_anim_len: float = 0.0

var state: PlayerState = PlayerState.IDLE
var started: bool = false
var was_on_floor: bool = false

var coyote_time_left: float = 0.0
var anchor_x: float = 0.0
var _can_be_hit: bool = true

var gm: GameManager
var world: WorldRunner
var fader: ScreenFader

var _shake_left: float = 0.0
var _cam_base_pos: Vector2 = Vector2.ZERO

var _start_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	gm = get_parent().get_node("GameManager") as GameManager
	world = get_parent().get_node("World") as WorldRunner
	fader = get_tree().get_first_node_in_group("screen_fader") as ScreenFader

	state = PlayerState.IDLE
	started = false
	velocity = Vector2.ZERO

	_start_pos = global_position
	anchor_x = global_position.x

	# Default collision shapes
	if standard_shape != null:
		standard_shape.disabled = false
	if dash_shape != null:
		dash_shape.disabled = true

	# Cache air_spin animation length so it doesn't get cut short
	_air_spin_anim_len = _get_animation_length("air_spin")

	if cam != null:
		_cam_base_pos = cam.position


func _physics_process(delta: float) -> void:
	velocity.x = 0.0

	_handle_gravity(delta)
	_handle_coyote_time(delta)
	_update_shake(delta)
	_handle_dash(delta)

	# During HIT: allow emergency jump
	if state == PlayerState.HIT:
		_handle_emergency_jump()
		move_and_slide()
		global_position.x = anchor_x
		_check_fall_reset()
		return

	_handle_start_or_jump()
	_handle_variable_jump()
	_handle_state_machine()

	move_and_slide()
	global_position.x = anchor_x

	_check_fall_reset()


func _process(_delta: float) -> void:
	_update_animation()


func _speed_t() -> float:
	if gm == null:
		return 0.0
	return clamp(gm.current_speed / gm.max_speed, 0.0, 1.0)


func _effective_jump_velocity() -> float:
	var t: float = _speed_t()
	return lerp(jump_velocity_min, jump_velocity_max, t)


func _effective_gravity_scale() -> float:
	var t: float = _speed_t()
	return lerp(gravity_scale_min, gravity_scale_max, t)


func _handle_gravity(delta: float) -> void:
	var g_scale: float = _effective_gravity_scale()

	if _is_dashing:
		g_scale *= dash_gravity_multiplier

	if not is_on_floor():
		velocity.y += base_gravity * g_scale * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0


func _handle_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_time_left = coyote_time_max

		# Reset air dash availability when back on floor
		_air_dash_used_this_air = false

		# Start cooldown only AFTER landing (for air dash only)
		if _start_cooldown_on_next_landing:
			_dash_cooldown_left = dash_cooldown
			_start_cooldown_on_next_landing = false
	else:
		coyote_time_left -= delta


func _handle_start_or_jump() -> void:
	if gm != null and not gm.can_start:
		return

	if not Input.is_action_just_pressed("jump"):
		return

	if not started:
		started = true
		if gm != null:
			gm.start_running()
		state = PlayerState.WALK
		return

	if coyote_time_left > 0.0:
		velocity.y = _effective_jump_velocity()
		state = PlayerState.JUMP
		coyote_time_left = 0.0


func _handle_emergency_jump() -> void:
	if gm != null and not gm.can_start:
		return

	if Input.is_action_just_pressed("jump") and coyote_time_left > 0.0:
		velocity.y = _effective_jump_velocity()
		coyote_time_left = 0.0


func _handle_variable_jump() -> void:
	if Input.is_action_just_released("jump"):
		if velocity.y < 0.0:
			velocity.y *= jump_cut_multiplier


func _handle_state_machine() -> void:
	if _is_dashing:
		return

	var on_floor: bool = is_on_floor()

	if not started:
		state = PlayerState.IDLE
		was_on_floor = on_floor
		return

	var world_speed: float = 0.0
	if gm != null:
		world_speed = gm.current_speed

	if not on_floor:
		if velocity.y < 0.0:
			state = PlayerState.JUMP
		else:
			state = PlayerState.FALL
	else:
		if not was_on_floor:
			state = PlayerState.LAND
		else:
			if world_speed < run_threshold:
				state = PlayerState.WALK
			else:
				state = PlayerState.RUN

	was_on_floor = on_floor


func _update_animation() -> void:
	match state:
		PlayerState.IDLE:
			_play_if_not("idle")
		PlayerState.WALK:
			if anim.sprite_frames.has_animation("walk"):
				_play_if_not("walk")
			else:
				_play_if_not("run")
		PlayerState.RUN:
			_play_if_not("run")
		PlayerState.JUMP:
			_play_if_not("jump")
		PlayerState.FALL:
			if anim.sprite_frames.has_animation("fall"):
				_play_if_not("fall")
			else:
				_play_if_not("jump")
		PlayerState.LAND:
			_play_if_not("land")
		PlayerState.HIT:
			_play_if_not("hurt")
		PlayerState.DASH:
			# Air dash uses air_spin; ground dash uses dash
			if _dash_started_in_air:
				if anim.sprite_frames.has_animation("air_spin"):
					_play_if_not("air_spin")
				else:
					if anim.sprite_frames.has_animation("dash"):
						_play_if_not("dash")
					else:
						_play_if_not("run")
			else:
				if anim.sprite_frames.has_animation("dash"):
					_play_if_not("dash")
				else:
					_play_if_not("run")


func _play_if_not(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)


func apply_hit() -> void:
	if not _can_be_hit:
		return

	_can_be_hit = false
	state = PlayerState.HIT
	_start_shake()

	var timer := get_tree().create_timer(hit_lock_time)
	timer.timeout.connect(_end_hit)


func _end_hit() -> void:
	_can_be_hit = true
	if started:
		state = PlayerState.FALL
	else:
		state = PlayerState.IDLE


func _start_shake() -> void:
	_shake_left = shake_time
	if cam != null:
		_cam_base_pos = cam.position


func _update_shake(delta: float) -> void:
	if cam == null:
		return

	if _shake_left > 0.0:
		_shake_left -= delta
		var off := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		cam.position = _cam_base_pos + off
	else:
		cam.position = _cam_base_pos


func _check_fall_reset() -> void:
	if global_position.y <= fall_reset_y:
		return

	_die_and_reset()


func _die_and_reset() -> void:
	if fader != null and fader.is_busy():
		return

	if gm != null:
		gm.stop_running()

	if fader != null:
		fader.fade_reset_and_fade_in(Callable(self, "_reset_run"))
	else:
		_reset_run()


func _reset_run() -> void:
	global_position = _start_pos
	anchor_x = _start_pos.x
	velocity = Vector2.ZERO
	state = PlayerState.IDLE
	started = false
	_can_be_hit = true

	_is_dashing = false
	_dash_started_in_air = false
	_dash_time_left = 0.0
	_dash_cooldown_left = 0.0
	_air_dash_used_this_air = false
	_start_cooldown_on_next_landing = false

	if standard_shape != null:
		standard_shape.disabled = false
	if dash_shape != null:
		dash_shape.disabled = true

	if world != null:
		world.reset_world()


# ---------------- DASH ----------------

func _handle_dash(delta: float) -> void:
	# Cooldown countdown (ONLY blocks air dash)
	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left -= delta

	# Only allow dash after run started and while not hit
	if not started or gm == null or not gm.running:
		return
	if state == PlayerState.HIT:
		return

	var on_floor: bool = is_on_floor()

	# START dash
	if Input.is_action_just_pressed("dash") and not _is_dashing:

		# Air dash is restricted (single use + cooldown)
		if not on_floor:
			if _air_dash_used_this_air:
				return
			if _dash_cooldown_left > 0.0:
				return

		_is_dashing = true
		_dash_started_in_air = not on_floor
		state = PlayerState.DASH

		# Collision shapes:
		# - ground dash uses dash shape
		# - air dash keeps standard shape
		if _dash_started_in_air:
			if standard_shape != null:
				standard_shape.disabled = false
			if dash_shape != null:
				dash_shape.disabled = true
		else:
			if standard_shape != null:
				standard_shape.disabled = true
			if dash_shape != null:
				dash_shape.disabled = false

		# Speed boost
		gm.current_speed += dash_speed_bonus
		gm.current_speed = min(gm.current_speed, gm.max_speed)

		if _dash_started_in_air:
			# Air dash: short burst, ensure animation can play fully
			var min_len: float = air_dash_duration
			if _air_spin_anim_len > min_len:
				min_len = _air_spin_anim_len

			_dash_time_left = min_len
			_air_dash_used_this_air = true

			# cooldown begins after landing
			_start_cooldown_on_next_landing = true

			# air recovery
			velocity.y = min(velocity.y, dash_air_boost_velocity)
		else:
			# Ground dash: holdable, long max duration
			_dash_time_left = dash_duration

	# MAINTAIN dash
	if _is_dashing:

		if _dash_started_in_air:
			# Air dash cannot be held; just count down
			_dash_time_left -= delta
			if _dash_time_left <= 0.0:
				_end_dash()
				return

		else:
			# Ground dash stays while held
			if not Input.is_action_pressed("dash"):
				_end_dash()
				return

			if dash_duration > 0.0:
				_dash_time_left -= delta
				if _dash_time_left <= 0.0:
					_end_dash()
					return

			# sustain push on ground dash
			gm.current_speed += (dash_speed_bonus * 0.5) * delta
			gm.current_speed = min(gm.current_speed, gm.max_speed)


func _end_dash() -> void:
	_is_dashing = false
	_dash_started_in_air = false

	# Restore standard collision shape
	if standard_shape != null:
		standard_shape.disabled = false
	if dash_shape != null:
		dash_shape.disabled = true

	# No cooldown for ground dash. Air dash cooldown starts on landing via _start_cooldown_on_next_landing.

	# Leave dash state cleanly
	if not is_on_floor():
		state = PlayerState.FALL
	else:
		var ws: float = gm.current_speed if gm != null else 0.0
		if ws < run_threshold:
			state = PlayerState.WALK
		else:
			state = PlayerState.RUN


func _get_animation_length(anim_name: String) -> float:
	if anim == null:
		return 0.0
	if anim.sprite_frames == null:
		return 0.0
	if not anim.sprite_frames.has_animation(anim_name):
		return 0.0

	var frames: int = anim.sprite_frames.get_frame_count(anim_name)
	var speed: float = anim.sprite_frames.get_animation_speed(anim_name)

	if speed <= 0.0:
		return 0.0

	return float(frames) / speed
