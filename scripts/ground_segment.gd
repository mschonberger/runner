extends PlatformChunk
class_name GroundSegment

@export var segment_height: float = 64.0
@export var house_textures: Array[Texture2D] = []

@onready var col_left: CollisionShape2D = $SolidLeft
@onready var left_sprite: Sprite2D = $Sprite2D

var right_sprite: Sprite2D

var _tex_size: Vector2 = Vector2.ONE
var _left_shape: RectangleShape2D

func _ready() -> void:
	_left_shape = RectangleShape2D.new()
	col_left.shape = _left_shape

	if not house_textures.is_empty():
		left_sprite.texture = house_textures.pick_random()

	if left_sprite:
		left_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		left_sprite.region_enabled = true


		right_sprite = Sprite2D.new()
		right_sprite.texture = left_sprite.texture
		right_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		right_sprite.region_enabled = true
		right_sprite.flip_h = true
		add_child(right_sprite)

	if left_sprite and left_sprite.texture:
		_tex_size = left_sprite.texture.get_size()

	_apply_solid_layout()

func randomize_chunk_width() -> void:

	chunk_width = snappedf(randf_range(264.0, 792.0), 2.0)

	if not house_textures.is_empty() and left_sprite:
		var chosen_tex = house_textures.pick_random()
		left_sprite.texture = chosen_tex
		if right_sprite:
			right_sprite.texture = chosen_tex
		_tex_size = chosen_tex.get_size()

func configure_with_difficulty(_speed: float, _max_speed: float) -> void:
	_apply_solid_layout()

func _apply_solid_layout() -> void:
	if _left_shape == null:
		return

	var actual_height := segment_height
	if _tex_size.y > 0.0:
		actual_height = _tex_size.y

	var center_y := -32.0 + (actual_height / 2.0)

	col_left.disabled = false
	_left_shape.size = Vector2(chunk_width, actual_height)
	col_left.position = Vector2(0, center_y)

	if left_sprite and right_sprite and _tex_size.x > 0.0:

		var half_width = chunk_width / 2.0

		left_sprite.visible = true
		right_sprite.visible = true

		left_sprite.scale = Vector2(1.0, 1.0)
		right_sprite.scale = Vector2(1.0, 1.0)

		var region = Rect2(0, 0, half_width, actual_height)
		left_sprite.region_rect = region
		right_sprite.region_rect = region

		left_sprite.position = Vector2(-half_width / 2.0, center_y)
		right_sprite.position = Vector2(half_width / 2.0, center_y)

func configure_no_gap() -> void:
	_apply_solid_layout()
