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

@export var post_hit_suppression_time: float = 2.5 
var _suppression_timer: float = 0.0

var current_speed: float = 0.0
var running: bool = false
var can_start: bool = true

var current_score: float = 0.0

# Store top 3 scores as an Array of Dictionaries
var leaderboard: Array = []

signal highscore_achieved(score_value: float)

func _ready() -> void:
	add_to_group("game_manager")
	current_speed = base_speed
	running = false
	can_start = true
	_load_leaderboard()

func _physics_process(delta: float) -> void:
	if not running:
		return

	current_score += current_speed * delta * 0.1

	if _suppression_timer > 0.0:
		_suppression_timer -= delta
	else:
		var speed_percentage: float = current_speed / max_speed
		var dynamic_accel: float = lerp(320.0, 45.0, speed_percentage)
		current_speed += dynamic_accel * delta
		current_speed = min(current_speed, max_speed)

func start_running() -> void:
	if running or not can_start:
		return
	running = true
	current_speed = max(current_speed, start_speed)

func stop_running() -> void:
	running = false
	current_speed = base_speed

	if _qualifies_for_leaderboard(current_score):
		can_start = false 
		highscore_achieved.emit(current_score)
	else:
		current_score = 0.0

func apply_speed_penalty(extra_amount: float) -> void:
	# Immediate impact slam
	current_speed *= hit_impact_multiplier

	# Scaled penalty so it always hurts at high speed
	var scaled: float = current_speed * penalty_speed_fraction
	var total: float = penalty_flat + scaled + extra_amount

	current_speed = max(min_speed_floor, current_speed - total)
	_suppression_timer = post_hit_suppression_time

func _qualifies_for_leaderboard(score_value: float) -> bool:
	if score_value <= 0.0:
		return false
	if leaderboard.size() < 3:
		return true
	return score_value > leaderboard[-1]["score"]

func get_best_score() -> float:
	if leaderboard.is_empty():
		return 0.0
	return leaderboard[0]["score"]

func add_leaderboard_entry(player_name: String, score_value: float) -> void:
	if player_name.strip_edges() == "":
		player_name = "AAA"
		
	var new_entry = {"name": player_name.to_upper().substr(0, 8), "score": score_value}
	leaderboard.append(new_entry)
	
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	
	if leaderboard.size() > 3:
		leaderboard.resize(3)
		
	_save_leaderboard()
	current_score = 0.0
	can_start = true

func _load_leaderboard() -> void:
	leaderboard.clear()
	if FileAccess.file_exists("user://leaderboard.dat"):
		var file = FileAccess.open("user://leaderboard.dat", FileAccess.READ)
		var json_string = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			if json.data is Array:
				leaderboard = json.data
				return
				
	leaderboard = [
		{"name": "MALTE", "score": 5000.0},
		{"name": "LUCA", "score": 3000.0},
		{"name": "MARK", "score": 1500.0}
	]

func _save_leaderboard() -> void:
	var file = FileAccess.open("user://leaderboard.dat", FileAccess.WRITE)
	var json_string = JSON.stringify(leaderboard)
	file.store_string(json_string)
