# res://scripts/level_spawner.gd
extends Node2D
class_name LevelSpawner

@export var platform_scenes: Array[PackedScene] = []
@export var spawn_buffer_x: float = 800.0   # Generates out to the right boundary
@export var destroy_buffer_x: float = -600.0 # Clears things past the left edge

@export var max_step_offset: float = 24.0
@export var max_total_offset: float = 72.0

var active_chunks: Array[PlatformChunk] = []
var next_spawn_x: float = 0.0
var last_height_offset: float = 0.0
var track_base_y: float = 328.0 # Found baseline in your scene configurations

func _ready() -> void:
	reset_spawner()

func _physics_process(delta: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if not gm or not gm.running:
		return

	# Bring tracking markers backward with current speed vector shift
	next_spawn_x -= gm.current_speed * delta

	# Check visual workspace limits and allocate runtime allocations
	var current_rightmost_visible := next_spawn_x
	if current_rightmost_visible < spawn_buffer_x:
		spawn_next_chunk(gm)

	_cleanup_old_chunks()

func spawn_next_chunk(gm: GameManager) -> void:
	if platform_scenes.is_empty():
		return

	var picked_scene := platform_scenes.pick_random() as PackedScene
	var chunk := picked_scene.instantiate() as PlatformChunk
	if not chunk:
		return

	# Calculate clean jump adjustments
	var next_offset := clampf(
		last_height_offset + randf_range(-max_step_offset, max_step_offset),
		-max_total_offset,
		max_total_offset
	)
	
	# Determine procedural empty air gaps between platforms
	var gap := randf_range(48.0, 160.0)
	
	# Compute spatial position (Pivot centered placement setup offset compensation)
	var spawn_pos_x := next_spawn_x + gap + (chunk.chunk_width / 2.0)
	var spawn_pos_y := track_base_y + next_offset

	chunk.position = Vector2(spawn_pos_x, spawn_pos_y)
	add_child(chunk)

	if chunk is GroundSegment:
		chunk.configure_with_difficulty(gm.current_speed, gm.max_speed)

	active_chunks.append(chunk)
	
	# Set next anchor directly past this chunk's right edge
	next_spawn_x = chunk.position.x + (chunk.chunk_width / 2.0)
	last_height_offset = next_offset

func reset_spawner() -> void:
	# Purge all existing blocks
	for chunk in active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	active_chunks.clear()

	last_height_offset = 0.0
	next_spawn_x = 0.0

	# Spawn an initial safety floor for the player to land on when starting
	if not platform_scenes.is_empty():
		var first_scene := platform_scenes[0]
		var chunk := first_scene.instantiate() as PlatformChunk
		
		# Center first platform directly underneath the starting character position
		var spawn_pos_x := chunk.chunk_width / 2.0
		chunk.position = Vector2(spawn_pos_x, track_base_y)
		add_child(chunk)
		
		if chunk is GroundSegment:
			chunk.configure_no_gap()
			
		active_chunks.append(chunk)
		next_spawn_x = chunk.position.x + (chunk.chunk_width / 2.0)

func _cleanup_old_chunks() -> void:
	var dead_chunks: Array[PlatformChunk] = []
	for chunk in active_chunks:
		# Check if the right boundary edge of the platform is off-screen left
		if chunk.position.x + (chunk.chunk_width / 2.0) < destroy_buffer_x:
			dead_chunks.append(chunk)
			chunk.queue_free()

	for chunk in dead_chunks:
		active_chunks.erase(chunk)
