extends PlatformChunk

@export var sink_speed: float = 120.0 
@export var max_sink_depth: float = 200.0 

@onready var step_trigger: Area2D = $StepTrigger

var _is_sinking: bool = false
var _initial_y: float = 0.0

func _ready() -> void:
	chunk_width = 1056.0 # Match your inspector configuration
	_initial_y = global_position.y
	if step_trigger:
		step_trigger.body_entered.connect(_on_player_stepped)

func _physics_process(delta: float) -> void:
	# Maintain horizontal scroll
	super._physics_process(delta)
	
	if _is_sinking:
		if position.y < _initial_y + max_sink_depth:
			position.y += sink_speed * delta
			
			# 🚨 THE SMOOTHNESS MAGIC:
			# Tell the physics server to automatically pull down anything standing on us
			constant_linear_velocity.y = sink_speed
			
			if position.y >= _initial_y + max_sink_depth:
				position.y = _initial_y + max_sink_depth
				constant_linear_velocity.y = 0.0 # Stop physics pulling when depth limit reached
		else:
			constant_linear_velocity.y = 0.0

func _on_player_stepped(body: Node) -> void:
	if body.is_in_group("player") and not _is_sinking:
		_is_sinking = true
		if step_trigger:
			step_trigger.queue_free()
