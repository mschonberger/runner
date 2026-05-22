extends Area2D

@export var move_speed: float = 160.0
@export var move_range: float = 100.0

var _time_passed: float = 0.0
var _initial_y: float = 0.0

func _ready() -> void:
	_time_passed = randf_range(0.0, 5.0)
	body_entered.connect(_on_body_entered)
	_initial_y = position.y

func _physics_process(delta: float) -> void:
	_time_passed += delta

	var offset: float = sin(_time_passed * (move_speed / 50.0)) * move_range
	position.y = _initial_y + offset

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		if body.has_method("_die_and_reset"):
			body.call_deferred("_die_and_reset")
