extends PlatformChunk

var sprite: Sprite2D = null

@export var start_fade_distance_px: float = 100.0
@export var full_fade_distance_px: float = -280.0

var _is_hidden: bool = false

func _ready() -> void:
	super._ready()
	chunk_width = 528.0

	sprite = get_node_or_null("Sprite2D") as Sprite2D

	if sprite == null:
		push_error("InvisiblePlatformChunk: Missing Sprite2D child node!")
	else:
		sprite.modulate.a = 1.0
		sprite.visible = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if sprite == null or _is_hidden:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var platform_left_edge: float = global_position.x - (chunk_width / 2.0)
		var distance_to_player: float = platform_left_edge - player.global_position.x

		if distance_to_player > start_fade_distance_px:
			sprite.modulate.a = 1.0
		elif distance_to_player < full_fade_distance_px:
			sprite.modulate.a = 0.0
			_is_hidden = true

			var col_node = get_node_or_null("CollisionShape2D")
			if col_node:
				col_node.set_deferred("disabled", true)
		else:
			var alpha := remap(distance_to_player, full_fade_distance_px, start_fade_distance_px, 0.0, 1.0)
			sprite.modulate.a = clampf(alpha, 0.0, 1.0)
