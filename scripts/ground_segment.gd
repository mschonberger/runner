extends AnimatableBody2D
class_name GroundSegment

@export var segment_width: float = 1056.0
@export var segment_height: float = 64.0
@export var tile_size: int = 48

@export var side_margin_tiles: int = 2
@export var max_jumpable_tiles: int = 8
@export var max_flat_segments: int = 3

# Obstacles
@export var obstacle_scene: PackedScene
@export var obstacle_chance_min: float = 0.25
@export var obstacle_chance_max: float = 0.55

# Fairness constraints
@export var min_solid_tiles_for_obstacle: int = 10
@export var gap_guard_tiles: int = 4
@export var obstacle_half_width_px: float = 24.0
@export var segment_edge_margin_px: float = 48.0

@onready var col_left: CollisionShape2D = $SolidLeft
@onready var col_right: CollisionShape2D = $SolidRight

# Visuals:
# We reuse $Sprite2D as the LEFT visual and create/find a RightSprite for the right visual.
@onready var left_sprite: Sprite2D = $Sprite2D
var right_sprite: Sprite2D = null
var _tex_size: Vector2 = Vector2.ONE

var _left_shape: RectangleShape2D
var _right_shape: RectangleShape2D

var flat_counter: int = 0

# Solid ranges (local X)
var _has_left: bool = true
var _has_right: bool = false
var _left_start_x: float = 0.0
var _left_end_x: float = 0.0
var _right_start_x: float = 0.0
var _right_end_x: float = 0.0

const OBSTACLE_FALLBACK_PATH: String = "res://scenes/obstacle.tscn"

func _ready() -> void:
	_left_shape = RectangleShape2D.new()
	_right_shape = RectangleShape2D.new()
	col_left.shape = _left_shape
	col_right.shape = _right_shape

	if obstacle_scene == null:
		obstacle_scene = load(OBSTACLE_FALLBACK_PATH) as PackedScene

	# --- Visual setup ---
	if left_sprite == null or left_sprite.texture == null:
		push_warning("GroundSegment: Sprite2D or texture missing. Visual ground won't match collisions.")
		_tex_size = Vector2.ONE
	else:
		_tex_size = left_sprite.texture.get_size()

	# Create/find right sprite
	right_sprite = get_node_or_null("RightSprite") as Sprite2D
	if right_sprite == null:
		right_sprite = Sprite2D.new()
		right_sprite.name = "RightSprite"
		right_sprite.centered = true
		right_sprite.z_index = left_sprite.z_index
		add_child(right_sprite)

		# Copy texture from left sprite
		right_sprite.texture = left_sprite.texture

	# Keep Y scale consistent across both sprites (optional; comment out if you don't want vertical scaling)
	if _tex_size.y > 0.0:
		var sy := segment_height / _tex_size.y
		left_sprite.scale.y = sy
		right_sprite.scale.y = sy

	configure_no_gap()

func configure_with_difficulty(speed: float, max_speed: float) -> void:
	clear_obstacles()

	var t: float = clamp(speed / max_speed, 0.0, 1.0)

	var gap_chance: float = lerp(0.25, 0.65, t)
	var min_gap: int = int(lerp(3.0, 5.0, t))
	var max_gap: int = int(lerp(6.0, float(max_jumpable_tiles), t))

	configure_random_cutout(gap_chance, min_gap, max_gap)

	var obs_chance: float = lerp(obstacle_chance_min, obstacle_chance_max, t)
	spawn_obstacle(obs_chance)

func configure_random_cutout(chance: float, min_gap: int, max_gap: int) -> void:
	if randf() > chance and flat_counter < max_flat_segments:
		flat_counter += 1
		configure_no_gap()
		return

	flat_counter = 0

	var tiles_total: int = int(segment_width / float(tile_size))

	min_gap = clamp(min_gap, 1, tiles_total - 2)
	max_gap = clamp(max_gap, min_gap, tiles_total - 2)

	var gap_tiles: int = int(randi_range(min_gap, max_gap))
	gap_tiles = min(gap_tiles, max_jumpable_tiles)

	var margin_limit: int = int(tiles_total / 2.0)
	var margin: int = min(side_margin_tiles, margin_limit)

	var start_min: int = margin
	var start_max: int = int(tiles_total - margin - gap_tiles)

	if start_max <= start_min:
		configure_no_gap()
		return

	var gap_start_tiles: int = int(randi_range(start_min, start_max))
	configure_gap(gap_start_tiles, gap_tiles)

