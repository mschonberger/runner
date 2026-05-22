extends PlatformChunk

@export var moving_deadly_obstacle_scene: PackedScene
@export var obstacle_count: int = 4

func _ready() -> void:
	chunk_width = 2112.0
	
	if moving_deadly_obstacle_scene == null:
		moving_deadly_obstacle_scene = load("res://scenes/moving_deadly_obstacle.tscn")

func randomize_chunk_width() -> void:
	chunk_width = 2112.0

func init_chunk() -> void:
	_generate_moving_parkour()

func _generate_moving_parkour() -> void:
	var min_bound := -850.0
	var max_bound := 850.0
	var segment_length := (max_bound - min_bound) / float(obstacle_count)

	var ground_surface_y := -32.0 

	for i in range(obstacle_count):
		var zone_start := min_bound + (i * segment_length)
		var zone_end := zone_start + segment_length
		
		var spawn_x := randf_range(zone_start + 40.0, zone_end - 40.0)
		
		var obstacle = moving_deadly_obstacle_scene.instantiate()
		if obstacle == null:
			continue

		obstacle.position = Vector2(spawn_x, ground_surface_y - 50.0)
		
		obstacle.move_speed = randf_range(130.0, 190.0)
		obstacle.move_range = randf_range(70.0, 120.0)
			
		obstacle.scale = Vector2(0.6, 0.6)
		obstacle.z_index = 10
		add_child(obstacle)
