extends PlatformChunk

@onready var sprite: Sprite2D = $Sprite2D

var _zoom_triggered: bool = false
var _original_offset_x: float = 200.0

func _ready() -> void:
	super._ready()
	chunk_width = 1584.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var platform_left_edge: float = global_position.x - (chunk_width / 2.0)
		var run_distance: float = player.global_position.x - platform_left_edge
		
		if run_distance >= 0.0 and run_distance <= chunk_width:
			var target_zoom: float = 1.0
			var three_quarter_mark: float = chunk_width * 0.75
			
			if run_distance <= three_quarter_mark:
				var t: float = run_distance / three_quarter_mark
				target_zoom = lerp(1.0, 2.2, t)
			else:
				var t: float = (run_distance - three_quarter_mark) / (chunk_width - three_quarter_mark)
				target_zoom = lerp(2.2, 1.0, t)
				
			if player.has_node("Camera2D"):
				var cam = player.get_node("Camera2D") as Camera2D
				if cam:
					cam.zoom = Vector2(target_zoom, target_zoom)
					cam.offset.x = _original_offset_x / target_zoom
			_zoom_triggered = true
			
		elif _zoom_triggered:
			if player.has_node("Camera2D"):
				var cam = player.get_node("Camera2D") as Camera2D
				if cam:
					cam.zoom = Vector2(1.0, 1.0)
					cam.offset.x = _original_offset_x
			_zoom_triggered = false
