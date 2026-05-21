# res://scripts/level_spawner.gd
extends Node2D
class_name LevelSpawner

@export var normal_platform_scenes: Array[PackedScene] = []
@export var special_platform_scenes: Array[PackedScene] = []

@export var spawn_buffer_x: float = 800.0   
@export var destroy_buffer_x: float = -600.0 

@export var max_step_offset: float = 24.0
@export var max_total_offset: float = 72.0

var active_chunks: Array[PlatformChunk] = []
var next_spawn_x: float = 0.0
var last_height_offset: float = 0.0
var track_base_y: float = 328.0 

func _ready() -> void:
	reset_spawner()

func _physics_process(delta: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if not gm or not gm.running:
		return

	# Shift our trailing coordinate tracking point backwards with world speed
	next_spawn_x -= gm.current_speed * delta

	if next_spawn_x < spawn_buffer_x:
		spawn_next_chunk(gm)

	_cleanup_old_chunks()

func spawn_next_chunk(gm: GameManager) -> void:
	if normal_platform_scenes.is_empty():
		return

# 1. Determine which array pool to pull from based on current score (distance proxy)
	var picked_scene: PackedScene
	var current_score := gm.current_score
	
	var special_chance := 0.0
	if current_score > 100.0:
		special_chance = clampf(remap(current_score, 100.0, 1000.0, 0.0, 0.45), 0.0, 0.45)

	if not special_platform_scenes.is_empty() and randf() < special_chance:
		picked_scene = _pick_weighted_special_scene()
	else:
		picked_scene = normal_platform_scenes.pick_random()

	var chunk := picked_scene.instantiate() as PlatformChunk
	if not chunk:
		return

	# 2. Establish chunk dimensions before calculating spatial position placement
	if chunk.has_method("randomize_chunk_width"):
		chunk.call("randomize_chunk_width")

	# Calculate vertical offsets
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

	# 3. Fire initialization routines if present (Obstacles, custom setups, etc.)
	if chunk.has_method("init_obstacle_chunk"):
		chunk.call("init_obstacle_chunk")
	elif chunk.has_method("init_chunk"):
		chunk.call("init_chunk")

	active_chunks.append(chunk)
	
	# Close the frame by moving our trailing tracking marker to the right edge of this new chunk
	next_spawn_x = chunk.position.x + (chunk.chunk_width / 2.0)
	last_height_offset = next_offset

func reset_spawner() -> void:
	# Clean slate removal
	for chunk in active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	active_chunks.clear()

	last_height_offset = 0.0
	next_spawn_x = 0.0

	# Spawn the guaranteed initial runway under the player's feet
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
		# If the rightmost edge of a chunk drops past our boundary limit, remove it
		if chunk.position.x + (chunk.chunk_width / 2.0) < destroy_buffer_x:
			dead_chunks.append(chunk)
			chunk.queue_free()

	for chunk in dead_chunks:
		active_chunks.erase(chunk)

func _pick_weighted_special_scene() -> PackedScene:
	if special_platform_scenes.is_empty():
		return null
		
	# Create a temporary array to build our probability weight map
	var weighted_pool: Array[PackedScene] = []
	
	for scene in special_platform_scenes:
		var chunk_instance = scene.instantiate()
		
		# Check the actual script class type attached to the packed scene
		if chunk_instance.has_method("init_obstacle_chunk"):
			# 🎯 OBSTACLE CHUNKS: Add them 4 times to the lottery pool
			for w in range(4):
				weighted_pool.append(scene)
		else:
			# 🎯 INVISIBLE / SINKING / OTHER CHUNKS: Add them only 2 times
			for w in range(2):
				weighted_pool.append(scene)
				
		chunk_instance.queue_free() # Clean up the memory instantly
		
	if weighted_pool.is_empty():
		return special_platform_scenes.pick_random()
		
	return weighted_pool.pick_random()
