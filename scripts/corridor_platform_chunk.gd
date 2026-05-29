extends PlatformChunk

@export var normal_obstacle_scene: PackedScene

@export var floor_height: float = 600.0
@export var ceiling_height: float = 256.0
@export var corridor_clearance_px: float = 130.0

@export var min_obstacles: int = 3
@export var max_obstacles: int = 4
@export var min_space_between_hazards: float = 380.0

@onready var col_floor: CollisionShape2D = $SolidFloor
@onready var col_ceiling: CollisionShape2D = $SolidCeiling
@onready var floor_sprite: Sprite2D = $FloorSprite
@onready var ceiling_sprite: Sprite2D = $CeilingSprite

func _ready() -> void:
	chunk_width = 1584.0
	
	var generic_sprite = get_node_or_null("Sprite2D")
	if generic_sprite:
		generic_sprite.queue_free()

	if normal_obstacle_scene == null:
		normal_obstacle_scene = load("res://scenes/obstacle.tscn")

	var variant := randi_range(1, 6)
	var path := "res://art/houses/1584 House %d.png" % variant

	if ResourceLoader.exists(path):
		var skyscraper_texture = load(path)
		if floor_sprite:
			floor_sprite.texture = skyscraper_texture
		if ceiling_sprite:
			ceiling_sprite.texture = skyscraper_texture
	else:
		push_error("Corridor Platform: Cannot find asset at " + path)

	_apply_corridor_layout()

func init_chunk() -> void:
	_generate_corridor_hazards()

func _apply_corridor_layout() -> void:
	var floor_y := floor_height / 2.0
	var ceiling_y := -(ceiling_height / 2.0 + corridor_clearance_px)

	col_floor.position = Vector2(0, floor_y)
	var r_floor := RectangleShape2D.new()
	r_floor.size = Vector2(chunk_width, floor_height)
	col_floor.shape = r_floor
		
	col_ceiling.position = Vector2(0, ceiling_y)
	var r_ceil := RectangleShape2D.new()
	r_ceil.size = Vector2(chunk_width, ceiling_height)
	col_ceiling.shape = r_ceil

	if floor_sprite and ceiling_sprite:
		floor_sprite.position = Vector2(0.0, 475.0)
		floor_sprite.scale = Vector2.ONE
		floor_sprite.flip_v = false

		var ceiling_surface_y := -corridor_clearance_px
		ceiling_sprite.position = Vector2(0.0, ceiling_surface_y - 475.0)
		ceiling_sprite.scale = Vector2.ONE
		ceiling_sprite.flip_v = true 

		var shader_res = load("res://shader/color_replace.gdshader") as Shader
		if shader_res:
			var floor_mat := ShaderMaterial.new()
			floor_mat.shader = shader_res
			floor_mat.set_shader_parameter("replace_color", main_color)
			floor_sprite.material = floor_mat

			var ceiling_mat := ShaderMaterial.new()
			ceiling_mat.shader = shader_res
			ceiling_mat.set_shader_parameter("replace_color", main_color)
			ceiling_sprite.material = ceiling_mat

func _generate_corridor_hazards() -> void:
	var obstacle_count := randi_range(min_obstacles, max_obstacles)
	var occupied_x_positions: Array[float] = []
	
	var min_bound := -650.0
	var max_bound := 650.0
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
		
func randomize_chunk_width() -> void:
	chunk_width = 1584
