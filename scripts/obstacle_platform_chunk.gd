# res://scripts/obstacle_platform_chunk.gd
extends PlatformChunk

@export var normal_obstacle_scene: PackedScene
@export var deadly_obstacle_scene: PackedScene

@export var deadly_chance: float = 0.28         
@export var min_obstacles_per_chunk: int = 4   
@export var max_obstacles_per_chunk: int = 7   
@export var min_space_between_hazards: float = 180.0

func _ready() -> void:
	# Force our updated strict size constraints globally
	chunk_width = 2112.0
	
	if normal_obstacle_scene == null:
		normal_obstacle_scene = load("res://scenes/obstacle.tscn")
	if deadly_obstacle_scene == null:
		deadly_obstacle_scene = load("res://scenes/deadly_obstacle.tscn")

func init_obstacle_chunk() -> void:
	_generate_massive_gauntlet()

func _generate_massive_gauntlet() -> void:
	# 1. Choose a high density count between our strict 4 and 7 range
	var obstacle_count := randi_range(min_obstacles_per_chunk, max_obstacles_per_chunk)
	var occupied_x_positions: Array[float] = []
	
	# Keep hazards safely away from the absolute edges of our 2112px layout
	var min_bound := -950.0
	var max_bound := 950.0
	
	for i in range(obstacle_count):
		var spawn_x := 0.0
		var valid_spot := false
		var attempts := 0
		
		# 2. Position Lottery Loop
		while not valid_spot and attempts < 30:
			attempts += 1
			spawn_x = randf_range(min_bound, max_bound)
			
			var too_close := false
			for pos in occupied_x_positions:
				if absf(spawn_x - pos) < min_space_between_hazards:
					too_close = true
					break
			
			if not too_close:
				valid_spot = true
		
		if not valid_spot:
			continue
			
		occupied_x_positions.append(spawn_x)
		
		# 3. Determine Object Type
		var obstacle_scene := normal_obstacle_scene
		if randf() < deadly_chance:
			obstacle_scene = deadly_obstacle_scene
			
		var obstacle := obstacle_scene.instantiate() as Node2D
		if obstacle == null: 
			continue
			
		# 4. Vertical Layer Selection (Ground, Low Float, High Float)
		var ground_y := -32.0 
		var spawn_y := ground_y
		
		var height_roll := randf()
		if height_roll < 0.25:
			spawn_y = ground_y - 52.0
		elif height_roll < 0.45:
			spawn_y = ground_y - 24.0
		
		obstacle.position = Vector2(spawn_x, spawn_y)
		obstacle.scale = Vector2(0.6, 0.6)
		obstacle.z_index = 10
		add_child(obstacle)
