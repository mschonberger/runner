extends PlatformChunk
class_name GroundSegment

@export var segment_height: float = 64.0

@onready var col_left: CollisionShape2D = $SolidLeft
@onready var left_sprite: Sprite2D = $Sprite2D

var _tex_size: Vector2 = Vector2.ONE
var _left_shape: RectangleShape2D

func _ready() -> void:
	_left_shape = RectangleShape2D.new()
	col_left.shape = _left_shape
	
	if left_sprite and left_sprite.texture:
		_tex_size = left_sprite.texture.get_size()
		if _tex_size.y > 0.0:
			left_sprite.scale.y = segment_height / _tex_size.y

	_apply_solid_layout()

func randomize_chunk_width() -> void:
	chunk_width = randf_range(264.0, 792.0)

func configure_with_difficulty(_speed: float, _max_speed: float) -> void:
	_apply_solid_layout()

func _apply_solid_layout() -> void:
	if _left_shape == null: 
		return
		
	col_left.disabled = false
	_left_shape.size = Vector2(chunk_width, segment_height)
	col_left.position = Vector2.ZERO

	if left_sprite and _tex_size.x > 0.0:
		left_sprite.visible = true
		left_sprite.position = Vector2.ZERO
		left_sprite.scale.x = chunk_width / _tex_size.x

func configure_no_gap() -> void: 
	_apply_solid_layout()
