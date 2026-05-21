extends Node2D
class_name WorldRunner

@export var segment_width: float = 1056.0
@export var wrap_buffer: float = 400.0

var gm: GameManager
var player: Node2D
var segments: Array[Node2D] = []

func _ready() -> void:
	randomize()

	gm = get_parent().get_node("GameManager") as GameManager
	player = get_parent().get_node("Player") as Node2D

	segments.clear()
	for child in get_children():
		if child is Node2D:
			segments.append(child)

func _physics_process(delta: float) -> void:
	if gm == null or player == null:
		return
	if gm.current_speed <= 0.0:
		return

	for s in segments:
		s.position.x -= gm.current_speed * delta

	_wrap_segments()

func _wrap_segments() -> void:
	if segments.size() < 2:
		return

	var half_w: float = segment_width / 2.0
	var left_limit: float = player.global_position.x - wrap_buffer

	var rightmost: Node2D = segments[0]
	for s in segments:
		if s.position.x > rightmost.position.x:
			rightmost = s

	for s in segments:
		var right_edge: float = s.position.x + half_w

		if right_edge < left_limit:
			var new_x: float = rightmost.position.x + segment_width

			# Snap to center-offset grid (no seams)
			new_x = round((new_x - half_w) / segment_width) * segment_width + half_w

			s.position.x = new_x
			rightmost = s

			if s is GroundSegment:
				(s as GroundSegment).configure_with_difficulty(gm.current_speed, gm.max_speed)

func reset_world() -> void:
	# Reposition segments to a clean start line
	var half_w: float = segment_width / 2.0

	# Sort by current x so reset is stable
	segments.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.position.x < b.position.x
	)

	for i in range(segments.size()):
		var s := segments[i]
		s.position.x = half_w + float(i) * segment_width

		if s is GroundSegment:
			var gs := s as GroundSegment
			gs.clear_obstacles()
			gs.configure_no_gap()
