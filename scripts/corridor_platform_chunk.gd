# res://scripts/corridor_platform_chunk.gd
extends PlatformChunk

@export var normal_obstacle_scene: PackedScene

# --- Skyscraper Layout Constraints ---
@export var floor_height: float = 600.0
@export var ceiling_height: float = 256.0        # 🚨 Massive block thickness to simulate a skyscraper base
@export var corridor_clearance_px: float = 130.0 # 📐 Widened from 84 to 130 so obstacles are actually dodgeable!

# --- Precision Obstacle Density Control ---
@export var min_obstacles: int = 3
@export var max_obstacles: int = 4
@export var min_space_between_hazards: float = 380.0 # 🚨 Drastically widened spacing so player can land and slide!

@onready var col_floor: CollisionShape2D = $SolidFloor
@onready var col_ceiling: CollisionShape2D = $SolidCeiling
@onready var floor_sprite: Sprite2D = $FloorSprite
@onready var ceiling_sprite: Sprite2D = $CeilingSprite

var _tex_size: Vector2 = Vector2.ONE

func _ready() -> void:
	chunk_width = 1584.0
	
	if normal_obstacle_scene == null:
		normal_obstacle_scene = load("res://scenes/obstacle.tscn")

	if floor_sprite and floor_sprite.texture:
		_tex_size = floor_sprite.texture.get_size()

	_apply_corridor_layout()

func init_chunk() -> void:
	_generate_corridor_hazards()

func _apply_corridor_layout() -> void:
	# Position the center of the floor block downward so its top surface stays at Y = 0
	var floor_y := floor_height / 2.0
	var ceiling_y := -(ceiling_height / 2.0 + corridor_clearance_px)

	# 1. Configure Floor Physical Block
	col_floor.position = Vector2(0, floor_y)
	var r_floor := RectangleShape2D.new()
	r_floor.size = Vector2(chunk_width, floor_height)
	col_floor.shape = r_floor
		
	# 2. Configure Massive Ceiling Block
	col_ceiling.position = Vector2(0, ceiling_y)
	var r_ceil := RectangleShape2D.new()
	r_ceil.size = Vector2(chunk_width, ceiling_height)
	col_ceiling.shape = r_ceil

	# 3. Scale and Stretch Visual Sprites
	if floor_sprite and floor_sprite.texture and ceiling_sprite and ceiling_sprite.texture:
		if _tex_size.x > 0.0 and _tex_size.y > 0.0:
			floor_sprite.position = col_floor.position
			floor_sprite.scale = Vector2(chunk_width / _tex_size.x, floor_height / _tex_size.y)
			
			ceiling_sprite.position = col_ceiling.position
			ceiling_sprite.scale = Vector2(chunk_width / _tex_size.x, ceiling_height / _tex_size.y)

func _generate_corridor_hazards() -> void:
	var obstacle_count := randi_range(min_obstacles, max_obstacles)
	var occupied_x_positions: Array[float] = []
	
	var min_bound := -650.0
	var max_bound := 650.0
	
	# 🚨 FIX: The top surface of our running track floor is at Y = 0.0!
	var ground_surface_y := 0.0
	
	for i in range(obstacle_count):
		var spawn_x := 0.0
		var valid_spot := false
		var attempts := 0
		
		while not valid_spot and attempts < 40:
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
		
		var obstacle := normal_obstacle_scene.instantiate() as Node2D
		if obstacle == null: 
			continue

		obstacle.position = Vector2(spawn_x, ground_surface_y)
		obstacle.scale = Vector2(0.6, 0.6)
		
		obstacle.z_index = 10
		add_child(obstacle)
