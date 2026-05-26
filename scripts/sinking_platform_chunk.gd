extends PlatformChunk

@export var sink_speed: float = 75.0 
@export var max_sink_depth: float = 110.0 

@onready var step_trigger: Area2D = $StepTrigger

var _is_sinking: bool = false
var _initial_y: float = 0.0

func _ready() -> void:
	chunk_width = 1584.0
	_initial_y = global_position.y
	if step_trigger:
		step_trigger.body_entered.connect(_on_player_stepped)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if _is_sinking:
		if position.y < _initial_y + max_sink_depth:
			position.y += sink_speed * delta
			
			constant_linear_velocity.y = sink_speed
			
			if position.y >= _initial_y + max_sink_depth:
				position.y = _initial_y + max_sink_depth
				constant_linear_velocity.y = 0.0
		else:
			constant_linear_velocity.y = 0.0

func _on_player_stepped(body: Node) -> void:
	if body.is_in_group("player") and not _is_sinking:
		_is_sinking = true
		if step_trigger:
			step_trigger.queue_free()
