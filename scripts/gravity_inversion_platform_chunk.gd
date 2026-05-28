extends PlatformChunk

@onready var trigger_area: Area2D = $CenterTrigger

var _triggered: bool = false

func _ready() -> void:
	chunk_width = 528.0
	if trigger_area:
		trigger_area.body_entered.connect(_on_player_passed_center)

func _on_player_passed_center(body: Node) -> void:
	if _triggered:
		return
		
	if body.is_in_group("player") and body.has_method("flip_gravity"):
		_triggered = true
		body.flip_gravity()
