# res://scripts/ground_segment.gd
extends PlatformChunk
class_name GroundSegment

@export var segment_height: float = 64.0

@onready var col_left: CollisionShape2D = $SolidLeft
@onready var col_right: CollisionShape2D = $SolidRight
@onready var left_sprite: Sprite2D = $Sprite2D

var _tex_size: Vector2 = Vector2.ONE
var _left_shape: RectangleShape2D

func _ready() -> void:
	# Keep clean rectangle shape setup
	_left_shape = RectangleShape2D.new()
	col_left.shape = _left_shape
	
	# Permanently turn off the old Right collision shape—it is no longer used!
	col_right.disabled = true
	var right_node = get_node_or_null("RightSprite")
	if right_node:
		right_node.queue_free()

	# Cache texture sizes for clean visual stretching
	if left_sprite and left_sprite.texture:
		_tex_size = left_sprite.texture.get_size()
		if _tex_size.y > 0.0:
			left_sprite.scale.y = segment_height / _tex_size.y

	_apply_solid_layout()

# --- Public Entry Points Called By Spawner ---

func randomize_chunk_width() -> void:
	# 🎯 Strictly limits the random size between 528px and 1056px
	chunk_width = randf_range(264.0, 792.0)

func configure_with_difficulty(_speed: float, _max_speed: float) -> void:
	# Difficulty-scaled slicing is gone! 
	# We just ensure the solid layout mirrors our newly chosen width.
	_apply_solid_layout()

# --- Internal Layout Engine ---

func _apply_solid_layout() -> void:
	if _left_shape == null: 
		return
		
	# Match the collision box exactly to the overall platform size
	col_left.disabled = false
	_left_shape.size = Vector2(chunk_width, segment_height)
	col_left.position = Vector2.ZERO

	# Stretch the sprite across the entire width perfectly centered
	if left_sprite and _tex_size.x > 0.0:
		left_sprite.visible = true
		left_sprite.position = Vector2.ZERO
		left_sprite.scale.x = chunk_width / _tex_size.x

# --- Purged Legacy Fallbacks ---
func configure_no_gap() -> void: _apply_solid_layout()
