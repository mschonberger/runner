extends Node2D
class_name LevelSpawner

@export var normal_platform_scenes: Array[PackedScene] = []
@export var special_platform_scenes: Array[Dictionary] = []

@export var spawn_buffer_x: float = 800.0
@export var destroy_buffer_x: float = -600.0

@export var max_step_offset: float = 24.0
@export var max_total_offset: float = 72.0

var active_chunks: Array[PlatformChunk] = []
var next_spawn_x: float = 0.0
var last_height_offset: float = 0.0
var track_base_y: float = 328.0
var last_spawned_was_special: bool = false

func _ready() -> void:
	reset_spawner()

func _physics_process(delta: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if not gm or not gm.running:
		return

	next_spawn_x -= gm.current_speed * delta

	if next_spawn_x < spawn_buffer_x:
		spawn_next_chunk(gm)

	_cleanup_old_chunks()

func spawn_next_chunk(gm: GameManager) -> void:
	if normal_platform_scenes.is_empty():
		return

	var picked_scene: PackedScene
	var current_score := gm.current_score
	var chosen_as_special := false

	var special_chance := 0.0
	if current_score > 100.0:
		special_chance = clampf(remap(current_score, 100.0, 1000.0, 0.0, 0.45), 0.0, 0.45)

	if not special_platform_scenes.is_empty() and not last_spawned_was_special and randf() < special_chance:
		picked_scene = _pick_weighted_special_scene(current_score)
		chosen_as_special = true
	else:
		picked_scene = normal_platform_scenes.pick_random()
		chosen_as_special = false

	last_spawned_was_special = chosen_as_special

	var chunk := picked_scene.instantiate() as PlatformChunk
	if not chunk:
		return

	if chunk.has_method("randomize_chunk_width"):
		chunk.call("randomize_chunk_width")

	var next_offset := clampf(
		last_height_offset + randf_range(-max_step_offset, max_step_offset),
		-max_total_offset,
		max_total_offset
	)

	var gap := randf_range(320.0, 480.0)
	var spawn_pos_x := next_spawn_x + gap + (chunk.chunk_width / 2.0)
	var spawn_pos_y := track_base_y + next_offset

	chunk.position = Vector2(spawn_pos_x, spawn_pos_y)
	add_child(chunk)

	if chunk.has_method("init_obstacle_chunk"):
		chunk.call("init_obstacle_chunk")
	elif chunk.has_method("init_chunk"):
		chunk.call("init_chunk")

	active_chunks.append(chunk)

	next_spawn_x = chunk.position.x + (chunk.chunk_width / 2.0)
	last_height_offset = next_offset

func reset_spawner() -> void:
	for chunk in active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	active_chunks.clear()

	last_height_offset = 0.0
	next_spawn_x = 0.0
	last_spawned_was_special = false

	if not normal_platform_scenes.is_empty():
		var first_scene := normal_platform_scenes[0]
		var chunk := first_scene.instantiate() as PlatformChunk

		if chunk.has_method("randomize_chunk_width"):
			chunk.call("randomize_chunk_width")

		var spawn_pos_x := chunk.chunk_width / 2.0
		chunk.position = Vector2(spawn_pos_x, track_base_y)
		add_child(chunk)

		active_chunks.append(chunk)
		next_spawn_x = chunk.position.x + (chunk.chunk_width / 2.0)

func _cleanup_old_chunks() -> void:
	var dead_chunks: Array[PlatformChunk] = []
	for chunk in active_chunks:
		if chunk.position.x + (chunk.chunk_width / 2.0) < destroy_buffer_x:
			dead_chunks.append(chunk)
			chunk.queue_free()

	for chunk in dead_chunks:
		active_chunks.erase(chunk)

func _pick_weighted_special_scene(current_score: float) -> PackedScene:
	if special_platform_scenes.is_empty():
		return null

	var valid_elements: Array[Dictionary] = []
	var total_weight: int = 0

	for element in special_platform_scenes:
		if element.has("scene") and element.has("weight"):
			var min_score: float = 0.0
			if element.has("min_score"):
				min_score = float(element["min_score"])

			if current_score >= min_score:
				valid_elements.append(element)
				total_weight += int(element["weight"])

	if valid_elements.is_empty():
		return normal_platform_scenes.pick_random()

	if total_weight <= 0:
		var fallback = valid_elements.pick_random()
		return fallback.get("scene", null)

	var roll := randi_range(1, total_weight)
	var current_sum: int = 0

	for element in valid_elements:
		current_sum += int(element["weight"])
		if roll <= current_sum:
			return element["scene"] as PackedScene

	return null
