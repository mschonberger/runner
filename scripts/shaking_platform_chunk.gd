extends PlatformChunk

@onready var step_trigger: Area2D = $StepTrigger

var _player_ref: CharacterBody2D = null

func _ready() -> void:
	chunk_width = 1584.0
	
	if step_trigger:
		step_trigger.body_entered.connect(_on_player_entered)
		step_trigger.body_exited.connect(_on_player_exited)

func _exit_tree() -> void:
	if is_instance_valid(_player_ref) and _player_ref.has_method("set_continuous_shake"):
		_player_ref.set_continuous_shake(false)

func _on_player_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_ref = body as CharacterBody2D
		if _player_ref.has_method("set_continuous_shake"):
			_player_ref.set_continuous_shake(true)

func _on_player_exited(body: Node) -> void:
	if body == _player_ref:
		if is_instance_valid(_player_ref) and _player_ref.has_method("set_continuous_shake"):
			_player_ref.set_continuous_shake(false)
		_player_ref = null
