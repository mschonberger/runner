extends PlatformChunk

@onready var trigger_area: Area2D = $CenterTrigger

var _has_executed: bool = false

func _ready() -> void:
	chunk_width = 528.0
	_has_executed = false

	if trigger_area:
		if trigger_area.body_entered.is_connected(_on_player_passed_center):
			trigger_area.body_entered.disconnect(_on_player_passed_center)
		trigger_area.body_entered.connect(_on_player_passed_center)

func _on_player_passed_center(body: Node) -> void:
	if _has_executed:
		return

	if body.is_in_group("player") and body.has_method("toggle_color_inversion"):
		_has_executed = true
		body.toggle_color_inversion()
