extends Node
class_name GameManager

@export var base_speed: float = 0.0
@export var start_speed: float = 250.0
@export var max_speed: float = 950.0

@export var accel_speed_factor: float = 0.4

@export var penalty_flat: float = 160.0
@export var penalty_speed_fraction: float = 0.22
@export var hit_impact_multiplier: float = 0.70
@export var min_speed_floor: float = 80.0

@export var post_hit_suppression_time: float = 2.5 # Seconds before acceleration restores
var _suppression_timer: float = 0.0

var current_speed: float = 0.0
var running: bool = false
var can_start: bool = true

var current_score: float = 0.0
var highscore: float = 0.0

func _ready() -> void:
	add_to_group("game_manager")
	current_speed = base_speed
	running = false
	can_start = true
	_load_highscore()

func _physics_process(delta: float) -> void:
	# score
	current_score += current_speed * delta * 0.1

	if _suppression_timer > 0.0:
		_suppression_timer -= delta
	else: # Only apply acceleration if the player hasn't crashed recently!
		# Calculate how far we are from top speed (0.0 = at base, 1.0 = at max speed)
		var speed_percentage: float = current_speed / max_speed
		# Dynamic easing: Accelerate faster when moving slow, slower when moving fast
		var dynamic_accel: float = lerp(320.0, 45.0, speed_percentage)
		current_speed += dynamic_accel * delta
		current_speed = min(current_speed, max_speed)

func start_running() -> void:
	if running:
		return
	running = true
	current_speed = max(current_speed, start_speed)

func stop_running() -> void:
	running = false
	current_speed = base_speed

	if current_score > highscore:
		highscore = current_score
		_save_highscore()

	current_score = 0.0

func apply_speed_penalty(extra_amount: float) -> void:

	# Immediate impact slam
	current_speed *= hit_impact_multiplier

	# Scaled penalty so it always hurts at high speed
	var scaled: float = current_speed * penalty_speed_fraction
	var total: float = penalty_flat + scaled + extra_amount

	current_speed = max(min_speed_floor, current_speed - total)
	_suppression_timer = post_hit_suppression_time

func _load_highscore() -> void:
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		highscore = file.get_float()

func _save_highscore() -> void:
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_float(highscore)
