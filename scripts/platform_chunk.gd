# res://scripts/platform_chunk.gd
extends StaticBody2D
class_name PlatformChunk

@export var chunk_width: float = 1056.0

func _physics_process(delta: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if gm and gm.running:
		# Uniform world movement vectors processed directly via physics server step
		position.x -= gm.current_speed * delta
