extends PlatformChunk

@onready var sprite: Sprite2D = $Sprite2D

@export var start_fade_distance_px: float = 0.0  # Fade starts here
@export var full_fade_distance_px: float = -240.0    # Fully invisible here

func _ready() -> void:
	
	# Safety check: Ensure the sprite exists and reset its visibility
	if sprite == null:
		push_error("InvisiblePlatformChunk: Missing Sprite2D child node!")
	else:
		sprite.modulate.a = 1.0
		sprite.visible = true

func _physics_process(delta: float) -> void:
	# Keep the base movement processing active so it scrolls left
	super._physics_process(delta)
	
	if sprite == null:
		return
		
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		# Use global_position to ensure camera zoom/offsets don't distort world coordinates
		var platform_left_edge: float = global_position.x - (chunk_width / 2.0)
		var distance_to_player: float = platform_left_edge - player.global_position.x
		
		if distance_to_player > start_fade_distance_px:
			# Player is far away -> SHOULD BE FULLY VISIBLE
			sprite.modulate.a = 1.0
		elif distance_to_player < full_fade_distance_px:
			# Player reached the edge -> COMPLETELY INVISIBLE
			sprite.modulate.a = 0.0
		else:
			# Smoothly transition alpha between the two points
			var alpha := remap(distance_to_player, full_fade_distance_px, start_fade_distance_px, 0.0, 1.0)
			sprite.modulate.a = clampf(alpha, 0.0, 1.0)