func configure_no_gap() -> void:
	col_left.disabled = false
	col_right.disabled = true

	_left_shape.size = Vector2(segment_width, segment_height)
	col_left.position = Vector2(0.0, 0.0)

	_has_left = true
	_has_right = false

	var half_w: float = segment_width / 2.0
	_left_start_x = -half_w
	_left_end_x = half_w

	# --- Visuals: left covers full, right hidden ---
	_apply_ground_visuals(segment_width, 0.0)

func configure_gap(gap_start_tiles: int, gap_tiles: int) -> void:
	var gap_start_px: float = float(gap_start_tiles * tile_size)
	var gap_width_px: float = float(gap_tiles * tile_size)

	var half_w: float = segment_width / 2.0

	var left_width: float = gap_start_px
	var right_width: float = segment_width - (gap_start_px + gap_width_px)

	# LEFT solid
	if left_width <= 0.0:
		col_left.disabled = true
		_has_left = false
	else:
		col_left.disabled = false
		_has_left = true
		_left_shape.size = Vector2(left_width, segment_height)
		col_left.position.x = -half_w + left_width / 2.0
		_left_start_x = -half_w
		_left_end_x = -half_w + left_width

	# RIGHT solid
	var gap_end: float = -half_w + left_width + gap_width_px

	if right_width <= 0.0:
		col_right.disabled = true
		_has_right = false
	else:
		col_right.disabled = false
		_has_right = true
		_right_shape.size = Vector2(right_width, segment_height)
		col_right.position.x = gap_end + right_width / 2.0
		_right_start_x = gap_end
		_right_end_x = half_w

	# --- Visuals: match collision widths exactly ---
	_apply_ground_visuals(left_width, right_width)

func _apply_ground_visuals(left_width: float, right_width: float) -> void:
	# If no texture, nothing to do
	if left_sprite == null or left_sprite.texture == null:
		return
	if right_sprite == null:
		return
	if _tex_size.x <= 0.0:
		return

	# Left visual
	if col_left.disabled or left_width <= 0.0:
		left_sprite.visible = false
	else:
		left_sprite.visible = true
		left_sprite.position.x = col_left.position.x
		left_sprite.scale.x = left_width / _tex_size.x

	# Right visual
	if col_right.disabled or right_width <= 0.0:
		right_sprite.visible = false
	else:
		right_sprite.visible = true
		right_sprite.position.x = col_right.position.x
		right_sprite.scale.x = right_width / _tex_size.x

func spawn_obstacle(chance: float) -> void:
	if obstacle_scene == null:
		return
	if randf() > chance:
		return

	var eligible: Array[int] = []
	if _has_left and _solid_width_tiles(_left_start_x, _left_end_x) >= min_solid_tiles_for_obstacle:
		eligible.append(0)
	if _has_right and _solid_width_tiles(_right_start_x, _right_end_x) >= min_solid_tiles_for_obstacle:
		eligible.append(1)

	if eligible.is_empty():
		return

	var pick: int = eligible[randi() % eligible.size()]

	var gap_guard_px: float = float(gap_guard_tiles * tile_size)
	var margin_px: float = max(segment_edge_margin_px, obstacle_half_width_px)

	var x_min: float
	var x_max: float

	if pick == 0:
		x_min = _left_start_x + margin_px
		x_max = _left_end_x - max(margin_px, gap_guard_px)
	else:
		x_min = _right_start_x + max(margin_px, gap_guard_px)
		x_max = _right_end_x - margin_px

	if x_max <= x_min:
		return

	var obstacle := obstacle_scene.instantiate() as Node2D
	var x_pos: float = randf_range(x_min, x_max)

	var ground_y: float = -segment_height / 2.0
	var y_positions: Array[float] = [
		ground_y - 32.0,
		ground_y - 44.0
	]
	var y_pos: float = y_positions[randi() % y_positions.size()]

	obstacle.position = Vector2(x_pos, y_pos)
	obstacle.z_index = 10
	add_child(obstacle)

func _solid_width_tiles(a: float, b: float) -> int:
	var w_px: float = max(0.0, b - a)
	return int(w_px / float(tile_size))

func clear_obstacles() -> void:
	for child in get_children():
		if child is Area2D:
			child.queue_free()
